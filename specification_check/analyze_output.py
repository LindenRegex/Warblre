#!/usr/bin/env python
import sys

from ecma_parser import ECMAParser
from rocq_parser import ROCQParser
from spec_merger.aligner import Aligner
from spec_merger.utils import Path
from spec_merger.content_classes.dictionary import Dictionary
from spec_merger.content_classes.string import String
from spec_merger.content_classes.misalignment import Misalignment
from spec_merger.content_classes.wildcard import WildCard


def analyze_content(content, indent=0, path=""):
    """Recursively analyze the result tree"""
    prefix = "  " * indent
    content_type = type(content).__name__

    if isinstance(content, Dictionary):
        print(f"{prefix}{path} [DICT] entries={list(content.entries.keys())}")
        for key, value in content.entries.items():
            analyze_content(value, indent + 1, key)
    elif isinstance(content, String):
        preview = (
            content.value[:50].replace("\n", " ")
            if len(content.value) > 50
            else content.value.replace("\n", " ")
        )
        print(
            f"{prefix}{path} [STRING] value='{preview}...' "
            if len(content.value) > 50
            else f"{prefix}{path} [STRING] value='{content.value}'"
        )
    elif isinstance(content, Misalignment):
        print(f"{prefix}{path} [!MISALIGNMENT!]")
        # Misalignment should have left and right trees
        if hasattr(content, "left"):
            print(f"{prefix}  -> LEFT:")
            analyze_content(content.left, indent + 2, "left")
        if hasattr(content, "right"):
            print(f"{prefix}  -> RIGHT:")
            analyze_content(content.right, indent + 2, "right")
        # Try to get any other attributes
        attrs = [
            a
            for a in dir(content)
            if not a.startswith("_")
            and a not in ["count_errors", "render_positions_html", "to_html", "to_text"]
        ]
        if attrs:
            print(f"{prefix}  Other attrs: {attrs}")
            for a in attrs:
                print(f"{prefix}    {a} = {getattr(content, a, 'N/A')}")
    elif isinstance(content, WildCard):
        print(f"{prefix}{path} [WILDCARD]")
    else:
        print(f"{prefix}{path} [UNKNOWN {content_type}] {content}")
        attrs = [a for a in dir(content) if not a.startswith("_")]
        if attrs:
            print(f"{prefix}  attrs: {attrs}")


def find_misalignments(content, path="", results=None):
    """Find all misalignments in the tree"""
    if results is None:
        results = []

    if isinstance(content, Dictionary):
        for key, value in content.entries.items():
            find_misalignments(value, f"{path}/{key}", results)
    elif isinstance(content, Misalignment):
        results.append((path, content))
        # Continue searching deeper
        if hasattr(content, "left"):
            find_misalignments(content.left, f"{path}/left", results)
        if hasattr(content, "right"):
            find_misalignments(content.right, f"{path}/right", results)

    return results


def main():
    paths = [Path("../mechanization/spec/", True)]
    files_to_exclude = [Path("../mechanization/spec/Node.v", False)]
    rocq_parsed_page = ROCQParser(paths, files_to_exclude).get_parsed_page()

    ecma_version = sys.argv[1] if len(sys.argv) > 1 else "14.0"
    ecma_parsed_page = ECMAParser(ecma_version).get_parsed_page()

    result = Aligner().align(rocq_parsed_page.entries, ecma_parsed_page.entries)

    # Count errors
    errors = result.count_errors()
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"ErrorWarningCount: {errors}")
    print(f"Type: {type(errors)}")
    print()

    # Print full tree structure (first 300 lines)
    print("=" * 60)
    print("FULL TREE STRUCTURE")
    print("=" * 60)
    import io
    from contextlib import redirect_stdout

    f = io.StringIO()
    with redirect_stdout(f):
        analyze_content(result)
    output = f.getvalue()
    lines = output.split("\n")
    for line in lines[:300]:
        print(line)
    if len(lines) > 300:
        print(f"... ({len(lines) - 300} more lines)")


if __name__ == "__main__":
    main()
