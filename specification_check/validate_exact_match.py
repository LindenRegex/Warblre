#!/usr/bin/env python
"""
Validate that Rocq mechanization exactly matches the ECMAScript specification.

Checks:
1. All spec sections are present in Rocq (or marked as wildcards)
2. No extra sections in Rocq that aren't in the spec
3. Content matches exactly (algorithms, grammar)

Usage:
    python validate_exact_match.py [ecma-version] [--rocq-path PATH]
"""

import sys
import re
from typing import Dict, List, Tuple

from ecma_parser import ECMAParser
from rocq_parser import ROCQParser
from spec_merger.utils import Path as SpecPath
from spec_merger.content_classes.dictionary import Dictionary
from spec_merger.content_classes.string import String
from spec_merger.content_classes.wildcard import WildCard


def normalize_text(text: str) -> str:
    """Normalize text for comparison."""
    text = " ".join(text.split())
    text = re.sub(r"\s*([(){}[\],;.])\s*", r"\1", text)
    return text


def extract_ecma_sections(ecma_parsed) -> Dict[str, dict]:
    """Extract all sections from ECMA parsed data."""
    sections = {}

    def walk(node, path=""):
        if isinstance(node, Dictionary):
            for key, value in node.entries.items():
                if key and re.match(r"^\d+(\.\d+)*$", key):
                    # This is a section number
                    sections[key] = extract_content(value)
                walk(value, f"{path}/{key}")
        elif isinstance(node, String):
            pass  # Leaf node

    walk(ecma_parsed.entries)
    return sections


def extract_content(node):
    """Extract content from a node."""
    if isinstance(node, WildCard):
        return {"type": "wildcard", "content": None}

    if isinstance(node, Dictionary):
        content = {}

        # Get title
        title = node.entries.get("title")
        if isinstance(title, String):
            content["title"] = title.value

        # Get description
        desc = node.entries.get("description")
        if isinstance(desc, String):
            content["description"] = desc.value

        # Get cases/algorithms
        cases = node.entries.get("cases")
        if isinstance(cases, Dictionary):
            content["cases"] = {}
            for case_name, case_content in cases.entries.items():
                if isinstance(case_content, String):
                    content["cases"][case_name] = case_content.value
                elif isinstance(case_content, Dictionary):
                    content["cases"][case_name] = extract_nested_content(case_content)

        return {"type": "dictionary", "content": content}

    if isinstance(node, String):
        return {"type": "string", "content": node.value}

    return {"type": "unknown", "content": str(node)}


def extract_nested_content(node):
    """Recursively extract nested content."""
    if isinstance(node, String):
        return node.value
    elif isinstance(node, Dictionary):
        result = {}
        for k, v in node.entries.items():
            result[k] = extract_nested_content(v)
        return result
    return str(node)


def collect_all_text(content: dict, result: List[str] = None) -> List[str]:
    """Collect all text strings from nested content."""
    if result is None:
        result = []

    if isinstance(content, dict):
        for k, v in content.items():
            if isinstance(v, str):
                result.append(v)
            else:
                collect_all_text(v, result)
    elif isinstance(content, str):
        result.append(content)
    elif isinstance(content, list):
        for item in content:
            collect_all_text(item, result)

    return result


def compare_content(
    spec_content: dict, rocq_content: dict, section_num: str
) -> Tuple[List[str], List[str]]:
    """Compare spec content with Rocq content."""
    errors = []
    warnings = []

    if rocq_content is None:
        errors.append(f"Section {section_num} not found in Rocq")
        return errors, warnings

    if rocq_content["type"] == "wildcard":
        # Section is marked as wildcard - that's fine for now
        return errors, warnings

    if rocq_content["type"] != "dictionary":
        errors.append(
            f"Section {section_num} has unexpected type: {rocq_content['type']}"
        )
        return errors, warnings

    spec_dict = spec_content.get("content", {})
    rocq_dict = rocq_content.get("content", {})

    # Compare titles
    spec_title = spec_dict.get("title", "")
    rocq_title = rocq_dict.get("title", "")
    if normalize_text(spec_title) != normalize_text(rocq_title):
        warnings.append(
            f"Title mismatch:\n  Spec:  {spec_title}\n  Rocq:  {rocq_title}"
        )

    # Compare cases/algorithms
    spec_cases = spec_dict.get("cases", {})
    rocq_cases = rocq_dict.get("cases", {})

    # Check for missing cases in Rocq
    for case_name in spec_cases:
        if case_name not in rocq_cases:
            errors.append(f"Case '{case_name}' not found in Rocq")

    # Check for extra cases in Rocq
    for case_name in rocq_cases:
        if case_name not in spec_cases:
            warnings.append(f"Extra case '{case_name}' in Rocq (not in spec)")

    # Compare content of matching cases
    for case_name in spec_cases:
        if case_name in rocq_cases:
            spec_case = spec_cases[case_name]
            rocq_case = rocq_cases[case_name]

            if isinstance(spec_case, str) and isinstance(rocq_case, str):
                if normalize_text(spec_case) != normalize_text(rocq_case):
                    # Find first difference
                    spec_norm = normalize_text(spec_case)
                    rocq_norm = normalize_text(rocq_case)
                    if spec_norm != rocq_norm:
                        errors.append(f"Content mismatch in case '{case_name}'")
            elif isinstance(spec_case, dict) and isinstance(rocq_case, dict):
                # Nested comparison
                for sub_name in spec_case:
                    if sub_name not in rocq_case:
                        errors.append(
                            f"Sub-case '{case_name}/{sub_name}' not found in Rocq"
                        )
                    elif isinstance(spec_case[sub_name], str) and isinstance(
                        rocq_case[sub_name], str
                    ):
                        if normalize_text(spec_case[sub_name]) != normalize_text(
                            rocq_case[sub_name]
                        ):
                            errors.append(
                                f"Content mismatch in sub-case '{case_name}/{sub_name}'"
                            )

    return errors, warnings


def wildcard_match(case_name: str, rocq_cases: dict) -> bool:
    """Check if a case matches a wildcard pattern in Rocq."""
    # Check if any Rocq case is a WildCard that might match
    for roc_name, roc_val in rocq_cases.items():
        if isinstance(roc_val, str) and roc_val == "[WILDCARD - not implemented]":
            return True
    return False


def main():
    ecma_version = (
        sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("-") else "14.0"
    )
    rocq_path = "../mechanization/spec/"

    if "--rocq-path" in sys.argv:
        idx = sys.argv.index("--rocq-path")
        if idx + 1 < len(sys.argv):
            rocq_path = sys.argv[idx + 1]

    print("=" * 70)
    print("EXACT SPEC MATCH VALIDATION")
    print("=" * 70)
    print()

    # Load ECMA spec
    print(f"Loading ECMAScript {ecma_version} specification...")
    ecma_parser = ECMAParser(ecma_version)
    ecma_parsed = ecma_parser.get_parsed_page()
    print(f"Loaded spec")
    print()

    # Load Rocq mechanization
    print(f"Loading Rocq mechanization from: {rocq_path}")
    paths = [SpecPath(rocq_path, True)]
    files_to_exclude = [SpecPath(f"{rocq_path}/Node.v", False)]
    rocq_parser = ROCQParser(paths, files_to_exclude)
    rocq_parsed = rocq_parser.get_parsed_page()
    rocq_entries = rocq_parsed.entries.entries
    print(f"Loaded {len(rocq_entries)} sections from Rocq")
    print()

    # Extract spec sections
    spec_sections = {}

    def extract_spec_sections(node, path=""):
        if isinstance(node, Dictionary):
            for key, value in node.entries.items():
                # Check if key looks like a section number
                if re.match(r"^\d+(\.\d+)*$", key):
                    spec_sections[key] = extract_content(value)
                extract_spec_sections(value, f"{path}/{key}")

    extract_spec_sections(ecma_parsed.entries)
    print(f"Found {len(spec_sections)} sections in spec")
    print()

    # Compare sections
    print("=" * 70)
    print("VALIDATION RESULTS")
    print("=" * 70)
    print()

    total_errors = 0
    total_warnings = 0

    # Check all spec sections
    for sec_num in sorted(
        spec_sections.keys(), key=lambda x: [int(n) for n in x.split(".")]
    ):
        spec_content = spec_sections[sec_num]
        rocq_content = get_rocq_section_content(rocq_entries, sec_num)

        errors, warnings = compare_content(spec_content, rocq_content, sec_num)

        if errors or warnings:
            status = "FAIL" if errors else "WARN"
            title = (
                spec_content.get("content", {}).get("title", "")
                if isinstance(spec_content, dict)
                else ""
            )
            print(f"[{status}] Section {sec_num}: {title[:50]}")

            for w in warnings:
                print(f"       WARNING: {w}")
                total_warnings += 1

            for e in errors:
                print(f"       ERROR: {e}")
                total_errors += 1

    # Check for extra sections in Rocq
    print()
    print("Checking for extra sections in Rocq...")
    extra_sections = []
    for sec_num in rocq_entries:
        if sec_num not in spec_sections:
            entry = rocq_entries[sec_num]
            if not isinstance(entry, WildCard):
                extra_sections.append(sec_num)

    if extra_sections:
        print(f"Found {len(extra_sections)} extra sections in Rocq (not in spec):")
        for sec_num in sorted(extra_sections):
            print(f"  - {sec_num}")
        total_warnings += len(extra_sections)
    else:
        print("No extra sections found.")

    print()
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"  Spec sections checked: {len(spec_sections)}")
    print(f"  Rocq sections: {len(rocq_entries)}")
    print(f"  Errors: {total_errors}")
    print(f"  Warnings: {total_warnings}")
    print()

    if total_errors == 0 and total_warnings == 0:
        print("✓ Rocq mechanization exactly matches the specification!")
        return 0
    elif total_errors == 0:
        print("✓ No errors, but some warnings to review.")
        return 0
    else:
        print("✗ Validation failed - mechanization does not exactly match spec.")
        return 1


def get_rocq_section_content(rocq_entries: dict, section_num: str):
    """Get the content of a section from Rocq mechanization."""
    if section_num not in rocq_entries:
        return None

    entry = rocq_entries[section_num]

    if isinstance(entry, WildCard):
        return {"type": "wildcard", "content": None}

    if isinstance(entry, Dictionary):

        def extract_content(obj):
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


if __name__ == "__main__":
    sys.exit(main())
