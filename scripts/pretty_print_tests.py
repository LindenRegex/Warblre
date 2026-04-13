#!/usr/bin/env python3
"""
Convert OCaml test file to JavaScript test262-style format.

This script parses OCaml test files that use Warblre's test_regex function
and prints them in JavaScript test262 format.

Usage:
    python3 pretty_print_tests.py <path_to_ml_file>

Example:
    python3 pretty_print_tests.py tests/tests/RegExpModifiers.ml
"""

import re
import sys
from pathlib import Path


def extract_string_content(s):
    """Extract content from OCaml string literals."""
    # Handle escape sequences
    s = s.replace("\\n", "\n")
    s = s.replace("\\t", "\t")
    s = s.replace("\\r", "\r")
    s = s.replace('\\"', '"')
    s = s.replace("\\\\", "\\")
    return s


def simplify_regex_expr(expr):
    """Simplify OCaml regex expression to a JavaScript pattern string."""
    # Remove module prefixes
    expr = re.sub(r"Warblre\.UnicodeProperties\.UnicodeProperty\.", "", expr)
    expr = re.sub(r"Warblre\.Extracted\.Patterns\.", "", expr)

    # Simplify common patterns
    expr = expr.replace("Coq_esc_w", "\\w")
    expr = expr.replace("Coq_esc_W", "\\W")
    expr = expr.replace("Coq_esc_s", "\\s")
    expr = expr.replace("Coq_esc_S", "\\S")
    expr = expr.replace("Coq_esc_d", "\\d")
    expr = expr.replace("Coq_esc_D", "\\D")
    expr = expr.replace("Coq_esc_b", "\\b")
    expr = expr.replace("Coq_esc_B", "\\B")

    # Simplify ModifierAdd/Remove
    expr = re.sub(r"ModifierAdd\s*\(\s*\[([^\]]+)\]\s*,\s*", r"(?\1:", expr)
    expr = re.sub(
        r"ModifierRemove\s*\(\s*\[([^\]]*)\]\s*,\s*\[([^\]]*)\]\s*,\s*",
        r"(?\1-\2:",
        expr,
    )
    expr = re.sub(r"modchar\s*\'([ims])\'", r"\1", expr)

    # Simplify character constructions
    expr = re.sub(r"cchar\s*\'([^\'])\'", r"\1", expr)
    expr = re.sub(r"ichar\s*(\d+)", lambda m: chr(int(m.group(1))), expr)
    expr = re.sub(r"sc\s*\'([^\'])\'", r"\1", expr)

    # Simplify escapes
    expr = re.sub(
        r"hex_escape\s*\'([0-9a-fA-F])\'\s*\'([0-9a-fA-F])\'", r"\\x\1\2", expr
    )
    expr = re.sub(r"ascii_letter_escape\s*\'([a-zA-Z])\'", r"\\c\1", expr)

    # Simplify operators
    expr = expr.replace(" -- ", "")
    expr = expr.replace(" ||| ", "|")
    expr = expr.replace(" || ", "|")

    # Simplify common regex constructs
    expr = expr.replace("InputStart", "^")
    expr = expr.replace("InputEnd", "$")
    expr = expr.replace("Dot", ".")
    expr = expr.replace("WordBoundary", r"\b")
    expr = expr.replace("NotWordBoundary", r"\B")

    # Simplify quantifiers
    expr = re.sub(r"!\*\?\s*\(", r"(?:", expr)
    expr = re.sub(r"!\*\s*\(", r"(?:", expr)
    expr = re.sub(r"!\+\?\s*\(", r"(?:", expr)
    expr = re.sub(r"!\+\s*\(", r"(?:", expr)
    expr = re.sub(r"!\?\?\s*\(", r"(?:", expr)
    expr = re.sub(r"!\?\s*\(", r"(?:", expr)

    # Simplify groups
    expr = re.sub(r"group\s*\(", r"(", expr)
    expr = re.sub(r'ngroup\s*\(\s*"([^"]+)"\s*,', r"(?<\1>", expr)

    # Simplify backreferences
    expr = re.sub(r"!\$\s*(\d+)", r"\\\1", expr)
    expr = re.sub(r'!&\s*"([^"]+)"', r"\\k<\1>", expr)

    # Simplify character classes
    expr = re.sub(
        r"CharacterClass\s*\(NoninvertedCC\s*\(([^)]+)\)\)",
        lambda m: f"[{simplify_class_ranges(m.group(1))}]",
        expr,
    )
    expr = re.sub(
        r"CharacterClass\s*\(InvertedCC\s*\(([^)]+)\)\)",
        lambda m: f"[^{simplify_class_ranges(m.group(1))}]",
        expr,
    )

    # Simplify atom escapes
    expr = re.sub(r"AtomEsc\s*\(ACharacterEsc\s*([^)]+)\)", r"\1", expr)
    expr = re.sub(r"AtomEsc\s*\(ACharacterClassEsc\s*([^)]+)\)", r"\1", expr)

    # Clean up UnicodeProp
    expr = re.sub(r"UnicodeProp\s+([^)]+)", r"\\p{\1}", expr)
    expr = re.sub(r"UnicodePropNeg\s+([^)]+)", r"\\P{\1}", expr)

    # Remove Empty/EmptyCR
    expr = re.sub(r"EmptyCR?", "", expr)

    # Clean up ClassAtomCR
    expr = re.sub(r"ClassAtomCR\s*\([^,]+,\s*", "", expr)

    # Remove extra whitespace and parentheses
    expr = re.sub(r"\s+", " ", expr)
    expr = re.sub(r"\(\s*\)", "", expr)

    return expr.strip()


def simplify_class_ranges(expr):
    """Simplify class range expressions."""
    expr = re.sub(r"RangeCR\s*\([^,]+,\s*([^,]+),\s*([^)]+)\)", r"\1-\2", expr)
    expr = re.sub(r"ClassAtomCR\s*\(([^,]+),\s*", r"\1", expr)
    expr = re.sub(r"sc\s*\'([^\'])\'", r"\1", expr)
    return expr


def extract_tests_simple(filepath):
    """Extract test blocks from OCaml file."""
    content = Path(filepath).read_text()

    tests = []

    # Split by let%expect_test
    blocks = re.split(r"(?=let%expect_test)", content)

    for block in blocks[1:]:  # Skip first empty block
        name_match = re.match(r'let%expect_test\s+"([^"]+)"', block)
        if not name_match:
            continue

        name = name_match.group(1)

        # Find test_regex call
        test_match = re.search(
            r'test_regex\s*\((.+?)\)\s+"([^"]*)"\s+(\d+)([^)]*)\(\)', block, re.DOTALL
        )
        if not test_match:
            continue

        regex_part = test_match.group(1)
        input_str = test_match.group(2)
        position = test_match.group(3)
        flags_part = test_match.group(4)

        # Clean up regex expression
        regex_expr = regex_part.strip()

        # Parse flags
        ignoreCase = "~ignoreCase:true" in flags_part
        dotAll = "~dotAll:true" in flags_part
        multiline = "~multiline:true" in flags_part
        unicode = "~unicode:true" in flags_part or "unicode" in name.lower()

        # Parse expected output to determine if match is expected
        # Look for [%expect {| ... |}] block
        expect_match = re.search(r"\[%expect\s*\{\|\s*(.*?)\s*\|\}\]", block, re.DOTALL)
        should_match = True  # Default to match
        if expect_match:
            expect_content = expect_match.group(1)
            # If it says "No match", then it shouldn't match
            if "No match" in expect_content:
                should_match = False

        tests.append(
            {
                "name": name,
                "regex_expr": regex_expr,
                "input": input_str,
                "position": position,
                "ignoreCase": ignoreCase,
                "dotAll": dotAll,
                "multiline": multiline,
                "unicode": unicode,
                "should_match": should_match,
            }
        )

    return tests


def get_js_flags(test):
    """Get JavaScript regex flags."""
    flags = ""
    if test["ignoreCase"]:
        flags += "i"
    if test["multiline"]:
        flags += "m"
    if test["dotAll"]:
        flags += "s"
    if test["unicode"]:
        flags += "u"
    return flags


def format_js_input(input_str):
    """Format input string for JavaScript output."""
    # Escape special characters for JavaScript string
    result = input_str.replace("\\", "\\\\")
    result = result.replace('"', '\\"')
    result = result.replace("\n", "\\n")
    result = result.replace("\t", "\\t")
    result = result.replace("\r", "\\r")
    return result


def format_js_pattern(pattern, flags):
    """Format pattern for JavaScript regex."""
    # Escape forward slashes in pattern
    pattern = pattern.replace("/", "\\/")

    if flags:
        return f"/{pattern}/{flags}"
    else:
        return f"/{pattern}/"


def extract_re_number(test_name):
    """Extract re number from test name (e.g., 'add_ignoreCase_re1_1' -> 1)."""
    match = re.search(r"_re(\d+)_", test_name)
    if match:
        return int(match.group(1))
    return None


def extract_file_from_test_name(test_name):
    """Extract original JS file name from test name (e.g., 'add_ignoreCase_re1_1' -> 'add-ignoreCase.js')."""
    # Remove everything from _reN onwards (where N is a number)
    # This handles: add_ignoreCase_re1_1 -> add_ignoreCase, add_multiline_re1 -> add_multiline
    name = re.sub(r"_re\d+.*$", "", test_name)
    # Convert underscores to hyphens
    name = name.replace("_", "-")
    # Add .js extension
    return f"{name}.js"


def extract_base_name(test_name):
    """Extract base name for grouping (e.g., 'add_ignoreCase_re1_1' -> 'add_ignoreCase_re1')."""
    # Extract up to and including the _reN part
    match = re.search(r"^(.*_re\d+)", test_name)
    if match:
        return match.group(1)
    return test_name


def print_js_tests(tests):
    """Print tests in JavaScript test262 format."""
    if not tests:
        print("// No test_regex calls found in file.")
        return

    # Group tests by their source file
    current_file = None
    current_re = None
    re_counter = 0

    for i, test in enumerate(tests):
        file_name = extract_file_from_test_name(test["name"])
        re_num = extract_re_number(test["name"])

        # If this is a new file, print a comment
        if file_name != current_file:
            current_file = file_name
            print(f"\n// From: {file_name}")

        # If this is a new re group, increment counter
        if re_num is not None and re_num != current_re:
            re_counter = re_num
            current_re = re_num

        pattern = simplify_regex_expr(test["regex_expr"])
        flags = get_js_flags(test)
        js_pattern = format_js_pattern(pattern, flags)
        js_input = format_js_input(test["input"])

        # Use the parsed expected result
        should_match = test["should_match"]

        # Generate assertion
        var_name = f"re{re_counter}"

        # Print variable declaration if this is the first test for this re
        if (
            "_1" in test["name"]
            or "_pos" in test["name"]
            or (i > 0 and extract_re_number(tests[i - 1]["name"]) != re_num)
        ):
            print(f"var {var_name} = {js_pattern};")

        # Generate assertion
        if should_match:
            print(f'assert({var_name}.test("{js_input}"), "Test: {test["name"]}");')
        else:
            print(f'assert(!{var_name}.test("{js_input}"), "Test: {test["name"]}");')


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 pretty_print_tests.py <path_to_ml_file>")
        print("\nExample:")
        print("  python3 pretty_print_tests.py tests/tests/RegExpModifiers.ml")
        sys.exit(1)

    filepath = sys.argv[1]

    if not Path(filepath).exists():
        print(f"Error: File not found: {filepath}")
        sys.exit(1)

    tests = extract_tests_simple(filepath)
    print_js_tests(tests)


if __name__ == "__main__":
    main()
