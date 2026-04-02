#!/usr/bin/env python
"""
Apply a proposal diff to validate the Rocq mechanization matches.

Usage:
    python apply_proposal.py <proposal-diff.html> [--rocq-path PATH]
"""

import sys
import re
from bs4 import BeautifulSoup, Tag

from rocq_parser import ROCQParser
from spec_merger.utils import Path as SpecPath
from spec_merger.content_classes.dictionary import Dictionary
from spec_merger.content_classes.string import String
from spec_merger.content_classes.wildcard import WildCard


def is_direct_child(parent: Tag, child: Tag, stop_at=None) -> bool:
    """Check if child is a direct descendant of parent, stopping at certain elements."""
    if stop_at is None:
        stop_at = ["emu-clause", "section"]
    current = child.parent
    while current and current != parent:
        if current.name in stop_at:
            return False
        current = current.parent
    return current == parent


def extract_proposal_changes(html_path: str):
    """Extract all changes from the proposal diff HTML."""
    with open(html_path, "r") as f:
        soup = BeautifulSoup(f.read(), "html.parser")

    changes = {}

    for section in soup.find_all(["section", "emu-clause"]):
        sec_id = section.get("id", "")
        if not sec_id.startswith("sec-"):
            continue

        # Get section number
        sec_num = ""
        sec_num_elem = section.find("span", class_="secnum")
        if sec_num_elem:
            sec_num = sec_num_elem.get_text(strip=True)

        if not sec_num:
            continue

        # Extract grammar changes (direct children only)
        grammar = []
        for prod in section.find_all("emu-production"):
            if not is_direct_child(section, prod):
                continue

            has_ins = bool(prod.find("ins"))
            has_del = bool(prod.find("del"))
            if not has_ins and not has_del:
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

        # Extract algorithm changes (direct children only)
        algorithms = []
        for alg in section.find_all("emu-alg"):
            if not is_direct_child(section, alg):
                continue

            for li in alg.find_all("li"):
                in_ins = bool(li.find_parent("ins") or li.find("ins"))
                in_del = bool(li.find_parent("del") or li.find("del"))

                if not in_ins and not in_del:
                    continue

                # Get step text
                step_text = li.get_text(separator=" ", strip=True)

                # Clean up diff artifacts like "1 4 ." -> "4."
                step_text = re.sub(r"^(\d+)\s+(\d+)\s*\.", r"\2.", step_text)

                algorithms.append(
                    {"step": step_text, "added": in_ins, "removed": in_del}
                )

        # Extract early errors (for 22.2.1.1)
        early_errors = []
        if sec_num == "22.2.1.1":
            for li in section.find_all("li"):
                in_ins = bool(li.find_parent("ins") or li.find("ins"))
                if in_ins:
                    text = li.get_text(separator=" ", strip=True)
                    early_errors.append(text)

        if grammar or algorithms or early_errors:
            header = section.find(["h1", "h2", "h3", "h4", "h5", "h6"])
            title = header.get_text(strip=True) if header else ""

            changes[sec_num] = {
                "id": sec_id,
                "title": title,
                "grammar": grammar,
                "algorithms": algorithms,
                "early_errors": early_errors,
            }

    return changes


def normalize_text(text: str) -> str:
    """Normalize text for comparison."""
    text = " ".join(text.split())
    text = re.sub(r"\s*([(){}[\],;.])\s*", r"\1", text)
    return text


def check_grammar_in_rocq(grammar_changes: list, rocq_entry) -> list:
    """Check if grammar changes are present in Rocq."""
    errors = []

    if isinstance(rocq_entry, WildCard):
        for gc in grammar_changes:
            if gc["added"]:
                errors.append(
                    f"Grammar addition not found (wildcard): {gc['production']} ::= {gc['rhs'][:50]}..."
                )
        return errors

    if not isinstance(rocq_entry, Dictionary):
        return errors

    # Collect all text from Rocq entry
    def collect_text(obj, result=None):
        if result is None:
            result = []
        if isinstance(obj, String):
            result.append(obj.value)
        elif isinstance(obj, Dictionary):
            for v in obj.entries.values():
                collect_text(v, result)
        return result

    all_text = collect_text(rocq_entry)
    all_text_normalized = [normalize_text(t) for t in all_text]

    for gc in grammar_changes:
        if not gc["added"]:
            continue  # Skip removals

        rhs = gc["rhs"]
        rhs_normalized = normalize_text(rhs)

        found = False
        for text_norm in all_text_normalized:
            if rhs_normalized in text_norm:
                found = True
                break

        if not found:
            errors.append(f"Grammar not found: {gc['production']} ::= {rhs[:50]}...")

    return errors


def check_algorithms_in_rocq(algorithms: list, rocq_entry) -> list:
    """Check if algorithm changes are present in Rocq."""
    errors = []

    if isinstance(rocq_entry, WildCard):
        for ac in algorithms:
            if ac["added"]:
                errors.append(
                    f"Algorithm step not found (wildcard): {ac['step'][:80]}..."
                )
        return errors

    if not isinstance(rocq_entry, Dictionary):
        return errors

    # Collect all text from Rocq entry
    def collect_text(obj, result=None):
        if result is None:
            result = []
        if isinstance(obj, String):
            result.append(obj.value)
        elif isinstance(obj, Dictionary):
            for v in obj.entries.values():
                collect_text(v, result)
        return result

    all_text = collect_text(rocq_entry)
    all_text_normalized = [normalize_text(t) for t in all_text]

    for ac in algorithms:
        if not ac["added"]:
            continue  # Skip removals

        step = ac["step"]
        step_normalized = normalize_text(step)

        found = False
        for text_norm in all_text_normalized:
            if step_normalized in text_norm:
                found = True
                break

        if not found:
            errors.append(f"Algorithm step not found: {step[:80]}...")

    return errors


def check_early_errors_in_rocq(early_errors: list, rocq_entry) -> list:
    """Check if early error rules are present in Rocq."""
    errors = []

    if isinstance(rocq_entry, WildCard):
        for ee in early_errors:
            errors.append(f"Early error not found (wildcard): {ee[:80]}...")
        return errors

    if not isinstance(rocq_entry, Dictionary):
        return errors

    # Collect all text from Rocq entry
    def collect_text(obj, result=None):
        if result is None:
            result = []
        if isinstance(obj, String):
            result.append(obj.value)
        elif isinstance(obj, Dictionary):
            for v in obj.entries.values():
                collect_text(v, result)
        return result

    all_text = collect_text(rocq_entry)
    all_text_normalized = [normalize_text(t) for t in all_text]

    for ee in early_errors:
        ee_normalized = normalize_text(ee)

        found = False
        for text_norm in all_text_normalized:
            if ee_normalized in text_norm:
                found = True
                break

        if not found:
            errors.append(f"Early error not found: {ee[:80]}...")

    return errors


def main():
    if len(sys.argv) < 2:
        print("Usage: python apply_proposal.py <proposal-diff.html> [--rocq-path PATH]")
        sys.exit(1)

    html_path = sys.argv[1]
    rocq_path = "../mechanization/spec/"

    if "--rocq-path" in sys.argv:
        idx = sys.argv.index("--rocq-path")
        if idx + 1 < len(sys.argv):
            rocq_path = sys.argv[idx + 1]

    print("=" * 70)
    print("APPLY PROPOSAL VALIDATION")
    print("=" * 70)
    print()

    # Extract proposal changes
    print(f"Parsing proposal from: {html_path}")
    changes = extract_proposal_changes(html_path)
    print(f"Found {len(changes)} sections with changes")
    print()

    # Load Rocq
    print(f"Loading Rocq mechanization from: {rocq_path}")
    paths = [SpecPath(rocq_path, True)]
    files_to_exclude = [SpecPath(f"{rocq_path}/Node.v", False)]
    rocq_parser = ROCQParser(paths, files_to_exclude)
    parsed_rocq = rocq_parser.get_parsed_page()
    rocq_entries = parsed_rocq.entries.entries
    print(f"Loaded {len(rocq_entries)} sections from Rocq")
    print()

    # Validate each change
    print("=" * 70)
    print("VALIDATION RESULTS")
    print("=" * 70)
    print()

    total_errors = 0
    total_warnings = 0

    for sec_num in sorted(changes.keys(), key=lambda x: [int(n) for n in x.split(".")]):
        change = changes[sec_num]
        rocq_entry = rocq_entries.get(sec_num)

        errors = []

        # Check grammar
        if change["grammar"]:
            errors.extend(check_grammar_in_rocq(change["grammar"], rocq_entry))

        # Check algorithms
        if change["algorithms"]:
            errors.extend(check_algorithms_in_rocq(change["algorithms"], rocq_entry))

        # Check early errors
        if change["early_errors"]:
            errors.extend(
                check_early_errors_in_rocq(change["early_errors"], rocq_entry)
            )

        if errors:
            print(f"[FAIL] Section {sec_num}: {change['title'][:50]}")
            for e in errors:
                print(f"       ERROR: {e}")
            total_errors += len(errors)
        else:
            print(f"[OK] Section {sec_num}: {change['title'][:50]}")

        # Show summary of changes
        if change["grammar"]:
            added = sum(1 for g in change["grammar"] if g["added"])
            removed = sum(1 for g in change["grammar"] if g["removed"])
            print(f"       Grammar: +{added}/-{removed}")
        if change["algorithms"]:
            added = sum(1 for a in change["algorithms"] if a["added"])
            removed = sum(1 for a in change["algorithms"] if a["removed"])
            print(f"       Algorithms: +{added}/-{removed}")
        if change["early_errors"]:
            print(f"       Early errors: +{len(change['early_errors'])}")

    print()
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"  Sections checked: {len(changes)}")
    print(f"  Total errors: {total_errors}")
    print()

    if total_errors == 0:
        print("✓ All proposal changes are correctly implemented!")
        return 0
    else:
        print("✗ Some proposal changes are missing.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
