# Agent: run_local_audit

## Overview

The `run_local_audit` agent is responsible for running the Coq/ECMAScript audit pipeline **incrementally**, based only on **uncommitted changes** in the repository.

Instead of analyzing the entire codebase, this agent detects modified `.v` files and restricts the audit to the **exact definitions impacted by those changes**.

This significantly reduces runtime and enables tight feedback loops during development.

---

## Responsibilities

The agent performs the following tasks:

1. **Detect modified Coq files**
   - Uses `git diff --name-only`
   - Filters only `.v` files

2. **Identify changed regions**
   - Uses `git diff <file>` to extract modified line ranges

3. **Map changes to Coq definitions**
   - Locates `Definition` and `Fixpoint` blocks
   - Selects only those overlapping modified lines

4. **Prepare audit input**
   - Extracts relevant definitions
   - Stores them in a temporary JSON structure

5. **Run audit pipeline**
   - Invokes the existing Python script with filtered input
   - Avoids running on the full codebase

6. **Collect and summarize results**
   - Counts analyzed definitions
   - Reports number of detected issues
   - Stores JSON + HTML outputs

---

## Key Properties

- **Incremental**: Only analyzes what changed
- **Deterministic**: Same input → same output
- **Non-intrusive**: Does not modify code
- **Composable**: Can be chained with fixing agents

---

## Inputs

The agent implicitly depends on:

- A Git repository
- Uncommitted changes in `.v` files
- The audit Python script
- Existing extraction logic (`extract_defs`)

Optional:
- A JSON override of definitions (`--defs-json`)

---

## Outputs

- Structured audit results (JSON)
- Human-readable report (HTML)
- Summary:
  - Number of modified files
  - Number of definitions analyzed
  - Number of issues detected

---

## Constraints

- MUST NOT analyze the full repository unless no filtering is possible
- MUST only consider `.v` files
- MUST only include definitions overlapping modified lines
- MUST NOT modify code (read-only mode)
- MUST NOT attempt fixes unless explicitly enabled

---

## Optional Capabilities

When extended, the agent can:

- Trigger a fixing agent (`fix_audit_entry`)
- Apply patches to the codebase
- Run `dune build` to validate fixes
- Keep only compiling changes

---

## Typical Use Cases

- Pre-commit validation
- Local development feedback loop
- CI optimization (partial analysis)
- Integration with automated repair pipelines

---

## Limitations

- Relies on correct diff-to-definition mapping
- Does not detect semantic issues (only what audit pipeline reports)
- Requires Git to be available and repository to be initialized

---

## Summary

`run_local_audit` is a fast, focused, and developer-friendly agent that ensures only **relevant parts of the Coq mechanization** are audited after changes, enabling efficient iteration and seamless integration with automated fixing workflows.