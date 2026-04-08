#!/usr/bin/env python3
"""
Convert regex literals to new RegExp() constructor calls.
This allows ES2025 regex syntax to be parsed by older JavaScript engines.

Example:
  /(?i:ab)/         → new RegExp("(?i:ab)")
  /(?i:ab)/gi       → new RegExp("(?i:ab)", "gi")
  /\d+/             → new RegExp("\\d+")
  /test\/path/      → new RegExp("test/path")
"""

import re
import sys
import os
import shutil


def escape_for_string(pattern):
    """Escape a regex pattern to be used inside a JavaScript string."""
    # Escape backslashes first (double them)
    result = pattern.replace("\\", "\\\\")
    # Escape double quotes
    result = result.replace('"', '\\"')
    return result


def convert_regex_literal(match):
    """Convert a regex literal to new RegExp() constructor."""
    full_match = match.group(0)
    pattern = match.group(1)
    flags = match.group(2) if match.group(2) else ""

    # Escape the pattern for use in a string
    escaped_pattern = escape_for_string(pattern)

    # Build the replacement
    if flags:
        return f'new RegExp("{escaped_pattern}", "{flags}")'
    else:
        return f'new RegExp("{escaped_pattern}")'


def convert_line(line):
    """Convert all regex literals in a line to new RegExp() calls."""
    # Regex to match regex literals: /pattern/flags
    # This is a simplified parser - handles most common cases
    # Pattern: /.../ where ... doesn't contain unescaped /
    result = []
    i = 0
    while i < len(line):
        if line[i] == "/":
            # Check if this is a comment
            if i + 1 < len(line) and line[i + 1] == "/":
                # Single-line comment, copy rest of line
                result.append(line[i:])
                break
            elif i + 1 < len(line) and line[i + 1] == "*":
                # Multi-line comment start
                end = line.find("*/", i + 2)
                if end == -1:
                    result.append(line[i:])
                    break
                else:
                    result.append(line[i : end + 2])
                    i = end + 2
                    continue

            # This might be a regex literal
            # Find the end of the pattern (unescaped /)
            j = i + 1
            escaped = False
            in_class = False
            pattern_start = j

            while j < len(line):
                if escaped:
                    escaped = False
                    j += 1
                    continue

                if line[j] == "\\":
                    escaped = True
                    j += 1
                    continue

                if line[j] == "[" and not in_class:
                    in_class = True
                    j += 1
                    continue

                if line[j] == "]" and in_class:
                    in_class = False
                    j += 1
                    continue

                if line[j] == "/" and not in_class:
                    # End of pattern
                    pattern = line[pattern_start:j]

                    # Parse flags
                    k = j + 1
                    flags = ""
                    while k < len(line) and line[k] in "gimsuvy":
                        flags += line[k]
                        k += 1

                    # Convert to new RegExp()
                    escaped_pattern = escape_for_string(pattern)
                    if flags:
                        result.append(f'new RegExp("{escaped_pattern}", "{flags}")')
                    else:
                        result.append(f'new RegExp("{escaped_pattern}")')

                    i = k
                    break

                j += 1
            else:
                # Didn't find end of regex, treat as division operator
                result.append(line[i])
                i += 1
        else:
            result.append(line[i])
            i += 1

    return "".join(result)


def convert_file(input_path, output_path):
    """Convert a single JavaScript file."""
    print(f"Converting: {input_path}")

    with open(input_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Process line by line
    lines = content.split("\n")
    converted_lines = []
    in_multiline_comment = False

    for line in lines:
        # Simple multiline comment tracking
        if in_multiline_comment:
            converted_lines.append(line)
            if "*/" in line:
                in_multiline_comment = False
            continue

        if "/*" in line and "*/" not in line:
            in_multiline_comment = True

        converted_line = convert_line(line)
        converted_lines.append(converted_line)

    converted_content = "\n".join(converted_lines)

    # Write output
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(converted_content)


def main():
    if len(sys.argv) < 3:
        print("Usage: python convert-regex-literals.py <input-dir> <output-dir>")
        print(
            "Example: python convert-regex-literals.py test262/test/built-ins/RegExp/regexp-modifiers converted-tests/"
        )
        sys.exit(1)

    input_dir = sys.argv[1]
    output_dir = sys.argv[2]

    if not os.path.exists(input_dir):
        print(f"Error: Input directory does not exist: {input_dir}")
        sys.exit(1)

    # Find all .js files in input directory
    js_files = []
    for root, dirs, files in os.walk(input_dir):
        for file in files:
            if file.endswith(".js"):
                js_files.append(os.path.join(root, file))

    print(f"Found {len(js_files)} JavaScript files to convert")
    print(f"Input directory:  {input_dir}")
    print(f"Output directory: {output_dir}")
    print()

    converted_count = 0
    for input_path in js_files:
        # Compute relative path
        rel_path = os.path.relpath(input_path, input_dir)
        output_path = os.path.join(output_dir, rel_path)

        try:
            convert_file(input_path, output_path)
            converted_count += 1
        except Exception as e:
            print(f"Error converting {input_path}: {e}")

    print()
    print(f"Successfully converted {converted_count} files")
    print(f"Output written to: {output_dir}")


if __name__ == "__main__":
    main()
