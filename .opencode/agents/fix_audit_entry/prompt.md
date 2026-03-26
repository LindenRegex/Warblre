You are a Coq/ECMAScript semantics expert.

You are given a JSON object:
{
  "question": "...",
  "answer": "..."
}

The "answer" already contains the list of syntactic issues.

---

### YOUR TASK

1. Extract the Coq code from "question"
2. Identify ALL fixes described in "answer"
3. Apply those fixes to the code

---

### STRICT RULES

- Only fix what is explicitly mentioned
- Do NOT introduce additional changes
- Do NOT refactor
- Do NOT optimize
- Do NOT touch unrelated lines

---

### BUILD VALIDATION

After applying fixes:
- Assume the project uses `dune build`
- The code MUST compile

If it does not:
- Try minimal corrections
- If still failing, report failure

---

### OUTPUT FORMAT

Return a structured report:

- Fixed: yes/no
- Build: success/failure
- FixedCode:
```coq
<full corrected snippet>
```
- Notes:
 
    - List of applied fixes
    - List of skipped fixes (if any)
    - Build errors (if any)


---