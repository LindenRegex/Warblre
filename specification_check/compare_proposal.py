#!/usr/bin/env python
"""
Compare a proposal diff (from ecma262-compare) against the Rocq mechanization.
Shows what needs to be implemented from the proposal.
"""

import sys
import re
from pathlib import Path

from bs4 import BeautifulSoup, Tag

from rocq_parser import ROCQParser
from spec_merger.utils import Path as SpecPath
from spec_merger.aligner import Aligner
from spec_merger.content_classes.dictionary import Dictionary
from spec_merger.content_classes.string import String
from spec_merger.content_classes.wildcard import WildCard
from spec_merger.content_classes.misalignment import Misalignment


def parse_compare_html(html_path: str):
    """Parse the ecma262-compare HTML and extract changes."""
    with open(html_path, "r") as f:
        soup = BeautifulSoup(f.read(), "html.parser")

    changes = []
    seen_sections = set()  # Avoid duplicates

    # Find all sections that have changes
    for section in soup.find_all(["section", "emu-clause", "div"]):
        sec_id = section.get("id", "")
        if not sec_id or not sec_id.startswith("sec-"):
            continue

        # Check if this section has changes
        has_ins = bool(section.find("ins"))
        has_del = bool(section.find("del"))

        if not has_ins and not has_del:
            continue

        # Extract section number and title
        header = section.find(["h1", "h2", "h3", "h4", "h5", "h6"])
        title = header.get_text(strip=True) if header else ""

        # Extract the section number (e.g., 22.2.2.7.4)
        sec_num = ""
        sec_num_elem = section.find("span", class_="secnum")
        if sec_num_elem:
            sec_num = sec_num_elem.get_text(strip=True)
        else:
            match = re.match(r"(\d+(?:\.\d+)*)", title)
            if match:
                sec_num = match.group(1)

        # Create unique key
        key = f"{sec_num}:{sec_id}"
        if key in seen_sections:
            continue
        seen_sections.add(key)

        # Determine diff type
        if has_ins and has_del:
            diff_type = "modified"
        elif has_ins:
            diff_type = "added"
        else:
            diff_type = "removed"

        # Extract changes
        grammar_changes = extract_grammar_changes(section)
        algo_changes = extract_algorithm_changes(section)

        # Extract the algorithm/content
        content = extract_section_content(section)

        changes.append(
            {
                "id": sec_id,
                "section": sec_num,
                "title": title,
                "type": diff_type,
                "content": content,
                "grammar_changes": grammar_changes,
                "algo_changes": algo_changes,
            }
        )

    return changes


def extract_grammar_changes(section):
    """Extract grammar production changes from a section."""
    changes = []

    for prod in section.find_all("emu-production"):
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

            if in_ins:
                changes.append(
                    {"production": nt_name, "rhs": rhs_text, "change": "added"}
                )
            elif in_del:
                changes.append(
                    {"production": nt_name, "rhs": rhs_text, "change": "removed"}
                )

    return changes


def extract_algorithm_changes(section):
    """Extract algorithm step changes from a section."""
    changes = []

    for alg in section.find_all("emu-alg"):
        for li in alg.find_all("li"):
            step_text = li.get_text(strip=True)
            in_ins = bool(li.find_parent("ins") or li.find("ins"))
            in_del = bool(li.find_parent("del") or li.find("del"))

            if in_ins:
                changes.append({"step": step_text, "change": "added"})
            elif in_del:
                changes.append({"step": step_text, "change": "removed"})

    return changes


def extract_section_content(section: Tag) -> str:
    """Extract the algorithm/content text from a section."""
    content_parts = []

    # Get description from first paragraph
    first_p = section.find("p", recursive=False)
    if first_p:
        desc = first_p.get_text(strip=True)
        if desc:
            content_parts.append(f"Description: {desc}")

    # Get algorithm steps from emu-alg
    for alg in section.find_all("emu-alg", recursive=False):
        ol = alg.find("ol")
        if ol:
            steps = []
            for li in ol.find_all("li", recursive=False):
                step_text = li.get_text(strip=True)
                if step_text:
                    steps.append(step_text)
            if steps:
                content_parts.append("Algorithm:")
                for i, step in enumerate(steps, 1):
                    content_parts.append(f"  {i}. {step}")

    # Get grammar productions from emu-grammar
    for grammar in section.find_all("emu-grammar", recursive=False):
        prods = grammar.find_all("emu-production")
        if prods:
            content_parts.append("Grammar:")
            for prod in prods:
                nt = prod.find("emu-nt")
                rhs_list = prod.find_all("emu-rhs")
                if nt and rhs_list:
                    lhs = nt.get_text(strip=True)
                    for rhs in rhs_list:
                        rhs_text = rhs.get_text(strip=True)
                        content_parts.append(f"  {lhs} :: {rhs_text}")

    return "\n".join(content_parts)


def find_in_rocq(rocq_entries: dict, section_num: str, section_title: str):
    """Find a section in the Rocq parsed output."""
    # Try to find by section number first
    if section_num in rocq_entries:
        return rocq_entries[section_num]

    # Try to find by looking through entries
    for key, entry in rocq_entries.items():
        if isinstance(entry, Dictionary):
            title = entry.entries.get("title", "")
            if isinstance(title, String):
                if section_num in title.value or section_title in title.value:
                    return entry

    return None


def compare_change_to_rocq(change: dict, rocq_entries: dict) -> dict:
    """Compare a single change to what's in Rocq."""
    section_num = change["section"]
    rocq_entry = find_in_rocq(rocq_entries, section_num, change["title"])

    if rocq_entry is None:
        return {"change": change, "status": "missing", "rocq_content": None}

    if isinstance(rocq_entry, WildCard):
        return {"change": change, "status": "wildcard", "rocq_content": None}

    # If it's a Dictionary, check if it has the right content
    if isinstance(rocq_entry, Dictionary):
        # For now, assume implemented if present
        return {"change": change, "status": "implemented", "rocq_content": rocq_entry}

    return {"change": change, "status": "unknown", "rocq_content": rocq_entry}


def main():
    if len(sys.argv) < 2:
        print(
            "Usage: python compare_proposal.py <path-to-compare-html> [--rocq-path PATH]"
        )
        print()
        print("Example:")
        print("  python compare_proposal.py ~/Downloads/ecma262-compare/index.html")
        sys.exit(1)

    html_path = sys.argv[1]

    # Allow overriding the Rocq path
    rocq_path = "../mechanization/spec/"
    if "--rocq-path" in sys.argv:
        idx = sys.argv.index("--rocq-path")
        if idx + 1 < len(sys.argv):
            rocq_path = sys.argv[idx + 1]

    print("=" * 60)
    print("PROPOSAL COMPARISON TOOL")
    print("=" * 60)
    print()
    print(f"Parsing proposal diff from: {html_path}")

    changes = parse_compare_html(html_path)
    print(f"Found {len(changes)} changed sections")
    print()

    # Filter to RegExp-related sections
    regexp_changes = [
        c
        for c in changes
        if "regexp" in c["title"].lower()
        or c["section"].startswith("22.2")
        or "regexp" in c["id"].lower()
    ]
    print(f"RegExp-related changes: {len(regexp_changes)}")
    print()

    if not regexp_changes:
        print("No RegExp changes found in this proposal.")
        return 0

    print("Parsing Rocq mechanization...")
    paths = [SpecPath(rocq_path, True)]
    files_to_exclude = [SpecPath(f"{rocq_path}/Node.v", False)]
    rocq_parser = ROCQParser(paths, files_to_exclude)
    parsed_rocq = rocq_parser.get_parsed_page()
    rocq_entries = parsed_rocq.entries.entries  # Dictionary -> dict
    print(f"Loaded {len(rocq_entries)} sections from Rocq")
    print()

    print("=" * 60)
    print("COMPARISON RESULTS")
    print("=" * 60)
    print()

    # Categorize
    missing = []
    wildcards = []
    implemented = []

    for change in regexp_changes:
        result = compare_change_to_rocq(change, rocq_entries)
        if result["status"] == "missing":
            missing.append(result)
        elif result["status"] == "wildcard":
            wildcards.append(result)
        elif result["status"] == "implemented":
            implemented.append(result)

    # Report
    print(f"IMPLEMENTED ({len(implemented)}):")
    if implemented:
        for r in implemented:
            c = r["change"]
            print(f"  ✓ {c['section']:<15} {c['title'][:50]}")
    else:
        print("  (none)")
    print()

    print(f"MARKED AS WILDCARD ({len(wildcards)}) - intentionally skipped:")
    if wildcards:
        for r in wildcards:
            c = r["change"]
            print(f"  ○ {c['section']:<15} {c['title'][:50]}")
    else:
        print("  (none)")
    print()

    print(f"MISSING FROM ROCQ ({len(missing)}) - need implementation:")
    if missing:
        for r in missing:
            c = r["change"]
            print(f"  ✗ {c['section']:<15} {c['title'][:50]}")
    else:
        print("  (none)")
    print()

    # Detailed view of missing and wildcards
    if missing or wildcards:
        print("=" * 60)
        print("DETAILED VIEW OF CHANGED SECTIONS")
        print("=" * 60)

        for category, items in [("MISSING", missing), ("WILDCARD", wildcards)]:
            if not items:
                continue

            for r in items:
                c = r["change"]
                print()
                print(f"[{category}] Section {c['section']}: {c['title']}")
                print("-" * 60)

                # Show grammar changes
                if c.get("grammar_changes"):
                    print("\nGRAMMAR CHANGES:")
                    for gc in c["grammar_changes"]:
                        marker = "[+ NEW]" if gc["change"] == "added" else "[- REMOVED]"
                        print(f"  {marker} {gc['production']}")
                        print(f"         :: {gc['rhs']}")

                # Show algorithm changes
                if c.get("algo_changes"):
                    print("\nALGORITHM CHANGES:")
                    for ac in c["algo_changes"]:
                        marker = "[+ NEW]" if ac["change"] == "added" else "[- REMOVED]"
                        print(
                            f"  {marker} {ac['step'][:100]}{'...' if len(ac['step']) > 100 else ''}"
                        )

                # Full content if no structured changes found
                if (
                    not c.get("grammar_changes")
                    and not c.get("algo_changes")
                    and c.get("content")
                ):
                    print("\nCONTENT:")
                    content = c["content"]
                    print(content[:800] if len(content) > 800 else content)
                    if len(content) > 800:
                        print(f"... ({len(content) - 800} more chars)")

    return 0 if not missing else 1


if __name__ == "__main__":
    sys.exit(main())
