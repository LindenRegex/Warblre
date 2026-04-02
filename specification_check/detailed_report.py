#!/usr/bin/env python
"""
Detailed comparison report between Rocq mechanization and ECMAScript spec.
"""

import sys
from typing import List, Tuple

from ecma_parser import ECMAParser
from rocq_parser import ROCQParser
from spec_merger.aligner import Aligner
from spec_merger.utils import Path
from spec_merger.content_classes.dictionary import Dictionary
from spec_merger.content_classes.string import String
from spec_merger.content_classes.misalignment import Misalignment
from spec_merger.content_classes.wildcard import WildCard


class Report:
    def __init__(self):
        self.wildcards: List[Tuple[str, str]] = []  # (section, reason)
        self.misalignments: List[
            Tuple[str, str, str]
        ] = []  # (section, left_type, right_type)
        self.detailed_diffs: List[
            Tuple[str, str, str]
        ] = []  # (section, rocq_content, ecma_content)

    def add_wildcard(self, section: str, error_type: str):
        self.wildcards.append((section, error_type))

    def add_misalignment(
        self,
        section: str,
        left_type: str,
        right_type: str,
        left_content=None,
        right_content=None,
    ):
        self.misalignments.append((section, left_type, right_type))
        if left_content and right_content:
            self.detailed_diffs.append((section, left_content, right_content))


def analyze_node(path: str, node, report: Report, depth: int = 0):
    """Recursively analyze the alignment result tree."""
    if isinstance(node, Dictionary):
        for key, value in node.entries.items():
            analyze_node(f"{path}/{key}", value, report, depth + 1)

    elif isinstance(node, Misalignment):
        error_type = str(node.error).replace("ReportErrorType.", "")

        left_type = type(node.left).__name__
        right_type = type(node.right).__name__

        # Wildcard matches are "expected" differences
        if isinstance(node.left, WildCard) or isinstance(node.right, WildCard):
            report.add_wildcard(path, error_type)
        else:
            # Both sides have content but don't match
            left_str = content_preview(node.left)
            right_str = content_preview(node.right)
            report.add_misalignment(path, left_type, right_type, left_str, right_str)

        # Continue analyzing both sides
        analyze_node(f"{path} (rocq)", node.left, report, depth + 1)
        analyze_node(f"{path} (ecma)", node.right, report, depth + 1)


def content_preview(content, max_len: int = 200) -> str:
    """Get a preview of content for display."""
    if isinstance(content, String):
        text = content.value.replace("\n", " ")
        if len(text) > max_len:
            return text[:max_len] + "..."
        return text
    elif isinstance(content, Dictionary):
        return f"[Dict with {len(content.entries)} entries: {list(content.entries.keys())[:5]}...]"
    elif isinstance(content, WildCard):
        return "[WILDCARD]"
    else:
        return f"[{type(content).__name__}]"


def main():
    print("=" * 80)
    print("SPECIFICATION COMPARISON REPORT")
    print("=" * 80)
    print()

    # Parse both sides
    paths = [Path("../mechanization/spec/", True)]
    files_to_exclude = [Path("../mechanization/spec/Node.v", False)]

    print("Parsing Rocq mechanization...")
    rocq_parsed_page = ROCQParser(paths, files_to_exclude).get_parsed_page()

    ecma_version = sys.argv[1] if len(sys.argv) > 1 else "14.0"
    print(f"Parsing ECMAScript {ecma_version} specification...")
    ecma_parsed_page = ECMAParser(ecma_version).get_parsed_page()

    print()
    print("Aligning and comparing...")
    result = Aligner().align(rocq_parsed_page.entries, ecma_parsed_page.entries)

    # Analyze the result
    report = Report()
    analyze_node("root", result, report)

    # Print report
    print()
    print("=" * 80)
    print(
        f"SECTIONS MARKED AS WILDCARDS (skipped in mechanization): {len(report.wildcards)}"
    )
    print("=" * 80)
    for section, error in sorted(report.wildcards):
        print(f"  {section:<50} ({error})")

    print()
    print("=" * 80)
    print(f"ACTUAL MISALIGNMENTS (content differs): {len(report.misalignments)}")
    print("=" * 80)
    if report.misalignments:
        for section, left, right in report.misalignments:
            print(f"\n  {section}")
            print(f"    Rocq:  {left}")
            print(f"    ECMA:  {right}")
    else:
        print("  None - all aligned sections match!")

    print()
    print("=" * 80)
    print("DETAILED DIFFERENCES")
    print("=" * 80)
    if report.detailed_diffs:
        for section, rocq, ecma in report.detailed_diffs[:10]:  # Show first 10
            print(f"\n  {section}")
            print(f"    ROCQ:  {rocq}")
            print(f"    ECMA:  {ecma}")
        if len(report.detailed_diffs) > 10:
            print(f"\n  ... and {len(report.detailed_diffs) - 10} more")
    else:
        print("  No detailed differences to show (all mismatches are wildcards).")

    print()
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"  Total wildcards (intentionally skipped): {len(report.wildcards)}")
    print(f"  Actual misalignments (need attention):   {len(report.misalignments)}")

    if report.misalignments:
        print()
        print("  WARNING: There are actual content differences that need to be fixed!")
        return 1
    else:
        print()
        print("  OK: All non-wildcard sections are aligned!")
        return 0


if __name__ == "__main__":
    sys.exit(main())
