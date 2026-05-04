#!/usr/bin/env node
/**
 * Warblre Project Context MCP Server
 * 
 * Provides project-specific tools for Rocq proof assistance:
 * - Finding admitted proofs
 * - Searching by spec comments
 * - Getting inductive constructors
 * - Finding similar proof patterns
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// MCP Protocol handlers
const tools = {
  find_admitted_proofs: async (args) => {
    const { module } = args;
    const mechanizationPath = path.resolve(__dirname, '../../mechanization');
    
    try {
      const globPattern = module 
        ? `${mechanizationPath}/**/${module}.v`
        : `${mechanizationPath}/**/*.v`;
      
      const files = await findFiles(globPattern);
      const admitted = [];
      
      for (const file of files) {
        const content = fs.readFileSync(file, 'utf8');
        const lines = content.split('\n');
        
        let currentLemma = null;
        let inProof = false;
        
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i];
          
          // Match theorem/lemma/definition start
          const lemmaMatch = line.match(/^(Theorem|Lemma|Definition|Fixpoint)\s+(\w+)/);
          if (lemmaMatch) {
            currentLemma = {
              name: lemmaMatch[2],
              type: lemmaMatch[1],
              line: i + 1,
              file: file.replace(mechanizationPath, 'mechanization')
            };
            inProof = false;
          }
          
          // Match Proof start
          if (line.match(/^Proof\./)) {
            inProof = true;
          }
          
          // Match Admitted
          if (line.match(/Admitted\./) && currentLemma) {
            admitted.push({
              ...currentLemma,
              admittedLine: i + 1,
              hasProof: inProof
            });
            currentLemma = null;
            inProof = false;
          }
          
          // Match Qed (reset)
          if (line.match(/Qed\./)) {
            currentLemma = null;
            inProof = false;
          }
        }
      }
      
      return {
        admitted_proofs: admitted,
        count: admitted.length
      };
    } catch (error) {
      return { error: error.message };
    }
  },

  get_custom_tactics: async (args) => {
    const { tactic_name } = args;
    const tacticsPath = path.resolve(__dirname, '../../mechanization/tactics');
    
    try {
      const tactics = {};
      const files = fs.readdirSync(tacticsPath).filter(f => f.endsWith('.v'));
      
      for (const file of files) {
        const content = fs.readFileSync(path.join(tacticsPath, file), 'utf8');
        
        // Extract tactic definitions
        const tacticMatches = content.matchAll(
          /(?:Tactic\s+Notation|Ltac)\s+(?:(?:"([^"]+)")|(\w+))[^.]*:=([^\n]*(?:\n(?!(?:Tactic|Ltac|Qed|Defined)\s)[^\n]*)*)/g
        );
        
        for (const match of tacticMatches) {
          const name = match[1] || match[2];
          const definition = match[3].trim();
          
          if (!tactic_name || name === tactic_name) {
            tactics[name] = {
              file: file,
              definition: definition.substring(0, 200) + (definition.length > 200 ? '...' : '')
            };
          }
        }
      }
      
      return {
        tactics: tactics,
        count: Object.keys(tactics).length
      };
    } catch (error) {
      return { error: error.message };
    }
  },

  search_by_spec_comment: async (args) => {
    const { spec_reference } = args;
    const mechanizationPath = path.resolve(__dirname, '../../mechanization');
    
    try {
      const results = [];
      const files = await findFiles(`${mechanizationPath}/**/*.v`);
      
      for (const file of files) {
        const content = fs.readFileSync(file, 'utf8');
        const lines = content.split('\n');
        
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i];
          
          // Match spec comments like (*>> ... <<*)
          const specMatch = line.match(/\(\*>>\s*(.+?)\s*<<\*\)/);
          if (specMatch) {
            const specContent = specMatch[1];
            
            if (!spec_reference || specContent.toLowerCase().includes(spec_reference.toLowerCase())) {
              // Get surrounding context
              const contextStart = Math.max(0, i - 2);
              const contextEnd = Math.min(lines.length, i + 3);
              const context = lines.slice(contextStart, contextEnd).join('\n');
              
              results.push({
                file: file.replace(mechanizationPath, 'mechanization'),
                line: i + 1,
                spec_comment: specContent,
                context: context
              });
            }
          }
        }
      }
      
      return {
        results: results,
        count: results.length
      };
    } catch (error) {
      return { error: error.message };
    }
  },

  get_inductive_constructors: async (args) => {
    const { type_name, module } = args;
    const mechanizationPath = path.resolve(__dirname, '../../mechanization');
    
    try {
      const searchPath = module 
        ? path.join(mechanizationPath, `${module.replace(/\./g, '/')}.v`)
        : mechanizationPath;
      
      const files = fs.existsSync(searchPath) && fs.statSync(searchPath).isFile()
        ? [searchPath]
        : await findFiles(`${searchPath}/**/*.v`);
      
      for (const file of files) {
        const content = fs.readFileSync(file, 'utf8');
        
        // Find inductive type definition
        const inductiveRegex = new RegExp(
          `Inductive\\s+${type_name}\\s*[^:]*:([^\\.]+\\.)?`,
          's'
        );
        
        const match = content.match(inductiveRegex);
        if (match) {
          const startIndex = match.index;
          const endMatch = content.substring(startIndex).match(/\\.\\s*(?=(?:Definition|Theorem|Lemma|Inductive|End\\s+\\w+|$))/);
          const endIndex = endMatch ? startIndex + endMatch.index : content.length;
          const definition = content.substring(startIndex, endIndex);
          
          // Extract constructors
          const constructors = [];
          const ctorMatches = definition.matchAll(/\\|\\s+(\\w+)\\s*:/g);
          for (const ctor of ctorMatches) {
            constructors.push(ctor[1]);
          }
          
          return {
            type_name,
            file: file.replace(mechanizationPath, 'mechanization'),
            definition: definition.substring(0, 500),
            constructors: constructors
          };
        }
      }
      
      return { error: `Type ${type_name} not found` };
    } catch (error) {
      return { error: error.message };
    }
  },

  get_lemma_statement: async (args) => {
    const { name } = args;
    const mechanizationPath = path.resolve(__dirname, '../../mechanization');
    
    try {
      const files = await findFiles(`${mechanizationPath}/**/*.v`);
      
      for (const file of files) {
        const content = fs.readFileSync(file, 'utf8');
        
        // Find lemma/theorem statement
        const lemmaRegex = new RegExp(
          `(Theorem|Lemma)\\s+${name}\\s*([^:]+):`,
          's'
        );
        
        const match = content.match(lemmaRegex);
        if (match) {
          const startIndex = match.index;
          const binders = match[2];
          
          // Find the statement (up to Proof. or .)
          const afterName = startIndex + match[0].length;
          const rest = content.substring(afterName);
          const endMatch = rest.match(/(?:Proof\\.|\\.\\s*(?=(?:Definition|Theorem|Lemma|Remark|Example|$)))/);
          const statement = rest.substring(0, endMatch ? endMatch.index : 500).trim();
          
          return {
            name,
            type: match[1],
            file: file.replace(mechanizationPath, 'mechanization'),
            binders: binders.trim(),
            statement: statement
          };
        }
      }
      
      return { error: `Lemma ${name} not found` };
    } catch (error) {
      return { error: error.message };
    }
  },

  find_similar_proofs: async (args) => {
    const { goal_pattern, limit = 5 } = args;
    const mechanizationPath = path.resolve(__dirname, '../../mechanization');
    
    try {
      const matches = [];
      const files = await findFiles(`${mechanizationPath}/**/*.v`);
      
      for (const file of files) {
        const content = fs.readFileSync(file, 'utf8');
        
        // Find completed proofs
        const proofRegex = /(Theorem|Lemma|Definition|Fixpoint)\s+(\w+)[^:]*:[^\.]*\.\s*Proof\.[\s\S]*?Qed\./g;
        let match;
        
        while ((match = proofRegex.exec(content)) !== null) {
          const proofText = match[0];
          
          // Check if it matches the pattern
          if (proofText.toLowerCase().includes(goal_pattern.toLowerCase())) {
            const nameMatch = proofText.match(/(?:Theorem|Lemma|Definition|Fixpoint)\s+(\w+)/);
            
            matches.push({
              name: nameMatch ? nameMatch[1] : 'unknown',
              file: file.replace(mechanizationPath, 'mechanization'),
              preview: proofText.substring(0, 300)
            });
            
            if (matches.length >= limit) break;
          }
        }
        
        if (matches.length >= limit) break;
      }
      
      return {
        similar_proofs: matches,
        count: matches.length
      };
    } catch (error) {
      return { error: error.message };
    }
  }
};

// Helper function to find files recursively (native Node.js, no dependencies)
async function findFiles(pattern) {
  // Parse pattern like "path/**/*.v" to directory + extension
  const parts = pattern.split('**');
  const baseDir = parts[0].replace(/\*$/, '').replace(/\/$/, '');
  const extMatch = pattern.match(/\.([^.]+)$/);
  const targetExt = extMatch ? '.' + extMatch[1] : null;
  
  const results = [];
  
  async function walk(dir) {
    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        
        if (entry.isDirectory()) {
          // Recursively walk subdirectories
          await walk(fullPath);
        } else if (entry.isFile()) {
          // Check if file matches extension
          if (!targetExt || fullPath.endsWith(targetExt)) {
            results.push(fullPath);
          }
        }
      }
    } catch (err) {
      // Directory might not exist or not accessible
    }
  }
  
  await walk(baseDir);
  return results;
}

// MCP Protocol handling
process.stdin.setEncoding('utf8');

let buffer = '';

process.stdin.on('data', (chunk) => {
  buffer += chunk;
  
  // Process complete JSON-RPC messages
  while (true) {
    const contentLengthMatch = buffer.match(/Content-Length:\s*(\d+)\r?\n/);
    if (!contentLengthMatch) break;
    
    const contentLength = parseInt(contentLengthMatch[1], 10);
    const headerEnd = buffer.indexOf('\r\n\r\n');
    if (headerEnd === -1) break;
    
    const messageStart = headerEnd + 4;
    if (buffer.length < messageStart + contentLength) break;
    
    const message = buffer.substring(messageStart, messageStart + contentLength);
    buffer = buffer.substring(messageStart + contentLength);
    
    try {
      const request = JSON.parse(message);
      handleRequest(request);
    } catch (error) {
      sendError(null, -32700, 'Parse error', error.message);
    }
  }
});

async function handleRequest(request) {
  const { id, method, params } = request;
  
  if (method === 'initialize') {
    sendResponse(id, {
      protocolVersion: '2024-11-05',
      capabilities: {
        tools: Object.keys(tools)
      },
      serverInfo: {
        name: 'warblre-context',
        version: '1.0.0'
      }
    });
    return;
  }
  
  if (method === 'tools/list') {
    sendResponse(id, {
      tools: Object.entries(tools).map(([name, handler]) => ({
        name,
        description: handler.description || `Execute ${name}`
      }))
    });
    return;
  }
  
  if (method === 'tools/call') {
    const { name, arguments: args } = params;
    const tool = tools[name];
    
    if (!tool) {
      sendError(id, -32601, `Tool ${name} not found`);
      return;
    }
    
    try {
      const result = await tool(args);
      sendResponse(id, {
        content: [
          {
            type: 'text',
            text: JSON.stringify(result, null, 2)
          }
        ]
      });
    } catch (error) {
      sendError(id, -32603, error.message);
    }
    return;
  }
  
  if (method === 'shutdown') {
    sendResponse(id, null);
    process.exit(0);
  }
}

function sendResponse(id, result) {
  const response = {
    jsonrpc: '2.0',
    id,
    result
  };
  const message = JSON.stringify(response);
  process.stdout.write(`Content-Length: ${Buffer.byteLength(message)}\r\n\r\n${message}`);
}

function sendError(id, code, message, data) {
  const error = {
    jsonrpc: '2.0',
    id,
    error: {
      code,
      message,
      data
    }
  };
  const messageStr = JSON.stringify(error);
  process.stdout.write(`Content-Length: ${Buffer.byteLength(messageStr)}\r\n\r\n${messageStr}`);
}

// Log startup
console.error('Warblre MCP Server started');
