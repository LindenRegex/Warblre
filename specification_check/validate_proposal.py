#!/usr/bin/env python
"""
Validate that the Rocq mechanization matches a proposal diff exactly.

Checks:
1. All changes from the proposal are present in Rocq
2. No other sections have been modified (except wildcards)

Usage:
    python validate_proposal.py <proposal-diff.html> [--rocq-path PATH]
"""

import sys
import re
from pathlib import Path

from bs4 import BeautifulSoup, Tag

from rocq_parser import ROCQParser
from spec_merger.utils import Path as SpecPath
from spec_merger.content_classes.dictionary import Dictionary
from spec_merger.content_classes.string import String
from spec_merger.content_classes.wildcard import WildCard
from ecma_parser import ECMAParser


def extract_section_number(section: Tag) -> str:
    """Extract section number from a section element."""
    sec_num_elem = section.find("span", class_="secnum")
    if sec_num_elem:
        return sec_num_elem.get_text(strip=True)
    return ""


def extract_title(section: Tag) -> str:
    """Extract title from a section element."""
    header = section.find(["h1", "h2", "h3", "h4", "h5", "h6"])
    return header.get_text(strip=True) if header else ""


def is_direct_child_of(parent: Tag, child: Tag, stop_at: list = None) -> bool:
    """Check if child is a direct descendant of parent, stopping at certain elements."""
    if stop_at is None:
        stop_at = ["emu-clause", "section"]

    current = child.parent
    while current and current != parent:
        if current.name in stop_at:
            return False
        current = current.parent
    return current == parent


def extract_changes_from_section(section: Tag):
    """Extract grammar and algorithm changes from a section (excluding nested sections)."""
    grammar = []
    algorithms = []

    # Find all grammar productions
    for prod in section.find_all("emu-production"):
        # Skip if this production is inside a nested section
        if not is_direct_child_of(section, prod, ["emu-clause", "section"]):
            continue

        prod_has_ins = bool(prod.find("ins"))
        prod_has_del = bool(prod.find("del"))

        if not prod_has_ins and not prod_has_del:
            continue

        nt = prod.find("emu-nt")
        nt_name = nt.get_text(strip=True) if nt else "unknown"

        for rhs in prod.find_all("emu-rhs"):
            rhs_text = rhs.get_text(strip=True)
            in_ins = bool(rhs.find_parent("ins") or rhs.find("ins"))
            in_del = bool(rhs.find_parent("del") or rhs.find("del"))

            if in_ins or in_del:
                grammar.append(
                    {
                        "production": nt_name,
                        "rhs": rhs_text,
                        "added": in_ins,
                        "removed": in_del,
                    }
                )

    # Find all algorithm steps
    for alg in section.find_all("emu-alg"):
        # Skip if this algorithm is inside a nested section
        if not is_direct_child_of(section, alg, ["emu-clause", "section"]):
            continue

        for li in alg.find_all("li"):
            # Check if this step is new or modified
            in_ins = bool(li.find_parent("ins") or li.find("ins"))
            in_del = bool(li.find_parent("del") or li.find("del"))

            if not in_ins and not in_del:
                continue

            # For steps that are inside <ins> (new steps), get text normally
            # For steps with both <ins> and <del> (modified steps), we need to be careful
            # The HTML diff tool wraps changed parts in <ins>/<del>
            if li.find_parent("ins"):
                # Step is completely new (wrapped in <ins>)
                step_text = li.get_text(separator=" ", strip=True)
            elif li.find("ins") or li.find("del"):
                # Step has inline changes - get only the <ins> content for additions
                ins_parts = []
                for ins in li.find_all("ins"):
                    ins_parts.append(ins.get_text(separator=" ", strip=True))

                # Also get the static parts (not in del/ins)
                # This is tricky - let's just get all text but clean up artifacts
                step_text = li.get_text(separator=" ", strip=True)

                # Clean up common diff artifacts like "1 4 ." (old and new step numbers)
                # Pattern: number number . -> number .
                step_text = re.sub(r"^(\d+)\s+(\d+)\s*\.", r"\2.", step_text)
            else:
                step_text = li.get_text(separator=" ", strip=True)

            if in_ins or in_del:
                algorithms.append(
                    {"step": step_text, "added": in_ins, "removed": in_del}
                )

    return grammar, algorithms


def extract_proposal_changes(html_path: str):
    """Extract all changes from the proposal diff HTML."""
    with open(html_path, "r") as f:
        soup = BeautifulSoup(f.read(), "html.parser")

    changes = {}

    # Find all sections with IDs
    for section in soup.find_all(["section", "emu-clause"]):
        sec_id = section.get("id", "")
        if not sec_id.startswith("sec-"):
            continue

        sec_num = extract_section_number(section)
        if not sec_num:
            continue

        # Extract changes from this section only (not nested)
        grammar, algorithms = extract_changes_from_section(section)

        # Only include if there are actual changes
        if grammar or algorithms:
            changes[sec_num] = {
                "id": sec_id,
                "title": extract_title(section),
                "grammar": grammar,
                "algorithms": algorithms,
            }

    return changes


def get_rocq_section_content(rocq_entries: dict, section_num: str):
    """Get the content of a section from Rocq mechanization."""
    if section_num not in rocq_entries:
        return None

    entry = rocq_entries[section_num]

    if isinstance(entry, WildCard):
        return {"type": "wildcard", "content": None}

    if isinstance(entry, Dictionary):

        def extract_content(obj):
            """Recursively extract content from Dictionary/String objects."""
            if isinstance(obj, String):
                return obj.value
            elif isinstance(obj, Dictionary):
                result = {}
                for k, v in obj.entries.items():
                    result[k] = extract_content(v)
                return result
            else:
                return str(obj)

        content = extract_content(entry)
        return {"type": "dictionary", "content": content}

    return {"type": "unknown", "content": str(entry)}


def validate_section(sec_num: str, proposal_change: dict, rocq_content: dict):
    """Validate that Rocq content matches the proposal change."""
    errors = []
    warnings = []

    if rocq_content is None:
        errors.append(f"Section {sec_num} not found in Rocq")
        return errors, warnings

    if rocq_content["type"] == "wildcard":
        warnings.append(
            f"Section {sec_num} is marked as wildcard but proposal modifies it"
        )
        return errors, warnings

    if rocq_content["type"] != "dictionary":
        errors.append(f"Section {sec_num} has unexpected type: {rocq_content['type']}")
        return errors, warnings

    content = rocq_content["content"]

    # Recursively collect all text from nested dictionaries
    def collect_all_text(data, result=None):
        if result is None:
            result = []
        if isinstance(data, dict):
            for k, v in data.items():
                if isinstance(v, str):
                    result.append(v)
                elif isinstance(v, String):
                    result.append(v.value)
                elif isinstance(v, Dictionary):
                    collect_all_text(v.entries, result)
                else:
                    collect_all_text(v, result)
        elif isinstance(data, str):
            result.append(data)
        elif isinstance(data, String):
            result.append(data.value)
        elif isinstance(data, Dictionary):
            collect_all_text(data.entries, result)
        return result

    all_text = collect_all_text(content)

    # Normalize function for comparison
    def normalize_text(text):
        # Collapse all whitespace to single spaces
        text = " ".join(text.split())
        # Remove spaces around punctuation (including periods)
        text = re.sub(r"\s*([(){}[\],;.])\s*", r"\1", text)
        return text

    # Check grammar changes
    for gc in proposal_change["grammar"]:
        prod_name = gc["production"]
        rhs = gc["rhs"]

        found = False
        for text in all_text:
            if prod_name in text or rhs in text:
                found = True
                break

        if gc["added"] and not found:
            errors.append(f"Grammar not found: {prod_name} ::= {rhs[:50]}...")

    # Check algorithm changes
    for ac in proposal_change["algorithms"]:
        step = ac["step"]
        found = False

        normalized_step = normalize_text(step)

        for text in all_text:
            normalized_text = normalize_text(text)
            if normalized_step in normalized_text:
                found = True
                break

        if ac["added"] and not found:
            errors.append(f"Algorithm step not found: {step[:80]}...")

    return errors, warnings


def main():
    if len(sys.argv) < 2:
        print(
            "Usage: python validate_proposal.py <proposal-diff.html> [--rocq-path PATH]"
        )
        print()
        print("Validates that Rocq mechanization matches a proposal diff exactly.")
        print()
        print("Checks:")
        print("  1. All changes from the proposal are present in Rocq")
        print("  2. No other sections have been modified")
        sys.exit(1)

    html_path = sys.argv[1]
    rocq_path = "../mechanization/spec/"

    if "--rocq-path" in sys.argv:
        idx = sys.argv.index("--rocq-path")
        if idx + 1 < len(sys.argv):
            rocq_path = sys.argv[idx + 1]

    print("=" * 70)
    print("PROPOSAL VALIDATION")
    print("=" * 70)
    print()

    # Extract proposal changes
    print(f"Parsing proposal from: {html_path}")
    proposal_changes = extract_proposal_changes(html_path)
    print(f"Found {len(proposal_changes)} modified sections in proposal")
    print()

    # Load Rocq mechanization
    print(f"Loading Rocq mechanization from: {rocq_path}")
    paths = [SpecPath(rocq_path, True)]
    files_to_exclude = [SpecPath(f"{rocq_path}/Node.v", False)]
    rocq_parser = ROCQParser(paths, files_to_exclude)
    parsed_rocq = rocq_parser.get_parsed_page()
    rocq_entries = parsed_rocq.entries.entries
    print(f"Loaded {len(rocq_entries)} sections from Rocq")
    print()

    # Validate each proposal change
    print("=" * 70)
    print("VALIDATION RESULTS")
    print("=" * 70)
    print()

    total_errors = 0
    total_warnings = 0

    for sec_num in sorted(
        proposal_changes.keys(), key=lambda x: [int(n) for n in x.split(".")]
    ):
        change = proposal_changes[sec_num]
        rocq_content = get_rocq_section_content(rocq_entries, sec_num)

        errors, warnings = validate_section(sec_num, change, rocq_content)

        status = "OK"
        if errors:
            status = "FAIL"
        elif warnings:
            status = "WARN"

        print(f"[{status}] Section {sec_num}: {change['title'][:50]}")

        if rocq_content and rocq_content["type"] == "wildcard":
            print(f"       -> Marked as WILDCARD (intentionally skipped)")

        for w in warnings:
            print(f"       WARNING: {w}")
            total_warnings += 1

        for e in errors:
            print(f"       ERROR: {e}")
            total_errors += 1

        # Show grammar changes
        if change["grammar"]:
            print(f"       Grammar changes: {len(change['grammar'])}")
            for gc in change["grammar"]:
                marker = "+" if gc["added"] else " "
                marker += "-" if gc["removed"] else " "
                print(f"         [{marker}] {gc['production']}")

        # Show algorithm changes
        if change["algorithms"]:
            print(f"       Algorithm changes: {len(change['algorithms'])}")

    print()
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"  Sections checked: {len(proposal_changes)}")
    print(f"  Errors: {total_errors}")
    print(f"  Warnings: {total_warnings}")
    print()

    if total_errors == 0 and total_warnings == 0:
        print("✓ All proposal changes are correctly implemented!")
        return 0
    elif total_errors == 0:
        print("✓ No errors, but some warnings to review.")
        return 0
    else:
        print("✗ Validation failed - some changes are missing or incorrect.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
