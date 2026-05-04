# OpenCode Agentic Pipeline Configuration

> This guide configures the OpenCode CLI for the Warblre autoformalization pipeline.

---

## 1. Installation

Install the OpenCode CLI using the official installer:

```bash
curl -fsSL https://opencode.ai/install | bash
```

After installation, restart your terminal and verify that `opencode` is available.

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

### 3.1 Add API Key

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

## 4. Autoformalization Pipeline

The pipeline runs sequentially. Each step produces artifacts that feed into the next.

```
annotate_rocq  ──►  implement_from_comments  ──►  audit  ──►  fix_audit_batch  ──►  fix_proofs
```

### 4.1 Prepare Proposal

Before starting, download the proposal and the ECMA diff into:

```
proposals/<your-proposal-name>/
```

> See existing proposal folders for the expected structure.

---

### 4.2 Step 1 — Generate Specification Comments

Insert ECMA specification comments into the Rocq mechanization.

```
@annotate_rocq implement the comments for the following proposal : proposals/<your proposal>
```

**Output:** Annotated `.v` files with `(*>> ... <<*)` spec comments.

---

### 4.3 Step 2 — Implement Code from Comments

Generate Rocq definitions and algorithms from the spec comments inserted in Step 1.

```
@implement_from_comments add the code for the following proposal : proposals/<your proposal>
```

**Output:** Implemented definitions, fixpoints, and (possibly admitted) proofs.

---

### 4.4 Step 3 — Audit

Run the audit tool on the files that changed in `mechanization/spec/`.

> See `README.md` in the audit directory for detailed instructions.

**Output:** Raw audit results (JSON + HTML).

---

### 4.5 Step 4 — Filter Audit Results

Keep only actionable mismatches (syntax errors, missing steps, etc.).

```
@filter_audit filter the audit just generated
```

**Output:** Filtered JSON of concrete issues.

---

### 4.6 Step 5 — Apply Fixes

Automatically repair the issues identified in Step 4.

```
@fix_audit_batch use the latest filter result created and the other subagent on your prompt to solve all of those problems
```

**Output:** Corrected `.v` files.

---

### 4.7 Step 6 — Fix Admitted Proofs

Ensure `rocq-mcp` is running, then synthesize proofs for all remaining `Admitted.` obligations.

```
@fix_proofs fix the admitted proofs
```

**Output:** Complete, compiled proofs.

---

## 5. Quick Reference

| Step | Agent | Input | Output |
|------|-------|-------|--------|
| 1 | `annotate_rocq` | `proposals/<name>/` | Spec comments in `.v` files |
| 2 | `implement_from_comments` | Annotated `.v` files | Implemented definitions |
| 3 | Manual / Audit tool | Changed spec files | Audit JSON / HTML |
| 4 | `filter_audit` | Raw audit results | Filtered issues |
| 5 | `fix_audit_batch` | Filtered issues | Fixed `.v` files |
| 6 | `fix_proofs` | Admitted proofs | Completed proofs |

---

## 6. Verification Checklist

After completing the pipeline, ensure the following before committing:

- [ ] `dune build @all` succeeds without errors
- [ ] `dune test` passes
- [ ] `rocqchk` validates the compiled libraries
- [ ] No `Admitted.` proofs remain
- [ ] Code follows the repository naming conventions
- [ ] Spec comments reference the correct ECMAScript sections
