# MCP Integration for Warblre

## Overview
The project uses **rocq-mcp** as an MCP (Model Context Protocol) server to provide real-time proof checking and code navigation for the Rocq/Coq mechanization.

## rocq-mcp Server
rocq-mcp is a Python-based MCP server for Rocq proof development that exposes compilation, verification, querying, and interactive tactic stepping as MCP tools.

## Configuration

### Server: `rocq-mcp`
- **Type**: local (stdio-based)
- **Command**: Python interpreter running `rocq_mcp.server`
- **Environment**:
  - `ROCQ_WORKSPACE=/home/valentin/epfl/masterProject/warblre`
  - `ROCQPATH=_build/default/mechanization`
  - `ROCQ_COQC_BINARY=coqc`

### Setup Requirements
1. Ensure rocq-mcp is installed in the virtual environment at `/home/valentin/epfl/masterProject/rocq-mcp`
2. Ensure the project is built (`.vo` files exist):
   ```bash
   opam exec -- dune build @all
   ```

### Prerequisites
- **Rocq / Coq** -- `coqc` must be on your `PATH`
  - **pet** (from pytanque) -- optional, needed only for interactive tools (`rocq_start`, `rocq_check`, `rocq_step_multi`, etc.)
- **Python 3.11+**

## rocq-mcp Tools

| Tool | Description |
|------|-------------|
| `rocq_compile_file` | Batch-compile a `.v` file. Returns errors and proof state on failure. |
| `rocq_check` | Run proof commands with cached imports — fast iterative checking. |
| `rocq_step_multi` | Try multiple tactics at once (max 20). Does not advance state. |
| `rocq_start` | Start an interactive proof session by theorem name or position. |
| `rocq_query` | Search the Rocq environment — find lemmas, check types, inspect definitions. |
| `rocq_toc` | Get the structure of a `.v` file as a hierarchical outline. |
| `rocq_assumptions` | Check what axioms a theorem depends on. |
| `rocq_verify` | Verify a proof actually proves the original statement. |

## Usage for Subagents

When subagents (like `fix_audit_entry`, `fix_audit_batch`) need to work with Rocq proofs, the MCP server provides:
- **Compilation**: Compile and check `.v` files with `rocq_compile_file`
- **Interactive proof stepping**: Start proofs, try tactics, check progress via `rocq_start` / `rocq_check` / `rocq_step_multi`
- **Environment querying**: Search lemmas and check types via `rocq_query`
- **Document structure**: Navigate through lemmas, definitions, theorems via `rocq_toc`

## How Agents Use It

The subagents can call the MCP server through the `task` tool mechanism. For example:
- `fix_audit_entry` can use `rocq_compile_file` to check if a proof compiles after changes
- `fix_proofs` can use `rocq_start` + `rocq_step_multi` to interactively find correct tactics
- `run_local_audit` can use `rocq_query` to extract definitions and their types
- `annotate_rocq` can use `rocq_toc` to verify spec comments align with actual code

## Troubleshooting

If rocq-mcp fails to start:
1. Check `ROCQ_WORKSPACE` points to the correct project directory
2. Ensure `.vo` compilation artifacts are present in `_build/default/mechanization`
3. Verify `coqc` is on the PATH and matches your Rocq version (currently 9.1.0)
4. If interactive tools fail, ensure `pet` (from the pytanque package) is installed
