/**
 * Transform a test file to replace regex literals with modifier syntax
 * to RegExp constructor calls.
 */

const fs = require('fs');

const MODIFIER_PATTERN = /\(\?[ims]*(?:-[ims]*)?:/;

function transformFile(inputPath, outputPath) {
    const content = fs.readFileSync(inputPath, 'utf8');
    
    // Check if this file contains modifier syntax
    if (!MODIFIER_PATTERN.test(content)) {
        // No modifiers, just copy
        fs.writeFileSync(outputPath, content);
        return;
    }
    
    console.error(`[Transform] Processing: ${inputPath}`);
    
    // Find and replace regex literals with modifier syntax
    const regexPattern = /\/((?:\\\/|[^\/\n])+?)\/([gimsuy]*)/g;
    let match;
    const replacements = [];
    
    while ((match = regexPattern.exec(content)) !== null) {
        const fullMatch = match[0];
        const pattern = match[1];
        const flags = match[2];
        const start = match.index;
        
        // Check context - skip if in comment or string
        const before = content.slice(Math.max(0, start - 5), start);
        if (before.includes('//') || before.match(/["']$/)) {
            continue;
        }
        
        if (MODIFIER_PATTERN.test(pattern)) {
            // Escape pattern for string
            const escaped = pattern
                .replace(/\\/g, '\\\\')
                .replace(/'/g, "\\'")
                .replace(/\n/g, '\\n')
                .replace(/\r/g, '\\r');
            
            const replacement = flags 
                ? `new RegExp('${escaped}', '${flags}')`
                : `new RegExp('${escaped}')`;
            
            replacements.push({ start, end: start + fullMatch.length, replacement });
        }
    }
    
    if (replacements.length === 0) {
        fs.writeFileSync(outputPath, content);
        return;
    }
    
    // Apply in reverse order
    let result = content;
    for (let i = replacements.length - 1; i >= 0; i--) {
        const r = replacements[i];
        result = result.slice(0, r.start) + r.replacement + result.slice(r.end);
    }
    
    console.error(`[Transform] Made ${replacements.length} replacements in ${inputPath}`);
    fs.writeFileSync(outputPath, result);
}

// Main
const inputPath = process.argv[2];
const outputPath = process.argv[3];

if (!inputPath || !outputPath) {
    console.error('Usage: node transform-file.js <input> <output>');
    process.exit(1);
}

transformFile(inputPath, outputPath);
