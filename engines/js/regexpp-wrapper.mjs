/**
 * Simple wrapper that exports parseRegExpLiteral with modifier support.
 */

import { parseRegExpLiteral as originalParse } from "@eslint-community/regexpp";

/**
 * Check if a pattern contains modifier syntax.
 * Uses string operations to avoid regex recursion issues.
 */
function hasModifierSyntax(pattern) {
    // Quick check for (? sequence
    let idx = pattern.indexOf('(?');
    while (idx !== -1) {
        // Check if followed by i, m, or s and then :
        let j = idx + 2;
        // Skip modifier chars
        while (j < pattern.length && /[ims]/.test(pattern[j])) j++;
        // Check for optional removal modifiers
        if (j < pattern.length && pattern[j] === '-') {
            j++;
            while (j < pattern.length && /[ims]/.test(pattern[j])) j++;
        }
        // If we hit :, this is a modifier group
        if (j < pattern.length && pattern[j] === ':') {
            return true;
        }
        // Look for next (? sequence
        idx = pattern.indexOf('(?', idx + 1);
    }
    return false;
}

/**
 * Parse a regex literal.
 * Falls back to custom parsing for patterns with modifiers.
 */
export function parseRegExpLiteral(source) {
    const sourceStr = typeof source === 'string' ? source : String(source);
    
    // Check if source contains modifier syntax
    if (!hasModifierSyntax(sourceStr)) {
        // No modifiers, use regexpp directly
        return originalParse(sourceStr);
    }
    
    // Has modifiers - extract pattern and flags
    const match = sourceStr.match(/^\/(.*)\/([gimsuy]*)$/);
    if (!match) {
        throw new Error('Invalid regex literal: ' + sourceStr);
    }
    
    const pattern = match[1];
    const flags = match[2];
    
    // Parse with custom parser that handles modifiers
    return {
        type: 'RegExpLiteral',
        pattern: parsePatternWithModifiers(pattern),
        flags: flags
    };
}

/**
 * Parse a pattern string with modifier support.
 */
function parsePatternWithModifiers(pattern) {
    return {
        type: 'Pattern',
        alternatives: parseAlternatives(tokenize(pattern))
    };
}

function tokenize(str) {
    const tokens = [];
    let i = 0;
    
    while (i < str.length) {
        const char = str[i];
        
        if (char === '\\') {
            tokens.push({ type: 'ESC', val: str[i + 1] || '' });
            i += 2;
        } else if (char === '[') {
            let j = i + 1, content = '';
            while (j < str.length && str[j] !== ']') {
                if (str[j] === '\\') {
                    content += str.slice(j, j + 2);
                    j += 2;
                } else {
                    content += str[j];
                    j++;
                }
            }
            const neg = content.startsWith('^');
            tokens.push({ type: 'CLASS', neg, content: neg ? content.slice(1) : content });
            i = j + 1;
        } else if (char === '(') {
            if (str[i + 1] === '?') {
                if (str[i + 2] === ':') {
                    tokens.push({ type: 'NONCAP' });
                    i += 3;
                } else if (str[i + 2] === '=') {
                    tokens.push({ type: 'POS_LA' });
                    i += 3;
                } else if (str[i + 2] === '!') {
                    tokens.push({ type: 'NEG_LA' });
                    i += 3;
                } else if (str[i + 2] === '<' && str[i + 3] === '=') {
                    tokens.push({ type: 'POS_LB' });
                    i += 4;
                } else if (str[i + 2] === '<' && str[i + 3] === '!') {
                    tokens.push({ type: 'NEG_LB' });
                    i += 4;
                } else if (str[i + 2] === '<') {
                    let j = i + 3, name = '';
                    while (j < str.length && str[j] !== '>') {
                        name += str[j];
                        j++;
                    }
                    tokens.push({ type: 'NAMED', name });
                    i = j + 1;
                } else if (/[ims]/.test(str[i + 2]) || (str[i + 2] === '-' && /[ims]/.test(str[i + 3]))) {
                    // Modifier group
                    let j = i + 2, add = '', remove = '';
                    while (/[ims]/.test(str[j])) {
                        add += str[j];
                        j++;
                    }
                    if (str[j] === '-') {
                        j++;
                        while (/[ims]/.test(str[j])) {
                            remove += str[j];
                            j++;
                        }
                    }
                    if (str[j] === ':') {
                        tokens.push({ type: 'MOD', add, remove });
                        i = j + 1;
                    } else {
                        tokens.push({ type: 'CHAR', val: char });
                        i++;
                    }
                } else {
                    tokens.push({ type: 'CHAR', val: char });
                    i++;
                }
            } else {
                tokens.push({ type: 'GROUP' });
                i++;
            }
        } else if (char === ')') {
            tokens.push({ type: 'CLOSE' });
            i++;
        } else if (char === '|') {
            tokens.push({ type: 'ALT' });
            i++;
        } else if (char === '^') {
            tokens.push({ type: 'ASSERT', kind: 'start' });
            i++;
        } else if (char === '$') {
            tokens.push({ type: 'ASSERT', kind: 'end' });
            i++;
        } else if (char === '.') {
            tokens.push({ type: 'DOT' });
            i++;
        } else if (/[*+?]/.test(char)) {
            const lazy = str[i + 1] === '?';
            tokens.push({ type: 'QUANT', val: char, lazy });
            i += 1 + (lazy ? 1 : 0);
        } else if (char === '{') {
            let j = i + 1, range = '';
            while (j < str.length && /[0-9,]/.test(str[j])) {
                range += str[j];
                j++;
            }
            if (str[j] === '}') {
                const lazy = str[j + 1] === '?';
                tokens.push({ type: 'QUANT', val: '{' + range + '}', lazy });
                i = j + 1 + (lazy ? 1 : 0);
            } else {
                tokens.push({ type: 'CHAR', val: char });
                i++;
            }
        } else {
            tokens.push({ type: 'CHAR', val: char });
            i++;
        }
    }
    
    return tokens;
}

function parseAlternatives(tokens) {
    const alts = [];
    let pos = 0;
    
    while (pos < tokens.length) {
        const { elements, newPos } = parseSequence(tokens, pos);
        alts.push({ type: 'Alternative', elements });
        pos = newPos;
        
        if (pos < tokens.length && tokens[pos].type === 'ALT') {
            pos++;
        } else {
            break;
        }
    }
    
    return alts;
}

function parseSequence(tokens, pos) {
    const elements = [];
    
    while (pos < tokens.length) {
        const tok = tokens[pos];
        
        if (tok.type === 'ALT' || tok.type === 'CLOSE') {
            break;
        }
        
        let elem;
        
        if (tok.type === 'CHAR') {
            elem = { type: 'Character', value: tok.val.charCodeAt(0) };
            pos++;
        } else if (tok.type === 'ESC') {
            elem = parseEscape(tok.val);
            pos++;
        } else if (tok.type === 'DOT') {
            elem = { type: 'CharacterSet', kind: 'any', negate: false };
            pos++;
        } else if (tok.type === 'ASSERT') {
            if (tok.kind === 'start' || tok.kind === 'end') {
                elem = { type: 'Assertion', kind: tok.kind };
            } else {
                elem = { type: 'Assertion', kind: 'word', negate: tok.kind === 'not-word' };
            }
            pos++;
        } else if (tok.type === 'CLASS') {
            elem = parseCharacterClass(tok);
            pos++;
        } else if (tok.type === 'QUANT') {
            if (elements.length > 0) {
                const prev = elements.pop();
                const q = parseQuantifier(tok);
                elem = {
                    type: 'Quantifier',
                    element: prev,
                    min: q.min,
                    max: q.max,
                    greedy: q.greedy,
                    raw: tok.val + (tok.lazy ? '?' : '')
                };
            }
            pos++;
            elements.push(elem);
            continue;
        } else if (tok.type === 'GROUP') {
            const { elements: innerElems, newPos } = parseSequence(tokens, pos + 1);
            elem = {
                type: 'CapturingGroup',
                name: null,
                alternatives: [{ type: 'Alternative', elements: innerElems }]
            };
            pos = findMatchingClose(tokens, pos + 1) + 1;
        } else if (tok.type === 'NONCAP') {
            const { elements: innerElems, newPos } = parseSequence(tokens, pos + 1);
            elem = {
                type: 'Group',
                alternatives: [{ type: 'Alternative', elements: innerElems }]
            };
            pos = findMatchingClose(tokens, pos + 1) + 1;
        } else if (tok.type === 'NAMED') {
            const { elements: innerElems, newPos } = parseSequence(tokens, pos + 1);
            elem = {
                type: 'CapturingGroup',
                name: tok.name,
                alternatives: [{ type: 'Alternative', elements: innerElems }]
            };
            pos = findMatchingClose(tokens, pos + 1) + 1;
        } else if (tok.type === 'POS_LA') {
            const { elements: innerElems, newPos } = parseSequence(tokens, pos + 1);
            elem = {
                type: 'Assertion',
                kind: 'lookahead',
                negate: false,
                alternatives: [{ type: 'Alternative', elements: innerElems }]
            };
            pos = findMatchingClose(tokens, pos + 1) + 1;
        } else if (tok.type === 'NEG_LA') {
            const { elements: innerElems, newPos } = parseSequence(tokens, pos + 1);
            elem = {
                type: 'Assertion',
                kind: 'lookahead',
                negate: true,
                alternatives: [{ type: 'Alternative', elements: innerElems }]
            };
            pos = findMatchingClose(tokens, pos + 1) + 1;
        } else if (tok.type === 'POS_LB') {
            const { elements: innerElems, newPos } = parseSequence(tokens, pos + 1);
            elem = {
                type: 'Assertion',
                kind: 'lookbehind',
                negate: false,
                alternatives: [{ type: 'Alternative', elements: innerElems }]
            };
            pos = findMatchingClose(tokens, pos + 1) + 1;
        } else if (tok.type === 'NEG_LB') {
            const { elements: innerElems, newPos } = parseSequence(tokens, pos + 1);
            elem = {
                type: 'Assertion',
                kind: 'lookbehind',
                negate: true,
                alternatives: [{ type: 'Alternative', elements: innerElems }]
            };
            pos = findMatchingClose(tokens, pos + 1) + 1;
        } else if (tok.type === 'MOD') {
            const { elements: innerElems, newPos } = parseSequence(tokens, pos + 1);
            elem = {
                type: 'Modifier',
                enable: tok.add,
                disable: tok.remove,
                alternatives: [{ type: 'Alternative', elements: innerElems }]
            };
            pos = findMatchingClose(tokens, pos + 1) + 1;
        } else {
            pos++;
            continue;
        }
        
        elements.push(elem);
    }
    
    return { elements, newPos: pos };
}

function findMatchingClose(tokens, start) {
    let depth = 1;
    for (let i = start; i < tokens.length; i++) {
        const t = tokens[i].type;
        if (t === 'GROUP' || t === 'NONCAP' || t === 'NAMED' || 
            t === 'POS_LA' || t === 'NEG_LA' || t === 'POS_LB' || 
            t === 'NEG_LB' || t === 'MOD') {
            depth++;
        } else if (t === 'CLOSE') {
            depth--;
            if (depth === 0) return i;
        }
    }
    return tokens.length;
}

function parseEscape(char) {
    switch (char) {
        case 'd': return { type: 'CharacterSet', kind: 'digit', negate: false };
        case 'D': return { type: 'CharacterSet', kind: 'digit', negate: true };
        case 'w': return { type: 'CharacterSet', kind: 'word', negate: false };
        case 'W': return { type: 'CharacterSet', kind: 'word', negate: true };
        case 's': return { type: 'CharacterSet', kind: 'space', negate: false };
        case 'S': return { type: 'CharacterSet', kind: 'space', negate: true };
        case 'b': return { type: 'Assertion', kind: 'word', negate: false };
        case 'B': return { type: 'Assertion', kind: 'word', negate: true };
        case 't': return { type: 'Character', value: 9 };
        case 'n': return { type: 'Character', value: 10 };
        case 'r': return { type: 'Character', value: 13 };
        case 'f': return { type: 'Character', value: 12 };
        case 'v': return { type: 'Character', value: 11 };
        case '0': return { type: 'Character', value: 0 };
        default:
            if (/[1-9]/.test(char)) {
                return { type: 'Backreference', ref: parseInt(char, 10) };
            }
            return { type: 'Character', value: char.charCodeAt(0) };
    }
}

function parseCharacterClass(tok) {
    const elements = [];
    const content = tok.content;
    let i = 0;
    
    while (i < content.length) {
        const char = content[i];
        
        if (char === '\\') {
            const esc = content[i + 1];
            if (/[dDwWsS]/.test(esc)) {
                elements.push(parseEscape(esc));
            } else {
                elements.push({ type: 'Character', value: (esc || '').charCodeAt(0) });
            }
            i += 2;
        } else if (i + 2 < content.length && content[i + 1] === '-' && content[i + 2] !== ']' && content[i + 2] !== undefined) {
            elements.push({
                type: 'CharacterClassRange',
                min: { type: 'Character', value: char.charCodeAt(0) },
                max: { type: 'Character', value: content[i + 2].charCodeAt(0) }
            });
            i += 3;
        } else {
            elements.push({ type: 'Character', value: char.charCodeAt(0) });
            i++;
        }
    }
    
    return {
        type: 'CharacterClass',
        negate: tok.neg,
        elements: elements
    };
}

function parseQuantifier(tok) {
    const val = tok.val;
    const greedy = !tok.lazy;
    
    if (val === '*') return { min: 0, max: Infinity, greedy };
    if (val === '+') return { min: 1, max: Infinity, greedy };
    if (val === '?') return { min: 0, max: 1, greedy };
    
    const m = val.match(/\{(\d+)(?:,(\d*))?\}/);
    if (m) {
        const min = parseInt(m[1], 10);
        const max = m[2] === '' ? Infinity : (m[2] ? parseInt(m[2], 10) : min);
        return { min, max, greedy };
    }
    
    return { min: 0, max: 1, greedy: true };
}
