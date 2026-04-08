#!/usr/bin/env python
import sys

from ecma_parser import ECMAParser
from rocq_parser import ROCQParser
from spec_merger.aligner import Aligner
from spec_merger.utils import Path


def main():
    paths = [Path("../../mechanization/spec/", True)]
    files_to_exclude = [Path("../../mechanization/spec/Node.v", False)]
    rocq_parsed_page = ROCQParser(paths, files_to_exclude).get_parsed_page()

    ecma_version = sys.argv[1] if len(sys.argv) > 1 else "14.0"
    ecma_parsed_page = ECMAParser(ecma_version).get_parsed_page()

    result = Aligner().align(rocq_parsed_page.entries, ecma_parsed_page.entries)
    print(result.to_text(), end="")


if __name__ == "__main__":
    main()
