import json
import os
import re
from dataclasses import dataclass
from typing import Dict, List, Tuple

from alectryon.literate import Comment, StringView, CoqParser
from spec_merger.aligner_utils import Position
from spec_merger.content_classes.dictionary import Dictionary
from spec_merger.content_classes.string import String
from spec_merger.content_classes.wildcard import WildCard
from spec_merger.utils import ParsedPage, Parser, ParserState, Path


@dataclass(frozen=True)
class RocqLine:
    file_name: str
    line_number: int
    is_end_comment: bool = False
    is_end_file: bool = False


def get_file_name_without_path(path) -> str:
    return path.split("/")[-1]


def add_case(cases: dict[str, Dictionary | WildCard], left_key: str, right_key: str, value: String | WildCard) -> None:
    if cases.get(left_key) is not None:
        if cases.get(left_key) == WildCard(None):
            return
        cases[left_key].entries[right_key] = value
    else:
        cases[left_key] = Dictionary(None, {right_key: value})


@dataclass(frozen=True)
class RocqPosition(Position):
    file_positions: Dict[str, Tuple[int, int]]

    def html_str(self) -> str:
        return ", ".join(
            f"<a download href='file://{file_name}'><b>{get_file_name_without_path(file_name)}</b>: {start} - {end}</a>"
            for file_name, (start, end)
            in self.file_positions.items())

    def __hash__(self):
        return hash(self.html_str())


class ROCQParser(Parser):
    def __init__(self, files: List[Path], to_exclude: List[Path], parser_name: str = "ROCQ",
                 title_regex: str = r"(22\.2(?:\.[0-9]*)*)",
                 spec_regex: str = r"^\(\*(\* )?>?>(.|\n)*?<<\*\)$",
                 directive_regex: str = r"^\(\*(\* )?##(.|\n)*?##\*\)$",
                 case_regex: str = r"([a-zA-Z0-9\[\]]+) ::((?:.|\n)*)",
                 algo_regex: str = r"^(?:(?:(?:(?:[1-9][0-9]*)|[a-z]|[ivxlc]+)\.)|\*) .*$",
                 any_title_regex: str = r"^((?:[0-9]+\.)+[0-9]+)(?: .*?|)$"):
        self.sections_by_number = None

        self.name = parser_name
        self.files = files
        self.to_exclude = to_exclude
        self.title_regex = re.compile(title_regex)
        self.any_title_regex = re.compile(any_title_regex, re.MULTILINE)
        self.spec_regex = re.compile(spec_regex)
        self.directive_regex = re.compile(directive_regex)
        self.case_regex = re.compile(case_regex)
        self.algo_regex = re.compile(algo_regex)

    @staticmethod
    def __get_line_num(string_view: StringView) -> int:
        return string_view.s.count("\n", 0, string_view.beg) + 1

    def __add_file(self, filename: str, files_dic: dict, all_filenames: list):
        if any([filename.startswith(excluded.uri) for excluded in self.to_exclude]):
            return
        with open(filename, "r") as f:
            rocq_file = f.read()
            files_dic[filename] = rocq_file
        all_filenames.append(filename)

    def __get_rocq_code(self) -> Tuple[Dict[str, str], List[str]]:
        files_dic: dict[str, str] = {}
        all_filenames: list[str] = []
        for file in self.files:
            if file.is_dir:
                for root, dirs, files in os.walk(file.uri, topdown=False):
                    for name in files:
                        self.__add_file(os.path.abspath(os.path.join(root, name)), files_dic, all_filenames)
            else:
                self.__add_file(file.uri, files_dic, all_filenames)
        return files_dic, all_filenames


    def __process_lines(self, rocq_code, all_filenames, matcher: re.Pattern) -> list[tuple[str, RocqLine]]:
        comments = []
        for filename in all_filenames:
            file = rocq_code[filename]
            partition = CoqParser(file).partition()
            for field in partition:
                if isinstance(field, Comment) and matcher.match(str(field.v)):
                    start_line_num = ROCQParser.__get_line_num(field.v)
                    for i, line in enumerate(str(field.v).splitlines()):
                        line = ROCQParser.__parse_line(line)
                        if line != "":
                            comments.append((line, RocqLine(filename, start_line_num + i)))
                    # avoid -1 at start, would have made no sense
                    if len(comments) > 0:
                        comments.append(("", RocqLine(filename, -1, True)))
            if len(comments) > 0:
                comments.append(("", RocqLine(filename, -1, False, True)))
        return comments

    @staticmethod
    def __parse_line(comment: str) -> str:
        return (comment.replace("\n", "")
            .replace("(*>>", "").replace("<<*)", "").replace("(** >>", "")
            .replace("(*##", "").replace("##*)", "").replace("(** ##", "")
            .replace("[OMITTED]","").lstrip().rstrip())

    # Completely arbitrary in our case
    @staticmethod
    def __merge_comments(section1: Dictionary, section2: Dictionary) -> Dictionary:
        # None act as the identity
        if section1 is None:
            return section2
        elif section2 is None:
            return section1

        #print("[WARNING] Merge called for ", section1, section2)
        title = section1["title"] if len(section1["title"]) > len(section2["title"]) else section2["title"]
        description_first = section1["description"] if len(section1["description"]) > len(
            section2["description"]) else section2["description"]
        description_second = section1["description"] if len(section1["description"]) <= len(
            section2["description"]) else section2["description"]
        pos: tuple[RocqPosition, RocqPosition] = section1.position, section2.position
        new_files = {}
        old_files = (pos[0].file_positions, pos[1].file_positions)
        for filename in old_files[0].keys() | old_files[1].keys():
            match (filename in old_files[0].keys(), filename in old_files[1].keys()):
                case (True, True):
                    new_files[filename] = (min(old_files[0][filename], old_files[1][filename]),
                                           max(old_files[0][filename], old_files[1][filename]))
                case (False, True):
                    new_files[filename] = old_files[1][filename]
                case (True, False):
                    new_files[filename] = old_files[0][filename]
                case _:
                    raise Exception("This should never happen")
        new_cases = {}
        for case in section1["cases"].entries.keys() | section2["cases"].entries.keys():
            if section1["cases"][case] is not None and section2["cases"][case] is not None:
                section1["cases"][case]: Dictionary[String]
                for key in section1["cases"][case].entries.keys() | section2["cases"][case].entries.keys():
                    if section1["cases"][case][key] is not None:
                        new_cases[case] = section1["cases"][case][key]
                    else:
                        new_cases[case] = section2["cases"][case].entries[key]
            elif section1["cases"][case] is not None:
                new_cases[case] = section1["cases"][case]
            else:
                new_cases[case] = section2["cases"][case]
        return Dictionary(RocqPosition(new_files), {"title": title, "description": description_first + "\n" +
                                                                                  description_second,
                                                   "cases": Dictionary(None, new_cases)})


    def __get_comment_titles(self, comments) -> Dict[str, Dictionary]:
        """
           Gets the indices of the comments that contain the titles of the sections (comments that match the title_regex)
           :return: A dictionary with the title of the section as key and the indices of the comments that contain the
           section as value
        """
        title_indices = {}
        current_block = ""
        last_block_end = 0
        section_to_be_thrown_away = False
        for comment_index, comment in enumerate(comments):
            if res2 := self.any_title_regex.match(comment[0]):
                if current_block != "" and not section_to_be_thrown_away:
                    title_indices[current_block] = ROCQParser.__merge_comments(
                        self.__parse_subsection(comments[last_block_end:comment_index]),
                        title_indices.get(current_block))
                    last_block_end = comment_index
                elif current_block != "" and section_to_be_thrown_away:
                    last_block_end = comment_index
                current_block = res2.group(1)
                section_to_be_thrown_away = self.title_regex.search(str(comment)) is None
        if not section_to_be_thrown_away:
            title_indices[current_block] = self.__parse_subsection(comments[last_block_end:len(comments)])
        return title_indices

    def __parse_title(self, title: str) -> str:

        lines = title.splitlines(keepends=False)
        title = lines[1].lstrip()
        for line in lines[3:-1]:
            title += "\n" + line.lstrip()
        return title + "\n"

    def __parse_subsection(self, comment_lines: List[str]) -> Dictionary:
        title = ""
        description = ""
        parser_state = ParserState.READING_TITLE
        saved_state = ParserState.BEFORE_START
        wildcard_state = ""
        in_case_title = False
        cases: dict[str, Dictionary| WildCard] = {}
        current_case = ""
        current_case_titles = []
        skip_until_end_file = False
        filenames = {}
        case_line_indices = [-1, -1]
        for parsed_comment, rocq_line in comment_lines:
            # We are at the end of a comment
            if rocq_line.is_end_comment or rocq_line.is_end_file:
                match parser_state:
                    case ParserState.BEFORE_START:
                        parser_state = ParserState.READING_TITLE
                    case ParserState.READING_TITLE:
                        if rocq_line.is_end_comment:
                            parser_state = ParserState.READING_DESCRIPTION
                    case ParserState.READING_DESCRIPTION:
                        pass
                    case ParserState.READING_CASES:
                        pass
                    case ParserState.READING_WILDCARD:
                        pass
                if rocq_line.is_end_file:
                    skip_until_end_file = False
                continue
            if skip_until_end_file:
                continue
            # Get file name
            filename = rocq_line.file_name
            # If not already in, add it and add its current line
            if filenames.get(filename) is None:
                filenames[filename] = (rocq_line.line_number, rocq_line.line_number)
            # Otherwise update last line
            else:
                before_indices = filenames[filename]
                added_index = rocq_line.line_number
                new_indices = (min(before_indices[0], added_index), max(before_indices[1], added_index))
                filenames[filename] = new_indices
            if parsed_comment.startswith("WILDCARD"):
                saved_state = parser_state
                parser_state = ParserState.READING_WILDCARD
                wildcard_state = parsed_comment.split(" ", 1)[1]
                if wildcard_state == "PARSING_FILE_END":
                    skip_until_end_file = True
                else:
                    case_wildcarded = json.loads(wildcard_state)
                    if " ::" in case_wildcarded:
                        parts = case_wildcarded.split(" ::")
                        add_case(cases, parts[0], parts[1], WildCard(None))
                    else:
                        cases[case_wildcarded] = WildCard(None)
                continue
            if self.case_regex.match(parsed_comment):
                parser_state = ParserState.READING_CASES
                if current_case != "":
                    case_pos = RocqPosition({rocq_line.file_name: tuple(case_line_indices)})
                    for case_title in current_case_titles:
                        add_case(cases, case_title[0], case_title[1], String(case_pos, current_case))
                    current_case_titles = []
                case_line_indices[0] = rocq_line.line_number
                case_line_indices[1] = rocq_line.line_number
                match = self.case_regex.match(parsed_comment)
                current_case_titles.append([match.group(1), match.group(2)])
                current_case = ""
                in_case_title = True

            else:
                match parser_state:
                    case ParserState.READING_TITLE:
                        if self.algo_regex.match(parsed_comment):
                            # If there is a start of an algorithm, but we are still building title, it means that there
                            # is only one case in the subsection, and therefore we set its title to ""
                            case_line_indices[0] = rocq_line.line_number
                            case_line_indices[1] = rocq_line.line_number
                            parser_state = ParserState.READING_CASES
                            current_case = parsed_comment + "\n"
                            if not current_case_titles:
                                current_case_titles.append(["", ""])
                        else:
                            title += parsed_comment
                            parser_state = ParserState.READING_DESCRIPTION
                    case ParserState.READING_DESCRIPTION:
                        if self.algo_regex.match(parsed_comment):
                            # If there is a start of an algorithm, but we are still building description, it means that
                            # there is only one case in the subsection, and therefore we set its title to ""
                            case_line_indices[0] = rocq_line.line_number
                            case_line_indices[1] = rocq_line.line_number
                            parser_state = ParserState.READING_CASES
                            current_case = parsed_comment + "\n"
                            if not current_case_titles:
                                current_case_titles.append(["", ""])
                        else:
                            description += parsed_comment + " "
                    case ParserState.READING_CASES:
                        case_line_indices[1] = rocq_line.line_number
                        if self.algo_regex.match(parsed_comment) or not in_case_title:
                            if not current_case_titles:
                                current_case_titles.append(["", ""])
                            in_case_title = False
                            current_case += parsed_comment + "\n"
                        elif in_case_title:
                            current_case_titles[-1][1] += "\n" + parsed_comment
        if current_case != "":
            case_pos = RocqPosition({comment_lines[-1][1].file_name: tuple(case_line_indices)})
            for case_title in current_case_titles:
                add_case(cases, case_title[0], case_title[1], String(case_pos, current_case))
        cases_dict = Dictionary(None, cases)
        return Dictionary(RocqPosition(filenames), {"title": String(None, title),
                                                   "description": String(None, description),
                                                   "cases": cases_dict})

    def __parse_directives(self, comments):
        state = ParserState.BEFORE_START
        acc = ''
        sections = []
        for comment, rocq_line in comments:
            if comment == '':
                pass
            elif state == ParserState.BEFORE_START and comment.startswith('WILDCARD Sections'):
                state = ParserState.READING_WILDCARD
            elif state == ParserState.READING_WILDCARD:
                acc += comment
            else:
                raise Exception("Unexpected directive part: '" + comment + "' (State: " + str(state) + ")")

            if rocq_line.is_end_comment:
                sections += json.loads(acc)
                acc = ''
                state = ParserState.BEFORE_START
        return sections

    def get_parsed_page(self) -> ParsedPage:
        if self.sections_by_number is None:
            rocq_code, all_filenames = self.__get_rocq_code()
            spec = self.__process_lines(rocq_code, all_filenames, self.spec_regex)
            self.sections_by_number = self.__get_comment_titles(spec)

            directives = self.__process_lines(rocq_code, all_filenames, self.directive_regex)
            for section in self.__parse_directives(directives):
                self.sections_by_number[section] = WildCard(None)
        return ParsedPage(self.name, Dictionary(None, self.sections_by_number))
