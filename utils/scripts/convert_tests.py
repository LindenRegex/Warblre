#!/usr/bin/env python3
r"""
Convert OCaml expect-test files to readable JavaScript-style assertions.

Usage:
    python3 convert_tests.py <input.ml file>

Example output:
    // File: slash-lower-case-z-matches-end-of-buffer.js
    assert(/x\z/.test("x"), "Expected /x\z/ to match 'x' (end of buffer)");
"""

import re
import sys
from pathlib import Path


def ocaml_pattern_to_regex(ocaml_pattern: str) -> str:
    """Convert OCaml pattern expression to regex string."""
    pattern = ocaml_pattern.strip()

    # Handle concatenation (--)
    pattern = pattern.replace(' -- ', '')
    pattern = pattern.replace('--', '')

    # Handle constructors
    pattern = pattern.replace('BufferStart', r'\A')
    pattern = pattern.replace('BufferEnd', r'\z')
    pattern = pattern.replace('InputStart', '^')
    pattern = pattern.replace('InputEnd', '$')

    # Handle cchar 'x' -> x
    pattern = re.sub(r"cchar\s+'([^']+)'", r'\1', pattern)

    # Handle parens
    pattern = pattern.replace('(', '').replace(')', '')

    # Clean up whitespace
    pattern = pattern.strip()

    return pattern


def find_current_file(content: str, position: int) -> str:
    """Find the current file comment before the given position."""
    # Look for the pattern:
    # (* ----------------------------------------------------------------------------
    #  * File: filename.js
    #  * Description: ...
    #  * ---------------------------------------------------------------------------- *)

    # Find all file comments and their positions
    file_pattern = r'\(\*\s*-+\s*\n\s*\*\s*File:\s*([^\n]+)\s*\n'
    for match in re.finditer(file_pattern, content):
        if match.end() < position:
            filename = match.group(1).strip()
            return filename
    return None


def convert_test_file(input_path: str):
    """Convert an OCaml test file to JavaScript-style assertions."""
    content = Path(input_path).read_text()

    print(f"// Converted from: {input_path}")
    print("// JavaScript-style assertions\n")

    # Find all let%expect_test blocks
    # Structure:
    # let%expect_test "name" =
    #   test_regex
    #     (pattern)
    #     "input"
    #     pos
    #     [~flags] ();
    #   [%expect {| ... |}]

    # Pattern to find test name and capture everything after until next let%expect_test or EOF
    test_blocks = re.findall(
        r'let%expect_test\s+"([^"]+)"\s*=\s*test_regex\s+((?:(?!let%expect_test)[\s\S])*?)\[%expect\s*\{\|\s*([\s\S]*?)\s*\|\}\]',
        content
    )

    # Also get positions to find the file comments
    test_matches = list(re.finditer(
        r'let%expect_test\s+"([^"]+)"\s*=\s*test_regex\s+((?:(?!let%expect_test)[\s\S])*?)\[%expect\s*\{\|\s*([\s\S]*?)\s*\|\}\]',
        content
    ))

    current_file = None

    for match in test_matches:
        test_name = match.group(1)
        args_section = match.group(2)
        expect_block = match.group(3)
        test_start = match.start()

        # Find which file this test belongs to
        file_name = find_current_file(content, test_start)
        if file_name and file_name != current_file:
            current_file = file_name
            print(f"// File: {current_file}")

        # Parse arguments from args_section
        # Find the first opening paren
        first_paren = args_section.find('(')
        if first_paren == -1:
            continue

        # Find the matching closing paren
        depth = 0
        pattern_end = -1
        for i in range(first_paren, len(args_section)):
            if args_section[i] == '(':
                depth += 1
            elif args_section[i] == ')':
                depth -= 1
                if depth == 0:
                    pattern_end = i
                    break

        if pattern_end == -1:
            continue

        ocaml_pattern = args_section[first_paren + 1:pattern_end]

        # Find the input string (quoted string after the pattern)
        remaining = args_section[pattern_end + 1:]
        input_match = re.search(r'"([^"]*)"', remaining)
        if not input_match:
            continue
        input_str = input_match.group(1)

        # Find the position (number on its own line or after whitespace)
        pos_match = re.search(r'\n\s*(\d+)\s*', args_section)
        if not pos_match:
            # Try another pattern - maybe position is on same line as input
            pos_match = re.search(r'\s+(\d+)\s+', args_section)
        if not pos_match:
            continue
        position = pos_match.group(1)

        # Get flags
        flags = []
        if '~multiline:true' in args_section:
            flags.append('m')
        if '~ignoreCase:true' in args_section:
            flags.append('i')
        if '~dotAll:true' in args_section:
            flags.append('s')
        flags_str = ''.join(flags)

        # Convert pattern
        pattern = ocaml_pattern_to_regex(ocaml_pattern)

        # Build regex literal
        regex_literal = f"/{pattern}/{flags_str}" if flags_str else f"/{pattern}/"

        # Determine if match or no-match
        matches = 'No match' not in expect_block

        # Escape for JS
        escaped_input = input_str.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
        escaped_pattern = pattern.replace('\\', '\\\\')

        # Build message
        if matches:
            msg = f"Expected /{escaped_pattern}/ to match '{escaped_input}'"
        else:
            msg = f"Expected /{escaped_pattern}/ NOT to match '{escaped_input}'"

        if position != '0':
            msg += f" (at position {position})"

        # Print assertion
        if matches:
            print(f'assert({regex_literal}.test("{escaped_input}"), "{msg}");')
        else:
            print(f'assert(!{regex_literal}.test("{escaped_input}"), "{msg}");')

        print()


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 convert_tests.py <input.ml file>", file=sys.stderr)
        sys.exit(1)

    input_path = sys.argv[1]
    convert_test_file(input_path)


if __name__ == '__main__':
    main()
