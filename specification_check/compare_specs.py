#!/usr/bin/env python
"""
Detailed comparison between Rocq mechanization and ECMAScript spec.
Shows exact differences when content doesn't match.
"""

import sys
import difflib
from typing import Optional

from ecma_parser import ECMAParser
from rocq_parser import ROCQParser
from spec_merger.aligner import Aligner
from spec_merger.utils import Path
from spec_merger.content_classes.dictionary import Dictionary
from spec_merger.content_classes.string import String
from spec_merger.content_classes.misalignment import Misalignment
from spec_merger.content_classes.wildcard import WildCard


def show_diff(
    left_text: str, right_text: str, left_label: str = "ROCQ", right_label: str = "ECMA"
):
    """Show a unified diff between two texts."""
    left_lines = left_text.splitlines(keepends=True)
    right_lines = right_text.splitlines(keepends=True)

    # Ensure lines end with newline for proper diff
    if left_lines and not left_lines[-1].endswith("\n"):
        left_lines[-1] += "\n"
    if right_lines and not right_lines[-1].endswith("\n"):
        right_lines[-1] += "\n"

    diff = difflib.unified_diff(
        left_lines, right_lines, fromfile=left_label, tofile=right_label, lineterm=""
    )

    diff_lines = list(diff)
    if diff_lines:
        for line in diff_lines:
            print(line)
    else:
        print("  (no diff output - texts appear identical)")


def get_full_content(content, max_depth: int = 3, current_depth: int = 0) -> str:
    """Get a full representation of content."""
    if isinstance(content, String):
        return content.value
    elif isinstance(content, WildCard):
        return "[WILDCARD - not implemented]"
    elif isinstance(content, Dictionary):
        if current_depth >= max_depth:
            return f"[Dict with keys: {list(content.entries.keys())}]"
        result = []
        for key, value in content.entries.items():
            sub = get_full_content(value, max_depth, current_depth + 1)
            if "\n" in sub:
                result.append(f"{key}:\n  " + sub.replace("\n", "\n  "))
            else:
                result.append(f"{key}: {sub}")
        return "\n".join(result)
    else:
        return str(content)


def analyze_difference(path: str, mis: Misalignment, verbose: bool = False):
    """Analyze and display a single misalignment."""
    left = mis.left
    right = mis.right

    print(f"\n{'=' * 60}")
    print(f"PATH: {path}")
    print(f"ERROR: {mis.error}")
    print(f"{'=' * 60}")

    # Case 1: Wildcard on one side - show what would need to be added
    if isinstance(left, WildCard) or isinstance(right, WildCard):
        if isinstance(left, WildCard):
            print(f"\n[ROCQ: WILDCARD - not implemented]")
            print(
                f"\n[ECMA: {type(right).__name__} - content that needs to be implemented]"
            )
            ecma_content = get_full_content(right)
            print("-" * 40)
            print(ecma_content)
            # Show diff: empty vs ECMA content
            print(f"\n[DIFF: What needs to be added to ROCQ]")
            print("-" * 40)
            show_diff(
                "", ecma_content, left_label="ROCQ (empty)", right_label="ECMA (target)"
            )
        else:
            rocq_content = get_full_content(left)
            print(f"\n[ROCQ: {type(left).__name__}]")
            print("-" * 40)
            print(rocq_content)
            print(f"\n[ECMA: WILDCARD - not in spec]")
            # Show diff: ROCQ content vs empty
            print(f"\n[DIFF: Content in ROCQ but not in ECMA]")
            print("-" * 40)
            show_diff(
                rocq_content, "", left_label="ROCQ (current)", right_label="ECMA (none)"
            )
        return

    # Case 2: Both are Strings - show text diff
    if isinstance(left, String) and isinstance(right, String):
        print(f"\n[ROCQ STRING]")
        print("-" * 40)
        print(left.value)
        print(f"\n[ECMA STRING]")
        print("-" * 40)
        print(right.value)
        print(f"\n[DIFF]")
        print("-" * 40)
        show_diff(left.value, right.value)
        return

    # Case 3: Type mismatch
    if type(left) != type(right):
        print(f"\n[TYPE MISMATCH]")
        print(f"ROCQ:  {type(left).__name__}")
        print(f"ECMA:  {type(right).__name__}")
        print(f"\n[ROCQ CONTENT]")
        print("-" * 40)
        print(get_full_content(left))
        print(f"\n[ECMA CONTENT]")
        print("-" * 40)
        print(get_full_content(right))
        return

    # Case 4: Both are Dictionaries - show key differences
    if isinstance(left, Dictionary) and isinstance(right, Dictionary):
        left_keys = set(left.entries.keys())
        right_keys = set(right.entries.keys())
        only_left = left_keys - right_keys
        only_right = right_keys - left_keys
        common = left_keys & right_keys

        print(f"\n[DICTIONARY COMPARISON]")
        print(f"ROCQ keys:  {sorted(left_keys)}")
        print(f"ECMA keys:  {sorted(right_keys)}")

        if only_left:
            print(f"\nOnly in ROCQ: {sorted(only_left)}")
        if only_right:
            print(f"Only in ECMA: {sorted(only_right)}")

        if verbose:
            for key in sorted(common):
                lval = left.entries[key]
                rval = right.entries[key]
                if type(lval) != type(rval) or (
                    isinstance(lval, String) and lval.value != rval.value
                ):
                    print(f"\n[DIFFERENCE IN KEY: {key}]")
                    print(f"ROCQ:  {get_full_content(lval)}")
                    print(f"ECMA:  {get_full_content(rval)}")
        return

    # Default: just show both
    print(f"\n[ROCQ: {type(left).__name__}]")
    print("-" * 40)
    print(get_full_content(left))
    print(f"\n[ECMA: {type(right).__name__}]")
    print("-" * 40)
    print(get_full_content(right))


def walk_tree(node, path: str = "root", callback=None):
    """Walk the tree and call callback on each node."""
    if callback:
        callback(path, node)

    if isinstance(node, Misalignment):
        walk_tree(node.left, f"{path}/left", callback)
        walk_tree(node.right, f"{path}/right", callback)
    elif isinstance(node, Dictionary):
        for key, value in node.entries.items():
            walk_tree(value, f"{path}/{key}", callback)


def main():
    verbose = "-v" in sys.argv or "--verbose" in sys.argv
    show_wildcards = "-w" in sys.argv or "--wildcards" in sys.argv

    # Remove flags from args
    args = [a for a in sys.argv[1:] if not a.startswith("-")]

    print("=" * 60)
    print("SPECIFICATION COMPARISON")
    print("=" * 60)
    if verbose:
        print("Mode: Verbose (show all details)")
    if show_wildcards:
        print("Mode: Show wildcards (sections not yet implemented)")
    print()

    # Parse
    paths = [Path("../mechanization/spec/", True)]
    files_to_exclude = [Path("../mechanization/spec/Node.v", False)]

    print("Parsing Rocq mechanization...")
    rocq = ROCQParser(paths, files_to_exclude).get_parsed_page()

    ecma_version = args[0] if args else "14.0"
    print(f"Parsing ECMAScript {ecma_version} specification...")
    ecma = ECMAParser(ecma_version).get_parsed_page()

    print("Aligning...")
    result = Aligner().align(rocq.entries, ecma.entries)
    print()

    # Collect statistics
    stats = {
        "total_misalignments": 0,
        "wildcards": 0,
        "string_diffs": 0,
        "type_mismatches": 0,
        "dict_diffs": 0,
        "other": 0,
    }

    misalignments = []

    def collect_stats(path, node):
        if isinstance(node, Misalignment):
            stats["total_misalignments"] += 1
            left, right = node.left, node.right

            if isinstance(left, WildCard) or isinstance(right, WildCard):
                stats["wildcards"] += 1
                if show_wildcards:
                    misalignments.append((path, node))
            elif isinstance(left, String) and isinstance(right, String):
                stats["string_diffs"] += 1
                misalignments.append((path, node))
            elif type(left) != type(right):
                stats["type_mismatches"] += 1
                misalignments.append((path, node))
            elif isinstance(left, Dictionary):
                stats["dict_diffs"] += 1
                misalignments.append((path, node))
            else:
                stats["other"] += 1
                misalignments.append((path, node))

    walk_tree(result, callback=collect_stats)

    # Print summary
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Total nodes analyzed:           {stats['total_misalignments']}")
    print(f"  Wildcards (not implemented):  {stats['wildcards']}")
    print(f"  String differences:           {stats['string_diffs']}")
    print(f"  Type mismatches:              {stats['type_mismatches']}")
    print(f"  Dictionary differences:       {stats['dict_diffs']}")
    print(f"  Other:                        {stats['other']}")
    print()

    actual_errors = (
        stats["string_diffs"]
        + stats["type_mismatches"]
        + stats["dict_diffs"]
        + stats["other"]
    )
    print(f"Actual content differences: {actual_errors}")

    if actual_errors == 0:
        print("\n✓ All implemented sections match the spec!")
        if not show_wildcards:
            print("  (Use -w flag to see what's not yet implemented)")
            return 0

    # Show detailed differences
    print()
    print("=" * 60)
    print("DETAILED DIFFERENCES")
    print("=" * 60)

    for path, mis in misalignments:
        analyze_difference(path, mis, verbose=verbose)

    return 1 if actual_errors > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
