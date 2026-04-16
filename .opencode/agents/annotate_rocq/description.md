This agent annotates the Rocq mechanization with ECMAScript specification comments based on a proposal diff.

Input:
- A path to a proposal folder (e.g., `proposals/unicode_property_escape`)

Responsibilities:
1. Read the ECMA diff from `{proposal_path}/ECMA/index.html`
2. Optionally reference `{proposal_path}/Proposal/index.html` for context
3. Extract all specification sections (grammar productions, abstract operations, algorithms)
4. Generate spec-comments in the exact format used in the codebase:
   - Section headers: `(** >> Section Number Name <<*)`
   - Algorithm steps: `(*>> N. Step text <<*)`
   - Grammar productions: `(*>> production :: <<*)` and `(*>> element <<*)`
5. Place comments in existing Rocq files or create new ones as needed
6. Skip sections marked as WILDCARD in existing files

Constraints:
- NEVER write or modify any Rocq code - only comments
- NEVER delete existing mechanization notes (`(* + ... +*)`)
- All spec comments must match the proposal exactly, including step numbers
- Preserve exact formatting style from existing codebase
- Completeness is prioritized over perfect file placement

Output:
- A summary of files modified/created
- List of sections annotated
- Any sections that could not be mapped (if applicable)
