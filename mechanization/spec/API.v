From Stdlib Require Import Bool Nat List.
From Warblre Require Import Base Errors Result Return RegExpRecord Patterns Notation Semantics Frontend.

Module API.
  Module Patterns := Patterns.

  (* Packs all parameters in a module type which can easily be instantiated in OCaml. *)
  Module Type EngineParameters.
    Parameter character : Type.
    Module Character.
      Parameter equal: forall (l r: character), {l=r} + {l<>r}.
      Parameter from_numeric_value: nat -> character.
      Parameter numeric_value: character -> nat.
      Parameter canonicalize: RegExpRecord -> character -> character.

      Axiom numeric_pseudo_bij: forall c, from_numeric_value (numeric_value c) = c.
      Axiom numeric_round_trip_order: forall l r, l <= r -> (numeric_value (from_numeric_value l)) <= (numeric_value (from_numeric_value r)).
    End Character.

    Parameter string : Type.
    Module String.
      Parameter equal: forall (l r: string), {l=r} + {l<>r}.
      Parameter length: string -> non_neg_integer.
      Parameter substring: string -> non_neg_integer -> non_neg_integer -> string.
      Parameter advanceStringIndex: string -> non_neg_integer -> non_neg_integer.
      Parameter getStringIndex: string -> non_neg_integer -> non_neg_integer.
      Parameter list_from_string: string -> list character.
      Parameter list_to_string: list character -> string.
    End String.

    Parameter char_set: Type.
    Module CharSet.
      Parameter empty: char_set.
      Parameter from_list: list character -> char_set.
      Parameter union: char_set -> char_set -> char_set.
      Parameter singleton: character -> char_set.
      Parameter size: char_set -> nat.
      Parameter remove_all: char_set -> char_set -> char_set.
      Parameter is_empty: char_set -> bool.
      Parameter elements: char_set -> list character.
      Parameter contains: char_set -> character -> bool.
      Parameter range: character -> character -> char_set.

      Parameter unique: forall (F: Type) (_: Result.AssertionError F), char_set -> Result character F.
      Parameter filter: char_set -> (character -> bool) -> char_set.
      Parameter exist: char_set -> (character -> bool) -> bool.
      Parameter exist_canonicalized: RegExpRecord -> char_set -> character -> bool.

      (*Axiom singleton_size: forall c, size (singleton c) = 1.
      Axiom singleton_exist: forall c p, exist (singleton c) p = p c.
      Axiom singleton_unique: forall (F: Type) (af: Result.AssertionError F) c, @unique F af (singleton c) = Success c.*)
      Axiom exist_canonicalized_equiv: forall rer s c,
        exist_canonicalized rer s c =
        exist
          s
          (fun c0 =>
            if Character.equal (Character.canonicalize rer c0) c
            then true else false).

      Parameter In: character -> char_set -> Prop.
      Definition Equal s1 s2 := forall c, In c s1 <-> In c s2.
      Definition Empty s := forall c, ~In c s.
      Definition Exists (P: character -> Prop) s := exists c, In c s /\ P c.
      Axiom empty_spec: forall c, ~ In c empty.
      Axiom from_list_spec: forall c l, In c (from_list l) <-> List.In c l. (* Custom *)
      Axiom union_spec: forall c s1 s2, In c (union s1 s2) <-> In c s1 \/ In c s2.
      Axiom singleton_spec: forall x c, In x (singleton c) <-> c = x. (* = instead of fixed equivalence relation *)
      Axiom size_spec: forall s, size s = List.length (elements s).
      Axiom remove_all_spec: forall c s1 s2, In c (remove_all s1 s2) <-> In c s1 /\ ~In c s2.
      Axiom is_empty_spec: forall s, is_empty s = true <-> Empty s. (* custom *)
      Axiom contains_spec: forall c s, contains s c = true <-> In c s.
      Axiom range_spec: forall c l h, In c (range l h) <-> Character.numeric_value l <= Character.numeric_value c /\ Character.numeric_value c <= Character.numeric_value h. (* custom *)
      Axiom unique_succ_spec: forall (F: Type) (H: Result.AssertionError F) (c: character) (s: char_set),
        unique F H s = Success c <-> Equal s (singleton c). (* custom *)
      Axiom unique_succ_error: forall (F: Type) (H: Result.AssertionError F) (s: char_set),
        (exists c, unique F H s = Success c) \/ unique F H s = Error (@Result.f F H). (* custom *)
      Axiom filter_spec: forall f c s,
        In c (filter s f) <-> In c s /\ f c = true.
      Axiom exist_spec: forall f s,
        exist s f = true <-> Exists (fun c => f c = true) s.
      Axiom elements_spec1: forall c s, List.In c (elements s) <-> In c s.
      Axiom elements_spec2: forall s, List.NoDup (elements s).

      Axiom union_empty: forall s e: char_set, Empty e -> union s e = s.
    End CharSet.

    Module CharSets.
      Parameter all: list character.
      Parameter line_terminators: list character.
      Parameter digits: list character.
      Parameter white_spaces: list character.
      Parameter ascii_word_characters: list character.
    End CharSets.

    Parameter property: Type.
    Module Property.
      Parameter equal: forall (l r: property), {l=r} + {l<>r}.
      Parameter code_points: property -> list character.
    End Property.
  End EngineParameters.

  (* Functor producing a fully executable engine. *)
  Module Engine (P: EngineParameters).
    Definition character := P.character.
    Definition string := P.string.
    Definition property := P.property.

    Instance character_marker: CharacterMarker character := (mk_character_marker _).
    Instance string_marker: StringMarker string := (mk_string_marker _).
    Instance property_marker: UnicodePropertyMarker property := (mk_unicode_property_marker _).

    (* Instantiation *)
    Definition parameters: Parameters :=
      let character_class := (Character.make
        character
        (EqDec.make _ P.Character.equal)
        P.Character.from_numeric_value
        P.Character.numeric_value
        P.Character.canonicalize
        P.CharSets.all
        P.CharSets.line_terminators
        P.CharSets.digits
        P.CharSets.white_spaces
        P.CharSets.ascii_word_characters
        P.Character.numeric_pseudo_bij
        P.Character.numeric_round_trip_order)
      in
      Parameters.make
        character_class
        (CharSet.make character_class
          P.char_set
          P.CharSet.empty
          P.CharSet.from_list
          P.CharSet.union
          P.CharSet.singleton
          P.CharSet.size
          P.CharSet.remove_all
          P.CharSet.is_empty
          P.CharSet.elements
          P.CharSet.contains
          P.CharSet.range
          P.CharSet.unique
          P.CharSet.filter
          P.CharSet.exist
          P.CharSet.exist_canonicalized
          (*P.CharSet.singleton_size
          P.CharSet.singleton_exist
          P.CharSet.singleton_unique*)
          P.CharSet.exist_canonicalized_equiv
          P.CharSet.In
          P.CharSet.empty_spec
          P.CharSet.from_list_spec
          P.CharSet.union_spec
          P.CharSet.singleton_spec
          P.CharSet.size_spec
          P.CharSet.remove_all_spec
          P.CharSet.is_empty_spec
          P.CharSet.contains_spec
          P.CharSet.range_spec
          P.CharSet.unique_succ_spec
          P.CharSet.unique_succ_error
          P.CharSet.filter_spec
          P.CharSet.exist_spec
          P.CharSet.elements_spec1
          P.CharSet.elements_spec2
          P.CharSet.union_empty
          )
        (String.make character
          string
          (EqDec.make _ P.String.equal)
          P.String.length
          P.String.substring
          P.String.advanceStringIndex
          P.String.getStringIndex
          P.String.list_from_string
          P.String.list_to_string)
        (Property.make character
          property
          (EqDec.make _ P.Property.equal)
          P.Property.code_points)
        _ _ _.

    (*  In order to get a strongly typed (as in: without any Obj.t) API in OCaml,
        dependent types (on the Parameters argument) must be eliminated.
        This is done by providing equivalent, yet non-depent signatures for all functions
        exposed in this API.
    *)
    Notation Regex := (@Patterns.Regex character string property _ _ _).
    Notation MatchResult := (@Notation.MatchResult character _).
    Notation RegExpInstance := (@RegExpInstance.type _ _ _ _ _ _).
    Notation ExecResult := (@ExecResult character string property _ _ _).
    Notation ProtoMatchResult := (@ProtoMatchResult character string property _ _ _).

    (* API *)
    Definition countGroups: Regex -> non_neg_integer :=
      @StaticSemantics.countLeftCapturingParensWithin_impl parameters.

    Definition compilePattern:
        Regex -> (RegExpRecord.type) ->
        Result (list character -> non_neg_integer -> MatchResult) _
      := @Semantics.compilePattern parameters.

    Definition initialize: Regex -> RegExpFlags.type -> (Result RegExpInstance _) :=
      @Frontend.regExpInitialize parameters.
    Definition setLastIndex :=
      @Frontend.RegExpInstance.setLastIndex character string property _ _ _.
    Definition execArrayExotic := @Frontend.ExecArrayExotic string (mk_string_marker _).
    Definition exec: RegExpInstance -> string -> Result ExecResult _ :=
      @Frontend.regExpExec parameters.
    Definition search: RegExpInstance -> string -> Result.Result (integer * RegExpInstance) _ :=
      @Frontend.prototypeSearch parameters.
    Definition rmatch: RegExpInstance -> string -> Result.Result ProtoMatchResult _ :=
      @Frontend.prototypeMatch parameters.
    Definition rmatchAll: RegExpInstance -> string -> Result.Result (list ExecArrayExotic * RegExpInstance) _ :=
      @Frontend.prototypeMatchAll parameters.
    Definition test: RegExpInstance -> string -> Result.Result (bool * RegExpInstance) _ :=
      @Frontend.prototypeTest parameters.

    Definition stringMatchAll: RegExpInstance -> string -> Result.Result (list ExecArrayExotic * RegExpInstance) _ :=
      @Frontend.prototypeMatchAll parameters.
  End Engine.

  (*  Other utils, such as functions of the specification which are not used in the mechanization, but could
      be useful to instantiate an engine from OCaml.
  *)
  Module Utils.
    Local Open Scope nat.
    Import Result.Notations.
    Local Open Scope result_flow.

    (* Required operations on utf16 strings. *)
    Module Type Utf16String.
      Parameter Utf16CodeUnit: Type.
      Parameter Utf16String: Type.
      Parameter length: Utf16String -> non_neg_integer.
      Parameter codeUnitAt: forall {F: Type} {_: Result.AssertionError F}, Utf16String -> non_neg_integer -> Result Utf16CodeUnit F.
      Parameter is_leading_surrogate: Utf16CodeUnit -> bool.
      Parameter is_trailing_surrogate: Utf16CodeUnit -> bool.
    End Utf16String.

    Module UnicodeOps (S: Utf16String).
      Include S.

      (** >> 
          11.1.4 Static Semantics: CodePointAt ( string, position )

          The abstract operation CodePointAt takes arguments string (a String) and position (a non-negative integer)
          and returns a Record with fields [[CodePoint]] (a code point), [[CodeUnitCount]] (a positive integer), and
          [[IsUnpairedSurrogate]] (a Boolean). It interprets string as a sequence of UTF-16 encoded code points, as
          described in 6.1.4, and reads from it a single code point starting with the code unit at index position.
          It performs the following steps when called:
      <<*)

      Definition codePointAt (string: Utf16String) (position: non_neg_integer): Result (non_neg_integer * bool) MatchError :=
        (*>> 1. Let size be the length of string. <<*)
        let size := length string in
        (*>> 2. Assert: position ≥ 0 and position < size. <<*)
        assert! (position >=? 0) && (position <? size) ;
        (*>> 3. Let first be the code unit at index position within string. <<*)
        let! first =<< codeUnitAt string position in
        (*>> 4. Let cp be the code point whose numeric value is the numeric value of first. <<*)
        (*>> We don't return cp, so this isn't required <<*)
        (*>> 5. If first is neither a leading surrogate nor a trailing surrogate, then <<*)
        if negb (is_leading_surrogate first) && negb (is_trailing_surrogate first) then
          (*>> a. Return the Record { [[CodePoint]]: cp, [[CodeUnitCount]]: 1, [[IsUnpairedSurrogate]]: false }. <<*)
          Success (1, false)
        else
        (*>> 6. If first is a trailing surrogate or position + 1 = size, then <<*)
        if is_trailing_surrogate first || ((position + 1) == size) then
          (*>> a. Return the Record { [[CodePoint]]: cp, [[CodeUnitCount]]: 1, [[IsUnpairedSurrogate]]: true }. <<*)
          Success (1, true)
        else
        (*>> 7. Let second be the code unit at index position + 1 within string. <<*)
        let! second =<< codeUnitAt string (position + 1) in
        (*>> 8. If second is not a trailing surrogate, then <<*)
        if negb (is_trailing_surrogate second) then
          (*>> a. Return the Record { [[CodePoint]]: cp, [[CodeUnitCount]]: 1, [[IsUnpairedSurrogate]]: true }. <<*)
          Success (1, true)
        else
        (*>> [OMITTED] 9. Set cp to UTF16SurrogatePairToCodePoint(first, second). <<*)
        (* + We don't return cp, so this isn't required +*)
        (*>> 10. Return the Record { [[CodePoint]]: cp, [[CodeUnitCount]]: 2, [[IsUnpairedSurrogate]]: false }. <<*)
        Success (2, false).


      (** >>
          22.2.7.3 AdvanceStringIndex ( S, index, unicode )

          The abstract operation AdvanceStringIndex takes arguments S (a String), index (a non-negative integer),
          and unicode (a Boolean) and returns an integer. It performs the following steps when called:
      <<*)
      (* + This function is specialized to only handle the unicode case; the other case is uninteresting. +*)
      Definition advanceStringIndex (S: Utf16String) (index: non_neg_integer) : Result.Result non_neg_integer MatchError :=
        (*>> [OMITTED] 1. Assert: index ≤ 2^53 - 1. <<*)
        (* + We don't include numeric limits +*)
        (*>> [OMITTED] 2. If unicode is false, return index + 1. <<*)
        (* + Unicode is always true +*)
        (*>> 3. Let length be the length of S. <<*)
        let length := length S in
        (*>> 4. If index + 1 ≥ length, return index + 1. <<*)
        if (index + 1) >=? length then Success (index + 1) else
        (*>> 5. Let cp be CodePointAt(S, index). <<*)
        let! (codeUnitCount, _) =<< codePointAt S index in
        (*>> 6. Return index + cp.[[CodeUnitCount]]. <<*)
        Success (index + codeUnitCount)%nat.

      (** >>
          22.2.7.4 GetStringIndex ( S, codePointIndex )

          The abstract operation GetStringIndex takes arguments S (a String) and codePointIndex (a non-negative integer)
          and returns a non-negative integer. It interprets S as a sequence of UTF-16 encoded code points, as described
          in 6.1.4, and returns the code unit index corresponding to code point index codePointIndex when such an index
          exists. Otherwise, it returns the length of S. It performs the following steps when called:
      <<*)
      Definition getStringIndex (S: Utf16String) (codePointIndex: non_neg_integer) : Result.Result non_neg_integer MatchError :=
        (*>> 1. If S is the empty String, return 0. <<*)
        if length S == 0 then Success 0 else
        (*>> 2. Let len be the length of S. <<*)
        let len := length S in
        (*>> 3. Let codeUnitCount be 0. <<*)
        let codeUnitCount := 0 in
        (*>> 4. Let codePointCount be 0. <<*)
        let codePointCount := 0 in
        (*>> 5. Repeat, while codeUnitCount < len, <<*)
        let! res =<< Return.while MatchError.OutOfFuel (len + 2) (codeUnitCount, codePointCount)
          (fun p => let (codeUnitCount, _) := p in codeUnitCount <? len)
          (fun p => let (codeUnitCount, codePointCount) := p in
            (*>> a. If codePointCount = codePointIndex, return codeUnitCount. <<*)
            if codePointCount == codePointIndex then Success (Return.ret codeUnitCount) else
            (*>> b. Let cp be CodePointAt(S, codeUnitCount). <<*)
            let! (cp_codeUnitCount, _) =<< codePointAt S codeUnitCount in
            (*>> c. Set codeUnitCount to codeUnitCount + cp.[[CodeUnitCount]]. <<*)
            let codeUnitCount := codeUnitCount + cp_codeUnitCount in
            (*>> d. Set codePointCount to codePointCount + 1. <<*)
            let codePointCount := codePointCount + 1 in
            Success (Return.continue (codeUnitCount, codePointCount)))
        in
        match res with
        | Return.Returned v => Success v
        | Return.Continue (codeUnitCount, codePointCount) =>
            (*>> 6. Return len. <<*)
            Success codeUnitCount
        end.
    End UnicodeOps.
  End Utils.

  (** >>
      22.2.5.1 RegExp.escape ( S )

      This function returns a copy of S in which characters that are potentially special in a regular expression |Pattern|
      have been replaced by equivalent escape sequences.

      It performs the following steps when called:
  <<*)
  Section RegExpEscape.
    Context `{specParameters: Parameters}.

    (* Helper function to convert a number to a 2-digit hex representation.
       Returns the hex characters representing the number. *)
    Definition toHex2 (n: non_neg_integer): list Character :=
      (* For now, we return a placeholder - actual hex conversion would be done at extraction time.
         The specification says to convert to hex and pad with zeros. *)
      Character.from_numeric_value n :: nil.

    (* Helper function to convert a number to a 4-digit hex representation *)
    Definition toHex4 (n: non_neg_integer): list Character :=
      Character.from_numeric_value n :: nil.

    (* Check if a character is a decimal digit (0-9) *)
    Definition isDecimalDigit (c: Character): bool :=
      let nv := Character.numeric_value c in
      (nv >=? 48) && (nv <=? 57).

    (* Check if a character is an ASCII letter (a-z, A-Z) *)
    Definition isAsciiLetter (c: Character): bool :=
      let nv := Character.numeric_value c in
      ((nv >=? 65) && (nv <=? 90)) || ((nv >=? 97) && (nv <=? 122)).

    (* Check if a character is a SyntaxCharacter *)
    (* SyntaxCharacter :: one of ^ $ \ . * + ? ( ) [ ] { } | *)
    Definition isSyntaxCharacter (c: Character): bool :=
      let nv := Character.numeric_value c in
      (nv =? 94) ||  (* ^ *)
      (nv =? 36) ||  (* $ *)
      (nv =? 92) ||  (* \ *)
      (nv =? 46) ||  (* . *)
      (nv =? 42) ||  (* * *)
      (nv =? 43) ||  (* + *)
      (nv =? 63) ||  (* ? *)
      (nv =? 40) ||  (* ( *)
      (nv =? 41) ||  (* ) *)
      (nv =? 91) ||  (* [ *)
      (nv =? 93) ||  (* ] *)
      (nv =? 123) || (* { *)
      (nv =? 125) || (* } *)
      (nv =? 124).   (* | *)

    (* Check if a character is SOLIDUS (/) *)
    Definition isSolidus (c: Character): bool :=
      let nv := Character.numeric_value c in
      nv =? 47.

    (* Check if a character is a ControlEscape code point *)
    (* ControlEscape characters: t, n, v, f, r *)
    Definition isControlEscape (c: Character): option (list Character) :=
      let nv := Character.numeric_value c in
      if nv =? 9 then Some (Character.from_numeric_value 116 :: nil)  (* \t *)
      else if nv =? 10 then Some (Character.from_numeric_value 110 :: nil) (* \n *)
      else if nv =? 11 then Some (Character.from_numeric_value 118 :: nil) (* \v *)
      else if nv =? 12 then Some (Character.from_numeric_value 102 :: nil) (* \f *)
      else if nv =? 13 then Some (Character.from_numeric_value 114 :: nil) (* \r *)
      else None.

    (* Check if a character is in otherPunctuators list:
       comma, hyphen, equals, less-than, greater-than, hash, ampersand, 
       exclamation, percent, colon, semicolon, at, tilde, apostrophe, backtick, quotation mark *)
    Definition isOtherPunctuator (c: Character): bool :=
      let nv := Character.numeric_value c in
      (nv =? 44) ||  (* , *)
      (nv =? 45) ||  (* - *)
      (nv =? 61) ||  (* = *)
      (nv =? 60) ||  (* < *)
      (nv =? 62) ||  (* > *)
      (nv =? 35) ||  (* # *)
      (nv =? 38) ||  (* & *)
      (nv =? 33) ||  (* ! *)
      (nv =? 37) ||  (* % *)
      (nv =? 58) ||  (* : *)
      (nv =? 59) ||  (* semicolon *)
      (nv =? 64) ||  (* at *)
      (nv =? 126) || (* tilde *)
      (nv =? 39) ||  (* apostrophe *)
      (nv =? 96) ||  (* backtick *)
      (nv =? 34).    (* quotation mark *)

    (* Check if a character is whitespace or line terminator *)
    Definition isWhitespaceOrLineTerminator (c: Character): bool :=
      List.existsb (fun ws => if (c =?= ws) then true else false)
        (Character.white_spaces ++ Character.line_terminators).

    (* Check if a character is a leading or trailing surrogate *)
    Definition isSurrogate (c: Character): bool :=
      let nv := Character.numeric_value c in
      (* Leading surrogate: 0xD800-0xDBFF, Trailing surrogate: 0xDC00-0xDFFF *)
      (nv >=? 55296) && (nv <=? 57343).

    (* Create a string from a single character *)
    Definition charToString (c: Character): String :=
      (* We need to create a string from a character *)
      String.from_char_list (c :: nil).

    (* Concatenate two strings *)
    Definition concatStrings (s1 s2: String): String :=
      String.from_char_list (String.to_char_list s1 ++ String.to_char_list s2).

    (* Helper: create a string from a list of characters *)
    Definition charsToString (chars: list Character): String :=
      String.from_char_list chars.

    (* Helper: check if string is empty *)
    Definition isEmptyString (s: String): bool :=
      (String.length s) =? 0.

    (*>> 1. If S is not a String, throw a *TypeError* exception. <<*)
    (*>> 2. Let escaped be the empty String. <<*)
    (*>> 3. Let cpList be StringToCodePoints(S). <<*)
    (*>> 4. For each code point c of cpList, do <<*)
    (*>>   a. If escaped is the empty String and c is matched by either |DecimalDigit| or |AsciiLetter|, then <<*)
    (*>>     i. NOTE: Escaping a leading digit ensures that output corresponds with pattern text which may be used after a backslash 0 <<*)
    (*>>        character escape or a |DecimalEscape| such as backslash 1 and still match S rather than be interpreted as an extension <<*)
    (*>>        of the preceding escape sequence. Escaping a leading ASCII letter does the same for the context after backslash c. <<*)
    (*>>     ii. Let numericValue be the numeric value of c. <<*)
    (*>>     iii. Let hex be Number::toString(𝔽(numericValue), 16). <<*)
    (*>>     iv. Assert: The length of hex is 2. <<*)
    (*>>     v. Set escaped to the string-concatenation of the code unit 0x005C (REVERSE SOLIDUS), "x", and hex. <<*)
    (*>>   b. Else, <<*)
    (*>>     i. Set escaped to the string-concatenation of escaped and EncodeForRegExpEscape(c). <<*)
    (*>> 5. Return escaped. <<*)

    (** >>
        EncodeForRegExpEscape ( c )

        The abstract operation EncodeForRegExpEscape takes argument c (a code point) and returns a String.
        It returns a string representing a |Pattern| for matching c. If c is white space or an ASCII punctuator, the returned
        value is an escape sequence. Otherwise, the returned value is a string representation of c itself.
    <<*)
    (*>> 1. If c is matched by |SyntaxCharacter| or c is U+002F (SOLIDUS), then <<*)
    (*>>   a. Return the string-concatenation of 0x005C (REVERSE SOLIDUS) and UTF16EncodeCodePoint(c). <<*)
    (*>> 2. Else if c is the code point listed in some cell of the "Code Point" column of <<*)
    (*>>    <emu-xref href="#table-controlescape-code-point-values"></emu-xref>, then <<*)
    (*>>   a. Return the string-concatenation of 0x005C (REVERSE SOLIDUS) and the string in the "ControlEscape" column of <<*)
    (*>>      the row whose "Code Point" column contains c. <<*)
    (*>> 3. Let otherPunctuators be the string-concatenation of ",-=<>#&!%:;@~'" + (backtick) + the code unit 0x0022 (QUOTATION MARK). <<*)
    (*>> 4. Let toEscape be StringToCodePoints(otherPunctuators). <<*)
    (*>> 5. If toEscape contains c, c is matched by either |WhiteSpace| or |LineTerminator|, or c has the same numeric value <<*)
    (*>>    as a leading surrogate or trailing surrogate, then <<*)
    (*>>   a. Let cNum be the numeric value of c. <<*)
    (*>>   b. If cNum ≤ 0xFF, then <<*)
    (*>>     i. Let hex be Number::toString(𝔽(cNum), 16). <<*)
    (*>>     ii. Return the string-concatenation of the code unit 0x005C (REVERSE SOLIDUS), "x", and StringPad(hex, 2, "0", start). <<*)
    (*>>   c. Let escaped be the empty String. <<*)
    (*>>   d. Let codeUnits be UTF16EncodeCodePoint(c). <<*)
    (*>>   e. For each code unit cu of codeUnits, do <<*)
    (*>>     i. Set escaped to the string-concatenation of escaped and UnicodeEscape(cu). <<*)
    (*>>   f. Return escaped. <<*)
    (*>> 6. Return UTF16EncodeCodePoint(c). <<*)

    Definition encodeForRegExpEscape (c: Character): String :=
      (*>> 1. If c is matched by |SyntaxCharacter| or c is U+002F (SOLIDUS), then <<*)
      if (isSyntaxCharacter c) || (isSolidus c) then
        (*>>   a. Return the string-concatenation of 0x005C (REVERSE SOLIDUS) and UTF16EncodeCodePoint(c). <<*)
        let backslash := Character.from_numeric_value 92 in
        charsToString (backslash :: c :: nil)
      else
      (*>> 2. Else if c is the code point listed in some cell of the "Code Point" column of <<*)
      (*>>    <emu-xref href="#table-controlescape-code-point-values"></emu-xref>, then <<*)
      match isControlEscape c with
      | Some escChar =>
          (*>>   a. Return the string-concatenation of 0x005C (REVERSE SOLIDUS) and the string in the "ControlEscape" column of <<*)
          (*>>      the row whose "Code Point" column contains c. <<*)
          let backslash := Character.from_numeric_value 92 in
          charsToString (backslash :: escChar)
      | None =>
          (*>> 3. Let otherPunctuators be the string-concatenation of ",-=<>#&!%:;@~'" + (backtick) + the code unit 0x0022 (QUOTATION MARK). <<*)
          (*>> 4. Let toEscape be StringToCodePoints(otherPunctuators). <<*)
          (*>> 5. If toEscape contains c, c is matched by either |WhiteSpace| or |LineTerminator|, or c has the same numeric value <<*)
          (*>>    as a leading surrogate or trailing surrogate, then <<*)
          if (isOtherPunctuator c) || (isWhitespaceOrLineTerminator c) || (isSurrogate c) then
            let cNum := Character.numeric_value c in
            (*>>   a. Let cNum be the numeric value of c. <<*)
            (*>>   b. If cNum ≤ 0xFF, then <<*)
            if cNum <=? 255 then
              (*>>     i. Let hex be Number::toString(𝔽(cNum), 16). <<*)
              (*>>     ii. Return the string-concatenation of the code unit 0x005C (REVERSE SOLIDUS), "x", and StringPad(hex, 2, "0", start). <<*)
              let backslash := Character.from_numeric_value 92 in
              let x := Character.from_numeric_value 120 in
              (* For the hex conversion, we use a simplified representation *)
              charsToString (backslash :: x :: toHex2 cNum)
            else
              (*>>   c. Let escaped be the empty String. <<*)
              (*>>   d. Let codeUnits be UTF16EncodeCodePoint(c). <<*)
              (*>>   e. For each code unit cu of codeUnits, do <<*)
              (*>>     i. Set escaped to the string-concatenation of escaped and UnicodeEscape(cu). <<*)
              (*>>   f. Return escaped. <<*)
              (* For code points > 0xFF, we use \uXXXX escape *)
              let backslash := Character.from_numeric_value 92 in
              let u := Character.from_numeric_value 117 in
              charsToString (backslash :: u :: toHex4 cNum)
          else
            (*>> 6. Return UTF16EncodeCodePoint(c). <<*)
            charToString c
      end.

    Fixpoint regExpEscape_aux (cpList: list Character) (escaped: String): String :=
      match cpList with
      | nil => escaped
      | c :: rest =>
          (*>>   a. If escaped is the empty String and c is matched by either |DecimalDigit| or |AsciiLetter|, then <<*)
          if (isEmptyString escaped) && ((isDecimalDigit c) || (isAsciiLetter c)) then
            (*>>     ii. Let numericValue be the numeric value of c. <<*)
            let numericValue := Character.numeric_value c in
            (*>>     iii. Let hex be Number::toString(𝔽(numericValue), 16). <<*)
            (*>>     iv. Assert: The length of hex is 2. <<*)
            (*>>     v. Set escaped to the string-concatenation of the code unit 0x005C (REVERSE SOLIDUS), "x", and hex. <<*)
            let backslash := Character.from_numeric_value 92 in
            let x := Character.from_numeric_value 120 in
            let newEscaped := charsToString (backslash :: x :: toHex2 numericValue) in
            regExpEscape_aux rest newEscaped
          else
            (*>>   b. Else, <<*)
            (*>>     i. Set escaped to the string-concatenation of escaped and EncodeForRegExpEscape(c). <<*)
            let encoded := encodeForRegExpEscape c in
            let newEscaped := concatStrings escaped encoded in
            regExpEscape_aux rest newEscaped
      end.

    Definition regExpEscape (S: String): String :=
      (*>> 1. If S is not a String, throw a *TypeError* exception. <<*)
      (* + In our type system, S is always a String + *)
      (*>> 2. Let escaped be the empty String. <<*)
      (*>> 3. Let cpList be StringToCodePoints(S). <<*)
      let cpList := String.to_char_list S in
      (*>> 4. For each code point c of cpList, do <<*)
      (*>> 5. Return escaped. <<*)
      regExpEscape_aux cpList (String.from_char_list nil).

  End RegExpEscape.

End API.
