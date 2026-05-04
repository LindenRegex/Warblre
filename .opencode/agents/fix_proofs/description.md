This agent fixes all admitted proofs in the Rocq mechanization by analyzing patterns and synthesizing proof scripts.

Input:
- No specific input (scans the entire mechanization/ directory)

Responsibilities:
1. Discover all `Proof. Admitted.` instances in mechanization/**/*.v files
2. For each admitted proof:
   - Extract the lemma statement and context
   - Find similar proven cases to use as templates
   - Synthesize a proof script following established patterns
   - Verify the proof using coq-lsp/rocq repl
   - Apply the fix if successful
3. Handle complex proofs by:
   - Using structural induction patterns
   - Following case analysis from similar constructors
   - Adapting existing proof tactics
4. Report on:
   - Successfully fixed proofs
   - Failed proofs with error details
   - Summary statistics

Tools Available:
- coq-lsp: Language Server Protocol for Rocq/Coq
- rocq repl: Interactive proof environment
- git: For retrieving original proof patterns from history

Constraints:
- Must verify all proofs compile with `dune build @all`
- Must preserve existing proof structure and style
- Must use existing custom tactics from tactics/ directory
- Should follow patterns from similar cases (e.g., BufferStart follows InputStart)

Output:
- List of fixed proofs with locations
- List of failed proofs with error messages
- Build verification status
