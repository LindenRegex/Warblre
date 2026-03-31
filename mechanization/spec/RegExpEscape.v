From Stdlib Require Import List Bool ZArith.
From Stdlib Require Import Strings.Ascii Strings.String.
From Warblre Require Import Base Errors Result Return RegExpRecord Patterns Notation Parameters Characters Numeric.

Import Result.Notations.
Local Open Scope result_flow.
Local Open Scope string_scope.

(** ##
    22.2.5 Properties of the RegExp Constructor
##*)

(** >>
    22.2.5.1 RegExp.escape ( S )

    This function returns a copy of S in which characters that are potentially special in a regular expression
    Pattern have been replaced by equivalent escape sequences.
    It performs the following steps when called:
<<*)

Module RegExpEscape. Section main.
  Context `{specParameters: Parameters}.

  (* Helper function to convert a nat to a hex digit character *)
  Definition nat_to_hex_digit (n: nat): Stdlib.Strings.String.string :=
    match n with
    | 0 => "0"
    | 1 => "1"
    | 2 => "2"
    | 3 => "3"
    | 4 => "4"
    | 5 => "5"
    | 6 => "6"
    | 7 => "7"
    | 8 => "8"
    | 9 => "9"
    | 10 => "a"
    | 11 => "b"
    | 12 => "c"
    | 13 => "d"
    | 14 => "e"
    | _ => "f"
    end.

  (* Helper function to convert a nat to a hex string (lowercase, no padding) *)
  (* Uses structural recursion on fuel *)
  Fixpoint nat_to_hex_string_aux (n: nat) (fuel: nat): Stdlib.Strings.String.string :=
    match fuel with
    | 0 => nat_to_hex_digit n
    | S fuel' =>
        if Nat.leb n 15 then nat_to_hex_digit n
        else
          let rest := nat_to_hex_string_aux (n / 16) fuel' in
          let digit := nat_to_hex_digit (n mod 16) in
          Stdlib.Strings.String.append rest digit
    end.

  Definition nat_to_hex_string (n: nat): Stdlib.Strings.String.string :=
    (* n / 16 decreases n, and we need at most log_16(n) + 1 steps *)
    (* Using n+1 as fuel is more than sufficient *)
    nat_to_hex_string_aux n (n + 1).

  (* Helper to pad a string on the left to a minimum length with a given character *)
  Fixpoint string_pad_left_aux (s: Stdlib.Strings.String.string) (remaining: nat) (pad_char: Stdlib.Strings.String.string): Stdlib.Strings.String.string :=
    match remaining with
    | 0 => s
    | S remaining' =>
        string_pad_left_aux (Stdlib.Strings.String.append pad_char s) remaining' pad_char
    end.

  Definition string_pad_left (s: Stdlib.Strings.String.string) (min_len: nat) (pad_char: Stdlib.Strings.String.string): Stdlib.Strings.String.string :=
    let slen := Stdlib.Strings.String.length s in
    let remaining := min_len - slen in
    string_pad_left_aux s remaining pad_char.

  (* Helper to check if a character is a decimal digit (0-9) *)
  Definition isDecimalDigit (c: Character): bool :=
    let nv := Character.numeric_value c in
    (Nat.leb 48 nv) && (Nat.leb nv 57).

  (* Helper to check if a character is an ASCII letter (A-Z, a-z) *)
  Definition isAsciiLetter (c: Character): bool :=
    let nv := Character.numeric_value c in
    ((Nat.leb 65 nv) && (Nat.leb nv 90)) || ((Nat.leb 97 nv) && (Nat.leb nv 122)).

  (* Helper to check if a character is a SyntaxCharacter *)
  (* SyntaxCharacter :: one of ^ $ \ . * + ? ( ) [ ] { } | *)
  Definition isSyntaxCharacter (c: Character): bool :=
    let nv := Character.numeric_value c in
    (Nat.eqb nv 94)  ||
    (Nat.eqb nv 36)  ||
    (Nat.eqb nv 92)  ||
    (Nat.eqb nv 46)  ||
    (Nat.eqb nv 42)  ||
    (Nat.eqb nv 43)  ||
    (Nat.eqb nv 63)  ||
    (Nat.eqb nv 40)  ||
    (Nat.eqb nv 41)  ||
    (Nat.eqb nv 91)  ||
    (Nat.eqb nv 93)  ||
    (Nat.eqb nv 123) ||
    (Nat.eqb nv 125) ||
    (Nat.eqb nv 124).

  (* Helper to check if a character matches ControlEscape table *)
  (* Table 63: Control Escape Characters
     t: CHARACTER_TABULATION (9)
     n: LINE_FEED (10)
     v: LINE_TABULATION (11)
     f: FORM_FEED (12)
     r: CARRIAGE_RETURN (13) *)
  Definition controlEscapeFor (c: Character): option Stdlib.Strings.String.string :=
    let nv := Character.numeric_value c in
    if Nat.eqb nv 9 then Some "t"
    else if Nat.eqb nv 10 then Some "n"
    else if Nat.eqb nv 11 then Some "v"
    else if Nat.eqb nv 12 then Some "f"
    else if Nat.eqb nv 13 then Some "r"
    else None.

  (* Check if character is in otherPunctuators: comma, hyphen, equals, less, greater, hash, ampersand,
     exclamation, percent, colon, semicolon, at, tilde, backtick, apostrophe, quotation *)
  Definition isOtherPunctuator (c: Character): bool :=
    let nv := Character.numeric_value c in
    (Nat.eqb nv 44)  ||
    (Nat.eqb nv 45)  ||
    (Nat.eqb nv 61)  ||
    (Nat.eqb nv 60)  ||
    (Nat.eqb nv 62)  ||
    (Nat.eqb nv 35)  ||
    (Nat.eqb nv 38)  ||
    (Nat.eqb nv 33)  ||
    (Nat.eqb nv 37)  ||
    (Nat.eqb nv 58)  ||
    (Nat.eqb nv 59)  ||
    (Nat.eqb nv 64)  ||
    (Nat.eqb nv 126) ||
    (Nat.eqb nv 96)  ||
    (Nat.eqb nv 39)  ||
    (Nat.eqb nv 34).

  (* Check if a character is in WhiteSpace or LineTerminator *)
  Definition isWhiteSpaceOrLineTerminator (c: Character): bool :=
    CharSet.contains Characters.white_spaces c ||
    CharSet.contains Characters.line_terminators c.

  (* Check if character is a leading surrogate (0xD800-0xDBFF) *)
  Definition isLeadingSurrogate (c: Character): bool :=
    let nv := Character.numeric_value c in
    (Nat.leb 55296 nv) && (Nat.leb nv 56319).

  (* Check if character is a trailing surrogate (0xDC00-0xDFFF) *)
  Definition isTrailingSurrogate (c: Character): bool :=
    let nv := Character.numeric_value c in
    (Nat.leb 56320 nv) && (Nat.leb nv 57343).

  (* Encode a code point as UTF16 and then Unicode-escape each code unit *)
  (* For simplicity, we handle BMP characters directly and use \uXXXX for surrogates *)
  Definition unicodeEscape (c: Character): Stdlib.Strings.String.string :=
    let nv := Character.numeric_value c in
    if Nat.leb nv 65535 then
      (* Single code unit - use \uXXXX *)
      let hex := nat_to_hex_string nv in
      let padded := string_pad_left hex 4 "0" in
      Stdlib.Strings.String.append "\u" padded
    else
      (* Astral code point - encode as surrogate pair and escape each *)
      (* cp - 0x10000 *)
      let cp_minus_10000 := nv - 65536 in
      (* lead = (cp - 0x10000) / 0x400 + 0xD800 *)
      let lead := (cp_minus_10000 / 1024) + 55296 in
      (* trail = (cp - 0x10000) % 0x400 + 0xDC00 *)
      let trail := (cp_minus_10000 mod 1024) + 56320 in
      let lead_hex := nat_to_hex_string lead in
      let trail_hex := nat_to_hex_string trail in
      let lead_padded := string_pad_left lead_hex 4 "0" in
      let trail_padded := string_pad_left trail_hex 4 "0" in
      Stdlib.Strings.String.append (Stdlib.Strings.String.append (Stdlib.Strings.String.append "\u" lead_padded) "\u") trail_padded.

  (* Create a string from a single character (its ASCII representation) *)
  (* For BMP characters > 0x7F and <= 0xFF, use \xNN escape *)
  (* For BMP characters > 0xFF, use \uNNNN escape *)
  (* For astral code points, encode as surrogate pair *)
  Definition char_to_string (c: Character): Stdlib.Strings.String.string :=
    let nv := Character.numeric_value c in
    if Nat.leb nv 127 then
      (* Standard ASCII - direct representation *)
      Stdlib.Strings.String.String (Stdlib.Strings.Ascii.ascii_of_nat nv) ""
    else if Nat.leb nv 255 then
      (* Extended ASCII - use \xNN escape *)
      let hex := nat_to_hex_string nv in
      let padded := string_pad_left hex 2 "0" in
      Stdlib.Strings.String.append "\x" padded
    else if Nat.leb nv 65535 then
      (* BMP character > 0xFF - use \uNNNN escape *)
      let hex := nat_to_hex_string nv in
      let padded := string_pad_left hex 4 "0" in
      Stdlib.Strings.String.append "\u" padded
    else
      (* Astral code point - encode as surrogate pair *)
      unicodeEscape c.

  (** >>
      22.2.5.1.1 EncodeForRegExpEscape ( c )

      The abstract operation EncodeForRegExpEscape takes argument c (a code point) and returns a String.
      It returns a string representing a Pattern for matching c. If c is white space or an ASCII punctuator,
      the returned value is an escape sequence. Otherwise, the returned value is a string representation of c itself.
      It performs the following steps when called:
  <<*)
  Definition encodeForRegExpEscape (c: Character): Stdlib.Strings.String.string :=
    (*>> 1. If c is matched by SyntaxCharacter or c is U+002F (SOLIDUS), then <<*)
    if isSyntaxCharacter c || (Nat.eqb (Character.numeric_value c) 47) then
      (*>> a. Return the string-concatenation of 0x005C (REVERSE SOLIDUS) and UTF16EncodeCodePoint(c). <<*)
      let c_str := char_to_string c in
      Stdlib.Strings.String.append "\" c_str
    (*>> 2. Else if c is the code point listed in some cell of the "Code Point" column of Table 63, then <<*)
    else
      match controlEscapeFor c with
      | Some esc_str =>
          (*>> a. Return the string-concatenation of 0x005C (REVERSE SOLIDUS) and the string in the "ControlEscape" column of the row whose "Code Point" column contains c. <<*)
          Stdlib.Strings.String.append "\" esc_str
      | None =>
          (*>> 3. Let otherPunctuators be the string-concatenation of ",-=<>&!%:;@~'``" and the code unit 0x0022 (QUOTATION MARK). <<*)
          (*>> 4. Let toEscape be StringToCodePoints(otherPunctuators). <<*)
          (*>> 5. If toEscape contains c, c is matched by either WhiteSpace or LineTerminator, or c has the same numeric value as a leading surrogate or trailing surrogate, then <<*)
          if isOtherPunctuator c || isWhiteSpaceOrLineTerminator c || isLeadingSurrogate c || isTrailingSurrogate c then
            (*>> a. Let cNum be the numeric value of c. <<*)
            let cNum := Character.numeric_value c in
            (*>> b. If cNum ≤ 0xFF, then <<*)
            if Nat.leb cNum 255 then
              (*>> i. Let hex be Number::toString(𝔽(cNum), 16). <<*)
              let hex := nat_to_hex_string cNum in
              (*>> ii. Return the string-concatenation of the code unit 0x005C (REVERSE SOLIDUS), "x", and StringPad(hex, 2, "0", start). <<*)
              let padded := string_pad_left hex 2 "0" in
              Stdlib.Strings.String.append "\x" padded
            (*>> c. Else, <<*)
            else
              (*>> i. Let escaped be the empty String. <<*)
              (*>> ii. Let codeUnits be UTF16EncodeCodePoint(c). <<*)
              (*>> iii. For each code unit cu of codeUnits, do <<*)
              (*>> iv. Set escaped to the string-concatenation of escaped and UnicodeEscape(cu). <<*)
              (*>> v. Return escaped. <<*)
              unicodeEscape c
          (*>> 6. Return UTF16EncodeCodePoint(c). <<*)
          else
            char_to_string c
      end.

  (** >>
      22.2.5.1 RegExp.escape ( S )

      This function returns a copy of S in which characters that are potentially special in a regular expression
      Pattern have been replaced by equivalent escape sequences.
      It performs the following steps when called:
  <<*)

  (* Process each code point in the list *)
  Fixpoint processCodePoints (escaped: Stdlib.Strings.String.string) (cpList: list Character): Stdlib.Strings.String.string :=
    match cpList with
    | nil => escaped
    | c :: rest =>
        (*>> b. If escaped is the empty String and c is matched by either DecimalDigit or AsciiLetter, then <<*)
        let new_escaped :=
          if (Nat.eqb (Stdlib.Strings.String.length escaped) 0) && (isDecimalDigit c || isAsciiLetter c) then
            (*>> i. NOTE: Escaping a leading digit ensures that output corresponds with pattern text which may be used after a \0 character escape or a DecimalEscape such as \1 and still match S rather than be interpreted as an extension of the preceding escape sequence. Escaping a leading ASCII letter does the same for the context after \c. <<*)
            (*>> ii. Let numericValue be the numeric value of c. <<*)
            let numericValue := Character.numeric_value c in
            (*>> iii. Let hex be Number::toString(𝔽(numericValue), 16). <<*)
            let hex := nat_to_hex_string numericValue in
            (*>> iv. Assert: The length of hex is 2. <<*)
            (* This is true because numericValue for 0-9 and A-Z/a-z is 48-57, 65-90, 97-122, all ≤ 0x7A *)
            (*>> v. Set escaped to the string-concatenation of the code unit 0x005C (REVERSE SOLIDUS), "x", and hex. <<*)
            Stdlib.Strings.String.append "\x" hex
          (*>> c. Else, <<*)
          else
            (*>> i. Set escaped to the string-concatenation of escaped and EncodeForRegExpEscape(c). <<*)
            Stdlib.Strings.String.append escaped (encodeForRegExpEscape c)
        in
        processCodePoints new_escaped rest
    end.

  (* Note: We work directly with list Character as StringToCodePoints(S) returns list Character *)
  Definition regExpEscape (S: list Character): Stdlib.Strings.String.string :=
    (*>> 1. If S is not a String, throw a TypeError exception. <<*)
    (* + This is handled by the type system; S is always a list Character +*)
    (*>> 2. Let escaped be the empty String. <<*)
    let escaped := "" in
    (*>> 3. Let cpList be StringToCodePoints(S). <<*)
    let cpList := S in
    (*>> 4. For each code point c of cpList, do <<*)
    processCodePoints escaped cpList.

  (* Alternative version that takes a proper String type and converts it *)
  Definition regExpEscapeFromString (S: String): Stdlib.Strings.String.string :=
    regExpEscape (Parameters.String.to_char_list S).

End main. End RegExpEscape.
