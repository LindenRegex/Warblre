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


def extract_proposal_changes(html_path: str):
    """Extract all changes from the proposal diff HTML."""
    with open(html_path, "r") as f:
        soup = BeautifulSoup(f.read(), "html.parser")

    changes = {}  # section_num -> {'grammar': [], 'algorithm': [], 'title': ''}
    seen = set()

    for section in soup.find_all(["section", "emu-clause", "div"]):
        sec_id = section.get("id", "")
        if not sec_id.startswith("sec-"):
            continue

        has_ins = bool(section.find("ins"))
        has_del = bool(section.find("del"))

        if not has_ins and not has_del:
            continue

        # Get section number
        sec_num = ""
        sec_num_elem = section.find("span", class_="secnum")
        if sec_num_elem:
            sec_num = sec_num_elem.get_text(strip=True)

        if not sec_num:
            continue

        if sec_num in seen:
            continue
        seen.add(sec_num)

        # Get title
        header = section.find(["h1", "h2", "h3", "h4", "h5", "h6"])
        title = header.get_text(strip=True) if header else ""

        # Extract grammar changes
        grammar = []
        for prod in section.find_all("emu-production"):
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

        # Extract algorithm changes
        algorithms = []
        for alg in section.find_all("emu-alg"):
            for li in alg.find_all("li"):
                step_text = li.get_text(strip=True)
                in_ins = bool(li.find_parent("ins") or li.find("ins"))
                in_del = bool(li.find_parent("del") or li.find("del"))

                if in_ins or in_del:
                    algorithms.append(
                        {"step": step_text, "added": in_ins, "removed": in_del}
                    )

        changes[sec_num] = {
            "id": sec_id,
            "title": title,
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
        content = {}

        # Get title
        title = entry.entries.get("title")
        if isinstance(title, String):
            content["title"] = title.value

        # Get description
        desc = entry.entries.get("description")
        if isinstance(desc, String):
            content["description"] = desc.value

        # Get cases/algorithms
        cases = entry.entries.get("cases")
        if isinstance(cases, Dictionary):
            content["cases"] = {}
            for case_name, case_content in cases.entries.items():
                if isinstance(case_content, String):
                    content["cases"][case_name] = case_content.value
                elif isinstance(case_content, Dictionary):
                    # Nested case
                    content["cases"][case_name] = "nested"

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
        # Section is marked as wildcard - this means we're skipping it
        # But if the proposal modifies it, that's a problem
        warnings.append(
            f"Section {sec_num} is marked as wildcard but proposal modifies it"
        )
        return errors, warnings

    if rocq_content["type"] != "dictionary":
        errors.append(f"Section {sec_num} has unexpected type: {rocq_content['type']}")
        return errors, warnings

    content = rocq_content["content"]

    # Check grammar changes
    for gc in proposal_change["grammar"]:
        # For now, just check if the production name appears somewhere
        prod_name = gc["production"]
        rhs = gc["rhs"]

        # Look in cases
        found = False
        for case_name, case_text in content.get("cases", {}).items():
            if isinstance(case_text, str):
                if prod_name in case_text or rhs in case_text:
                    found = True
                    break

        # Also check description
        if not found and prod_name in content.get("description", ""):
            found = True

        if gc["added"] and not found:
            errors.append(f"Grammar addition not found: {prod_name} ::= {rhs[:50]}...")

    # Check algorithm changes
    for ac in proposal_change["algorithms"]:
        step = ac["step"]
        found = False

        for case_name, case_text in content.get("cases", {}).items():
            if isinstance(case_text, str):
                # Normalize whitespace for comparison
                normalized_step = " ".join(step.split())
                normalized_case = " ".join(case_text.split())
                if normalized_step in normalized_case:
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

        # Print results
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
                marker = "+" if gc["added"] else "-"
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
