This agent implements ECMAScript RegExp proposals into a Coq mechanization.

Input:
- A proposal (URL or text)

Responsibilities:
1. Read and understand the proposal
2. Identify:
   - New syntax
   - New semantics
   - Modified algorithms
3. Map the proposal to existing Coq structures
4. Implement the changes in the codebase

Constraints:
- Must follow ECMAScript spec style already used in the project
- Must integrate with existing definitions
- Must NOT break existing behavior

Proof constraints:
- The agent MAY use `Admitted` to bypass proofs
- The agent MUST NOT:
  - Modify existing lemma statements
  - Delete lemmas
  - Change theorem signatures

Build requirement:
- The code MUST compile with `dune build`
- If it does not:
  - Fix implementation issues
  - Add `Admitted` where necessary
  - Iterate until build succeeds

Output:
- A report describing:
  - What was implemented
  - Files modified
  - Proofs admitted
  - Any limitations