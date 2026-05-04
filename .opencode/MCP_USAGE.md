# MCP Usage in Warblre

## What is MCP?
Model Context Protocol (MCP) is a protocol that allows AI agents to interact with external tools and servers. In this project, MCP connects subagents to the **rocq-mcp** server for Rocq/Coq development.

## Current MCP Configuration

### Server: `rocq-mcp`
```json
{
    "rocq-mcp": {
        "enabled": true,
        "type": "local",
        "command": "/home/valentin/epfl/masterProject/rocq-mcp/.venv/bin/python",
        "args": ["-m", "rocq_mcp.server"],
        "env": {
            "ROCQ_WORKSPACE": "/home/valentin/epfl/masterProject/warblre",
            "ROCQPATH": "_build/default/mechanization",
            "ROCQ_COQC_BINARY": "coqc",
            "ROCQ_PET_TIMEOUT": "30",
            "ROCQ_COQC_TIMEOUT": "60",
            "ROCQ_VERIFY_TIMEOUT": "120"
        }
    }
}
```

**Location**: `.opencode/opencode.json`

### Key Parameters
- **command**: Python interpreter that runs `rocq_mcp.server`
- **type**: `local` - Runs on local machine via stdio
- **env.ROCQ_WORKSPACE**: Working directory for Rocq compilation
- **env.ROCQPATH**: Points to compiled Rocq modules for imports resolution

## How Agents Use MCP

### 1. Proof Fixing Agents (`fix_audit_entry`, `fix_audit_batch`)
```
User Task → fix_audit_entry subagent
                ↓
         [Writes fixed Coq code]
                ↓
         [Compiles with `dune build`]
                ↓
         [Verifies with rocqchk]
```
These agents use the existing build pipeline (not direct MCP calls in the current setup), but MCP rocq-mcp can be leveraged for:
- Pre-checking proof edits before full compilation
- Getting real-time error messages on syntax/type issues
- Interactive proof stepping with `rocq_start`, `rocq_check`, `rocq_step_multi`

### 2. Audit Agents (`run_local_audit`)
```
User Task → run_local_audit subagent
                ↓
          [git diff to find changes]
                ↓
          [Extracts modified definitions]
                ↓
          [Runs audit python script]
```

## Subagent Tool Access

The subagents in this project have access to these tools via the OpenCode framework:

| Agent | Task Tool | MCP Access |
|-------|-----------|------------|
| `fix_audit_batch` | Yes - delegates to `fix_audit_entry` | Via framework |
| `fix_audit_entry` | No | Via framework |
| `annotate_rocq` | No | Via framework |
| `implement_proposal` | No | Via framework |
| `run_local_audit` | No | Via framework |

## Activating MCP for Proof Help

When you (or a subagent) work on proofs:

1. **The framework automatically connects** to rocq-mcp if configured in `.opencode/opencode.json`
2. **Subagents get enhanced context**:
   - Current proof goals via `rocq_start`
   - Error locations in `.v` files via `rocq_compile_file`
   - Type information for definitions via `rocq_query`
   - Interactive tactic trial via `rocq_step_multi`
3. **Build verification** is still done via `dune build` as the ground truth

## Example Workflow

```
1. User: "Fix this broken proof"
           ↓
2. fix_audit_entry agent loads the file
           ↓
3. [MCP] rocq-mcp compiles the file and reports errors
           ↓
4. Agent uses rocq_start + rocq_step_multi to explore tactics
           ↓
5. [MCP] rocq-mcp validates the change
           ↓
6. Agent runs `dune build` to confirm
           ↓
7. Success response
```

## Files Related to MCP

- `.opencode/opencode.json` - MCP server configuration
- `.opencode/mcp_guide.md` - Detailed setup guide
- `AGENTS.md` - Mentions MCP in project guidelines

## Current Status

- ✅ `rocq-mcp` installed in `/home/valentin/epfl/masterProject/rocq-mcp`
- ✅ MCP configuration using `rocq-mcp` server
- ✅ Compiled `.vo` files present in `_build/default/mechanization`
- ✅ Subagents ready to use via `task` tool
