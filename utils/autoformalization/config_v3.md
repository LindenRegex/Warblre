# OpenCode Agentic Pipeline Configuration

> Complete setup guide for the Warblre autoformalization pipeline, including LLM provider, MCP server, and audit tool configuration.

---

## 1. Installation

Install the OpenCode CLI using the official installer:

```bash
curl -fsSL https://opencode.ai/install | bash
```

After installation, **restart your terminal** and verify that `opencode` is available.

---

## 2. Provider Setup

### 2.1 Create Configuration File

Save the following provider configuration to `~/.config/opencode/opencode.json`:

```bash
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/opencode.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "myprovider": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "EPFL RCP",
      "options": {
        "baseURL": "https://inference.rcp.epfl.ch/v1"
      },
      "models": {
        "moonshotai/Kimi-K2.5": {
          "name": "moonshotai/Kimi-K2.5",
          "max_tokens": 1000
        },
        "moonshotai/Kimi-K2.6": {
          "name": "moonshotai/Kimi-K2.6",
          "max_tokens": 1000
        }
      }
    }
  }
}
EOF
```

### 2.2 Select a Model

Models are available via `Ctrl + P` → **Change Model** inside OpenCode.

---

## 3. Authentication

Store your EPFL RCP API key in `~/.local/share/opencode/auth.json`:

```bash
mkdir -p ~/.local/share/opencode
cat > ~/.local/share/opencode/auth.json << 'EOF'
{
  "myprovider": {
    "type": "api",
    "key": "<Your key here>"
  }
}
EOF
```

> Replace `<Your key here>` with your actual API key before running any agents.

---

## 4. MCP Server Configuration

The pipeline relies on **rocq-mcp** for interactive proof checking, compilation, and code navigation. This server must be running before you execute agents that touch Rocq code.

### 4.1 Prerequisites

- **Rocq / Coq** — `coqc` must be on your `PATH` (version 9.0.0 or 9.1.0)
- **Python 3.11+**
- **rocq-mcp** — installed in a virtual environment (e.g., `/home/valentin/epfl/masterProject/rocq-mcp`)
- **pet** (from `pytanque`) — optional, required only for interactive tools (`rocq_start`, `rocq_check`, `rocq_step_multi`)
- **Compiled artifacts** — the project must be built so `.vo` files exist

### 4.2 Create MCP Configuration

Create `.opencode/mcp.json` at the project root:

```bash
cat > .opencode/mcp.json << 'EOF'
{
  "$schema": "https://opencode.ai/mcp-schema.json",
  "servers": {
    "rocq-mcp": {
      "name": "Rocq MCP Server",
      "description": "Real-time proof checking and code navigation for Rocq",
      "transport": {
        "type": "stdio",
        "command": "python",
        "args": ["-m", "rocq_mcp.server"]
      },
      "env": {
        "ROCQ_WORKSPACE": "/home/valentin/epfl/masterProject/warblre",
        "ROCQPATH": "_build/default/mechanization",
        "ROCQ_COQC_BINARY": "coqc"
      }
    }
  }
}
EOF
```

> Adjust `ROCQ_WORKSPACE` to your absolute project path if it differs.

### 4.3 Verify the Server

1. Build the project to ensure `.vo` files are present:
   ```bash
   opam exec -- dune build @all
   ```

2. In OpenCode, check that rocq-mcp tools are available. A quick test is:
   ```
   @fix_proofs verify that you can access the mcp server
   ```

### 4.4 rocq-mcp Tools Reference

| Tool | Purpose |
|------|---------|
| `rocq_compile_file` | Batch-compile a `.v` file |
| `rocq_check` | Fast iterative proof checking with cached imports |
| `rocq_step_multi` | Try multiple tactics at once (does not advance state) |
| `rocq_start` | Start an interactive proof session |
| `rocq_query` | Search lemmas, check types, inspect definitions |
| `rocq_toc` | Get the structure of a `.v` file |
| `rocq_assumptions` | Check axioms a theorem depends on |
| `rocq_verify` | Verify a proof proves the original statement |

---

## 5. Audit Tool Configuration

The audit tool checks consistency between specification comments and Rocq implementations. It lives in `utils/autoformalization/audit/`.

### 5.1 Install Dependencies

```bash
cd utils/autoformalization/audit
conda env create -f environment.yml
conda activate coq-audit
```

### 5.2 Configure the Model

Edit `utils/autoformalization/audit/config.json`:

```json
[
  {
    "model": "moonshotai/Kimi-K2.6",
    "base_url": "https://inference.rcp.epfl.ch/v1",
    "generation": {
      "temperature": 0,
      "top_p": 1,
      "max_tokens": 20000,
      "presence_penalty": 0.0,
      "frequency_penalty": 0.0
    }
  }
]
```

> Multiple models can be listed; they will be evaluated sequentially.

### 5.3 Set the API Key

Create `utils/autoformalization/audit/.env`:

```env
API_KEY=your_api_key_here
```

### 5.4 Customize Prompts (Optional)

Edit `utils/autoformalization/audit/prompts.json` to adjust the audit prompts:

```json
{
  "system": "You are verifying consistency between specification comments and implementation.",
  "prompts": [
    "Check whether the implementation follows the steps described in the comments."
  ]
}
```

### 5.5 Run the Audit

Execute the audit from the `utils/autoformalization/audit/` directory:

```bash
python comment_code_audit.py
```

Limit the definition range if needed:

```bash
python comment_code_audit.py --start 10 --end 50
```

**Output location:**

```
results/
  YYYY-MM-DD/
    MODEL_NAME/
      results_TIMESTAMP.json
      results_TIMESTAMP.html
```

---

## 6. Autoformalization Pipeline

Execute the following steps in order. Each step feeds the next.

```
annotate_rocq  ──►  implement_from_comments  ──►  audit  ──►  fix_audit_batch  ──►  fix_proofs
```

### 6.1 Prepare Proposal

Before starting, download the proposal and the ECMA diff into:

```
proposals/<your-proposal-name>/
```

> See existing proposal folders for the expected structure.

---

### 6.2 Step 1 — Generate Specification Comments

Insert ECMA specification comments into the Rocq mechanization.

```
@annotate_rocq implement the comments for the following proposal : proposals/<your proposal>
```

**Output:** Annotated `.v` files with `(*>> ... <<*)` spec comments.

---

### 6.3 Step 2 — Implement Code from Comments

Generate Rocq definitions and algorithms from the spec comments inserted in Step 1.

```
@implement_from_comments add the code for the following proposal : proposals/<your proposal>
```

**Output:** Implemented definitions, fixpoints, and (possibly admitted) proofs.

---

### 6.4 Step 3 — Audit

Run the audit tool on the files that changed in `mechanization/spec/`.

```bash
cd utils/autoformalization/audit
python comment_code_audit.py
```

**Output:** Raw audit results (`results/YYYY-MM-DD/MODEL/`).

---

### 6.5 Step 4 — Filter Audit Results

Keep only actionable mismatches (syntax errors, missing steps, etc.).

```
@filter_audit filter the audit just generated
```

**Output:** Filtered JSON of concrete issues.

---

### 6.6 Step 5 — Apply Fixes

Automatically repair the issues identified in Step 4.

```
@fix_audit_batch use the latest filter result created and the other subagent on your prompt to solve all of those problems
```

**Output:** Corrected `.v` files.

---

### 6.7 Step 6 — Fix Admitted Proofs

Ensure `rocq-mcp` is running, then synthesize proofs for all remaining `Admitted.` obligations.

```
@fix_proofs fix the admitted proofs
```

**Output:** Complete, compiled proofs.

---

## 7. Quick Reference

| Step | Agent / Tool | Input | Output |
|------|-------------|-------|--------|
| 1 | `annotate_rocq` | `proposals/<name>/` | Spec comments in `.v` files |
| 2 | `implement_from_comments` | Annotated `.v` files | Implemented definitions |
| 3 | `comment_code_audit.py` | Changed spec files | Audit JSON / HTML |
| 4 | `filter_audit` | Raw audit results | Filtered issues |
| 5 | `fix_audit_batch` | Filtered issues | Fixed `.v` files |
| 6 | `fix_proofs` | Admitted proofs | Completed proofs |

---

## 8. Verification Checklist

After completing the pipeline, ensure the following before committing:

- [ ] `dune build @all` succeeds without errors
- [ ] `dune test` passes
- [ ] `rocqchk` validates the compiled libraries
- [ ] No `Admitted.` proofs remain
- [ ] Code follows the repository naming conventions
- [ ] Spec comments reference the correct ECMAScript sections
