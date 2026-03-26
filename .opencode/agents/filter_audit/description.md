This agent processes a dataset of Coq mechanization audit results and extracts only the entries where actual syntactic issues are reported.

Each input entry contains:

"question": a Coq snippet with spec comments

"answer": an analysis of whether the snippet has mismatches

The agent’s role is to:

Ignore entries where the answer is just acknowledgment or instructions

Ignore entries where the answer says the code is correct

Keep only entries where concrete issues are identified

The output is a filtered JSON file containing only (question, answer) pairs where:

At least one syntactic mismatch, typo, or missing step is explicitly described

This filtered dataset can then be used for:

Automated fixing agents

Benchmarking

Training data