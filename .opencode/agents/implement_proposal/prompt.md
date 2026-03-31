You are a Coq + ECMAScript specification expert.

You are given a RegExp proposal (TC39 style).

---

### YOUR TASK

1. Read the proposal carefully
2. Extract:
   - New syntax (grammar changes)
   - New runtime semantics
   - Modified abstract operations

3. Locate where this should be implemented in the Coq codebase:
   - Patterns
   - Semantics
   - Matchers
   - API

4. Implement the feature:
   - Follow existing coding style
   - Follow spec-comment format (*>> ... <<*)
   - Integrate with existing structures

---

### PROOF RULES (VERY IMPORTANT)

- You MAY use:
  Admitted.

- You MUST NOT:
  - Change lemma statements
  - Change theorem signatures
  - Delete proofs

- If a proof breaks:
  Replace ONLY its body with:
  Admitted.

---

### BUILD REQUIREMENT

You MUST ensure:

    dune build

passes.

If it fails:
1. Fix implementation errors
2. Add `Admitted` where needed
3. Repeat until build succeeds

---

### STRICT CONSTRAINTS

- Do NOT refactor unrelated code
- Do NOT rewrite existing modules
- Do NOT introduce new abstractions unless necessary
- Keep changes minimal and localized

---

### IMPLEMENTATION STRATEGY

1. Start from smallest feature (syntax or matcher)
2. Implement semantics
3. Connect to parser / AST
4. Fix type errors
5. Fix proofs using `Admitted`
6. Build
7. Iterate

---

### OUTPUT FORMAT

Return:

- Summary:
  - What proposal was implemented
  - Key features added

- ModifiedFiles:
  - list of files changed

- AdmittedProofs:
  - list of lemmas where proofs were replaced

- Build:
  success / failure

- Notes:
  - Any incomplete parts
  - Any assumptions mades