open Warblre.OCamlEngines.UnicodeNotations
open Warblre.OCamlEngines.UnicodeTester

(* RegExp Modifiers tests from test262 PR #3960
   https://github.com/tc39/test262/pull/3960

   These tests cover the RegExp Modifiers proposal which allows
   inline modification of flags within a regex pattern using:
   - (?i:) - add ignoreCase modifier
   - (?-i:) - remove ignoreCase modifier
   - (?s:) - add dotAll modifier
   - (?-s:) - remove dotAll modifier
   - (?m:) - add multiline modifier
   - (?-m:) - remove multiline modifier
   - (?i-s:) - add and remove modifiers simultaneously
*)

(* ============================================================================
   add-ignoreCase.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_basic_1" =
  test_regex
    (add_modifiers "i" ((cchar 'a') -- (cchar 'b')))
    "Ab"
    0 ();
  [%expect {|
    Regex /(?i:ab)/ on 'Ab' at 0:
    Input: Ab
    End: 2
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_basic_2" =
  test_regex
    ((cchar 'b') -- (add_modifiers "i" (cchar 'a')))
    "bA"
    0 ();
  [%expect {|
    Regex /b(?i:a)/ on 'bA' at 0:
    Input: bA
    End: 2
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_basic_3" =
  test_regex
    ((cchar 'a') -- (add_modifiers "i" (cchar 'b')) -- (cchar 'c'))
    "aBc"
    0 ();
  [%expect {|
    Regex /a(?i:b)c/ on 'aBc' at 0:
    Input: aBc
    End: 3
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_no_match_outside_modifier" =
  test_regex
    ((cchar 'a') -- (add_modifiers "i" (cchar 'b')))
    "AB"
    0 ();
  [%expect {|
    Regex /a(?i:b)/ on 'AB' at 0:
    No match |}]

(* ============================================================================
   remove-ignoreCase.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_basic_1" =
  test_regex
    (remove_modifiers "" "i" ((cchar 'f') -- (cchar 'o')) -- (cchar 'o'))
    "foo"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:fo)o/ on 'foo' at 0:
    Input: foo
    End: 3
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_basic_2" =
  test_regex
    ((cchar 'b') -- (remove_modifiers "" "i" ((cchar 'a') -- (cchar 'r'))))
    "bar"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /b(?-i:ar)/ on 'bar' at 0:
    Input: bar
    End: 3
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_basic_3" =
  test_regex
    ((cchar 'b') -- (remove_modifiers "" "i" (cchar 'a')) -- (cchar 'z'))
    "baz"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /b(?-i:a)z/ on 'baz' at 0:
    Input: baz
    End: 3
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_no_match" =
  test_regex
    (remove_modifiers "" "i" ((cchar 'f') -- (cchar 'o')) -- (cchar 'o'))
    "FOO"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:fo)o/ on 'FOO' at 0:
    No match |}]

(* ============================================================================
   add-dotAll.js
   ============================================================================ *)

let%expect_test "add_dotAll_matches_line_terminators" =
  test_regex
    (add_modifiers "s" (InputStart -- Dot -- InputEnd))
    "\n"
    0 ();
  [%expect {|
    Regex /(?s:^.$)/ on '
    ' at 0:
    Input:

    End: 1
    Captures:
    	None |}]

let%expect_test "add_dotAll_matches_non_line_terminators" =
  test_regex
    (add_modifiers "s" (InputStart -- Dot -- InputEnd))
    "a"
    0 ();
  [%expect {|
    Regex /(?s:^.$)/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

let%expect_test "add_dotAll_does_not_affect_outside" =
  test_regex
    ((cchar 'a') -- Dot -- (add_modifiers "s" ((cchar 'b') -- Dot -- (cchar 'b'))) -- Dot -- (cchar 'c'))
    "a,b\nb,c"
    0 ();
  [%expect {|
    Regex /a.(?s:b.b).c/ on 'a,b
    b,c' at 0:
    Input: a,b
    b,c
    End: 7
    Captures:
    	None |}]

let%expect_test "add_dotAll_outside_fails_on_line_terminator" =
  test_regex
    ((cchar 'a') -- Dot -- (add_modifiers "s" ((cchar 'b') -- Dot -- (cchar 'b'))) -- Dot -- (cchar 'c'))
    "a\nb\nb,c"
    0 ();
  [%expect {|
    Regex /a.(?s:b.b).c/ on 'a
    b
    b,c' at 0:
    No match |}]

(* ============================================================================
   remove-dotAll.js
   ============================================================================ *)

let%expect_test "remove_dotAll_does_not_match_line_terminators" =
  test_regex
    (remove_modifiers "" "s" (InputStart -- Dot -- InputEnd))
    "\n"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:^.$)/ on '
    ' at 0:
    No match |}]

let%expect_test "remove_dotAll_matches_non_line_terminators" =
  test_regex
    (remove_modifiers "" "s" (InputStart -- Dot -- InputEnd))
    "a"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:^.$)/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

let%expect_test "remove_dotAll_outside_matches_line_terminator" =
  test_regex
    ((cchar 'a') -- Dot -- (remove_modifiers "" "s" ((cchar 'b') -- Dot -- (cchar 'b'))) -- Dot -- (cchar 'c'))
    "a\nb,b\nc"
    0 ~dotAll:true ();
  [%expect {|
    Regex /a.(?-s:b.b).c/ on 'a
    b,b
    c' at 0:
    Input: a
    b,b
    c
    End: 7
    Captures:
    	None |}]

(* ============================================================================
   add-multiline.js
   ============================================================================ *)

let%expect_test "add_multiline_matches_newline_with_dollar" =
  test_regex
    (add_modifiers "m" ((cchar 'e') -- (cchar 's') -- InputEnd))
    "es\ns"
    0 ();
  [%expect {|
    Regex /(?m:es$)/ on 'es
    s' at 0:
    Input: es
    s
    End: 2
    Captures:
    	None |}]

let%expect_test "add_multiline_matches_newline_with_caret" =
  test_regex
    ((cchar 'a') -- (ichar 10) -- (add_modifiers "m" (InputStart -- (cchar 'b') -- InputEnd)) -- (ichar 10) -- (cchar 'c'))
    "a\nb\nc"
    0 ();
  [%expect {|
    Regex /a
    (?m:^b$)
    c/ on 'a
    b
    c' at 0:
    Input: a
    b
    c
    End: 5
    Captures:
    	None |}]

(* ============================================================================
   remove-multiline.js
   ============================================================================ *)

let%expect_test "remove_multiline_does_not_match_newline" =
  test_regex
    (InputStart -- (remove_modifiers "" "m" ((cchar 'e') -- (cchar 's') -- InputEnd)))
    "\nes\ns"
    0 ~multiline:true ();
  [%expect {|
    Regex /^(?-m:es$)/ on '
    es
    s' at 0:
    No match |}]

let%expect_test "remove_multiline_matches_end_of_input" =
  test_regex
    (InputStart -- (remove_modifiers "" "m" ((cchar 'e') -- (cchar 's') -- InputEnd)))
    "\nes"
    0 ~multiline:true ();
  [%expect {|
    Regex /^(?-m:es$)/ on '
    es' at 0:
    No match |}]

(* ============================================================================
   add-remove-modifiers.js
   ============================================================================ *)

let%expect_test "add_remove_modifiers_combined" =
  test_regex
    (remove_modifiers "m" "i" (InputStart -- (cchar 'a') -- InputEnd))
    "a\n"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?m-i:^a$)/ on 'a
    ' at 0:
    Input: a

    End: 1
    Captures:
    	None |}]

let%expect_test "add_remove_modifiers_no_case_insensitive" =
  test_regex
    (remove_modifiers "m" "i" (InputStart -- (cchar 'a') -- InputEnd))
    "A\n"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?m-i:^a$)/ on 'A
    ' at 0:
    No match |}]

(* ============================================================================
   nested-add-remove-modifiers.js
   ============================================================================ *)

let%expect_test "nested_add_remove_modifiers" =
  test_regex
    (add_modifiers "m" (InputStart -- (remove_modifiers "" "i" (InputStart -- (cchar 'a') -- InputEnd))))
    "a\n"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?m:^(?-i:^a$))/ on 'a
    ' at 0:
    Input: a

    End: 1
    Captures:
    	None |}]

let%expect_test "nested_add_remove_modifiers_no_match" =
  test_regex
    (add_modifiers "m" (InputStart -- (remove_modifiers "" "i" (InputStart -- (cchar 'a') -- InputEnd))))
    "A\n"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?m:^(?-i:^a$))/ on 'A
    ' at 0:
    No match |}]

(* ============================================================================
   nesting-add-ignoreCase-within-remove-ignoreCase.js
   ============================================================================ *)

let%expect_test "nesting_add_ignoreCase_within_remove_ignoreCase" =
  test_regex
    ((remove_modifiers "" "i" ((cchar 'a') -- (add_modifiers "i" (cchar 'b')))) -- (cchar 'c'))
    "aBc"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:a(?i:b))c/ on 'aBc' at 0:
    Input: aBc
    End: 3
    Captures:
    	None |}]

let%expect_test "nesting_add_ignoreCase_within_remove_ignoreCase_no_match" =
  test_regex
    ((remove_modifiers "" "i" ((cchar 'a') -- (add_modifiers "i" (cchar 'b')))) -- (cchar 'c'))
    "ABC"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:a(?i:b))c/ on 'ABC' at 0:
    No match |}]

(* ============================================================================
   nesting-add-dotAll-within-remove-dotAll.js
   ============================================================================ *)

let%expect_test "nesting_add_dotAll_within_remove_dotAll" =
  test_regex
    (remove_modifiers "" "s" (add_modifiers "s" (InputStart -- Dot -- InputEnd)))
    "\n"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:(?s:^.$))/ on '
    ' at 0:
    Input:

    End: 1
    Captures:
    	None |}]

(* ============================================================================
   nesting-add-multiline-within-remove-multiline.js
   ============================================================================ *)

let%expect_test "nesting_add_multiline_within_remove_multiline" =
  test_regex
    ((remove_modifiers "" "m" (((cchar 'e') -- (cchar 's') -- (add_modifiers "m" (InputEnd))) || ((cchar 'j') -- (cchar 's') -- InputEnd))))
    "es\ns"
    0 ~multiline:true ();
  [%expect {|
    Regex /(?-m:es(?m:$)|js$)/ on 'es
    s' at 0:
    Input: es
    s
    End: 2
    Captures:
    	None |}]

(* ============================================================================
   add-ignoreCase-does-not-affect-alternatives-outside.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_does_not_affect_alternatives_outside" =
  test_regex
    (((cchar 'a') || (cchar 'b') || (add_modifiers "i" (cchar 'c')) || (cchar 'd') || (cchar 'e')))
    "C"
    0 ();
  [%expect {|
    Regex /a|b|(?i:c)|d|e/ on 'C' at 0:
    Input: C
    End: 1
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_does_not_affect_alternatives_outside_no_match" =
  test_regex
    (((cchar 'a') || (cchar 'b') || (add_modifiers "i" (cchar 'c')) || (cchar 'd') || (cchar 'e')))
    "A"
    0 ();
  [%expect {|
    Regex /a|b|(?i:c)|d|e/ on 'A' at 0:
    No match |}]

(* ============================================================================
   add-ignoreCase-affects-backreferences.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_affects_backreferences" =
  test_regex
    ((group (cchar 'a')) -- (add_modifiers "i" (!$ 1)))
    "aA"
    0 ();
  [%expect {|
    Regex /(a)(?i:\1)/ on 'aA' at 0:
    Input: aA
    End: 2
    Captures:
    	# 0 : (0,1) |}]

let%expect_test "add_ignoreCase_affects_backreferences_no_match" =
  test_regex
    ((group (cchar 'a')) -- (add_modifiers "i" (!$ 1)))
    "AA"
    0 ();
  [%expect {|
    Regex /(a)(?i:\1)/ on 'AA' at 0:
    No match |}]

(* ============================================================================
   add-ignoreCase-affects-characterClasses.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_affects_characterClasses" =
  test_regex
    (add_modifiers "i" (CharacterClass (NoninvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))))
    "Ac"
    0 ();
  [%expect {|
    Regex /(?i:[ab])/ on 'Ac' at 0:
    Input: Ac
    End: 1
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_affects_negated_characterClasses" =
  test_regex
    (add_modifiers "i" (CharacterClass (InvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- (cchar 'c'))
    "xc"
    0 ();
  [%expect {|
    Regex /(?i:[^ab])c/ on 'xc' at 0:
    Input: xc
    End: 2
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_negated_characterClasses_no_match" =
  test_regex
    (add_modifiers "i" (CharacterClass (InvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- (cchar 'c'))
    "Ac"
    0 ();
  [%expect {|
    Regex /(?i:[^ab])c/ on 'Ac' at 0:
    No match |}]

(* ============================================================================
   add-ignoreCase-affects-characterEscapes.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_affects_hex_escape" =
  test_regex
    (add_modifiers "i" (AtomEsc (ACharacterEsc (HexEscape (Coq_x6, Coq_x1)))) -- (cchar 'b'))
    "Ab"
    0 ();
  [%expect {|
    Regex /(?i:\x61)b/ on 'Ab' at 0:
    Input: Ab
    End: 2
    Captures:
    	None |}]

(* ============================================================================
   add-ignoreCase-affects-slash-lower-b.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_affects_word_boundary" =
  test_regex
    (add_modifiers "i" WordBoundary)
    "A"
    0 ();
  [%expect {|
    Regex /(?i:\b)/ on 'A' at 0:
    Input: A
    End: 0
    Captures:
    	None |}]

(* ============================================================================
   add-ignoreCase-affects-slash-upper-b.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_affects_non_word_boundary" =
  test_regex
    (add_modifiers "i" ((cchar 'Z') -- NotWordBoundary))
    "Z\u{017f}"
    0 ();
  [%expect {|
    Regex /(?i:Z\B)/ on 'Zſ' at 0:
    Input: Zſ
    End: 1
    Captures:
    	None |}]

(* ============================================================================
   add-ignoreCase-affects-slash-lower-w.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_affects_word_characters" =
  test_regex
    (add_modifiers "i" (AtomEsc (ACharacterClassEsc (Coq_esc_w))))
    "A"
    0 ();
  [%expect {|
    Regex /(?i:\w)/ on 'A' at 0:
    Input: A
    End: 1
    Captures:
    	None |}]

(* ============================================================================
   add-ignoreCase-affects-slash-upper-w.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_affects_non_word_characters" =
  test_regex
    (add_modifiers "i" (AtomEsc (ACharacterClassEsc (Coq_esc_W))))
    "\u{017f}"
    0 ();
  [%expect {|
    Regex /(?i:\W)/ on 'ſ' at 0:
    No match |}]

(* ============================================================================
   remove-ignoreCase-affects-characterEscapes.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_affects_hex_escape" =
  test_regex
    (remove_modifiers "" "i" (AtomEsc (ACharacterEsc (HexEscape (Coq_x6, Coq_x1)))) -- (cchar 'b'))
    "ab"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\x61)b/ on 'ab' at 0:
    Input: ab
    End: 2
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_affects_hex_escape_no_match" =
  test_regex
    (remove_modifiers "" "i" (AtomEsc (ACharacterEsc (HexEscape (Coq_x6, Coq_x1)))) -- (cchar 'b'))
    "Ab"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\x61)b/ on 'Ab' at 0:
    No match |}]

(* ============================================================================
   remove-ignoreCase-affects-characterClasses.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_affects_characterClasses" =
  test_regex
    (remove_modifiers "" "i" (CharacterClass (NoninvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- (cchar 'c'))
    "ac"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:[ab])c/ on 'ac' at 0:
    Input: ac
    End: 2
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_affects_characterClasses_no_match" =
  test_regex
    (remove_modifiers "" "i" (CharacterClass (NoninvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- (cchar 'c'))
    "Ac"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:[ab])c/ on 'Ac' at 0:
    No match |}]

let%expect_test "remove_ignoreCase_affects_negated_characterClasses" =
  test_regex
    (remove_modifiers "" "i" (CharacterClass (InvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- (cchar 'c'))
    "Ac"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:[^ab])c/ on 'Ac' at 0:
    Input: Ac
    End: 2
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_negated_characterClasses_no_match" =
  test_regex
    (remove_modifiers "" "i" (CharacterClass (InvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- (cchar 'c'))
    "ac"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:[^ab])c/ on 'ac' at 0:
    No match |}]

(* ============================================================================
   remove-ignoreCase-affects-slash-lower-w.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_affects_word_characters_no_match" =
  test_regex
    (remove_modifiers "" "i" (AtomEsc (ACharacterClassEsc (Coq_esc_w))))
    "\u{017f}"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\w)/ on 'ſ' at 0:
    No match |}]

(* ============================================================================
   remove-ignoreCase-affects-slash-upper-w.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_affects_non_word_characters" =
  test_regex
    (remove_modifiers "" "i" (AtomEsc (ACharacterClassEsc (Coq_esc_W))))
    "\u{017f}"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\W)/ on 'ſ' at 0:
    Input: ſ
    End: 1
    Captures:
    	None |}]

(* ============================================================================
   remove-ignoreCase-affects-slash-lower-b.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_affects_word_boundary_no_match" =
  test_regex
    (remove_modifiers "" "i" WordBoundary)
    "\u{017f}"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\b)/ on 'ſ' at 0:
    No match |}]

(* ============================================================================
   remove-ignoreCase-affects-slash-upper-b.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_affects_non_word_boundary_no_match" =
  test_regex
    (remove_modifiers "" "i" ((cchar 'Z') -- NotWordBoundary))
    "Z\u{017f}"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:Z\B)/ on 'Zſ' at 0:
    No match |}]

(* ============================================================================
   remove-ignoreCase-affects-backreferences.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_affects_backreferences" =
  test_regex
    ((group (cchar 'a')) -- (remove_modifiers "" "i" (!$ 1)))
    "aa"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(a)(?-i:\1)/ on 'aa' at 0:
    Input: aa
    End: 2
    Captures:
    	# 0 : (0,1) |}]

let%expect_test "remove_ignoreCase_affects_backreferences_no_match" =
  test_regex
    ((group (cchar 'a')) -- (remove_modifiers "" "i" (!$ 1)))
    "aA"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(a)(?-i:\1)/ on 'aA' at 0:
    No match |}]

(* ============================================================================
   remove-ignoreCase-affects-slash-lower-p.js
   (Uses Unicode property \p{Lu} which is not implemented in warblre)
   ============================================================================ *)

(* Skip: requires Unicode property \p{Lu} support *)

(* ============================================================================
   remove-ignoreCase-affects-slash-upper-p.js
   (Uses Unicode property \P{Lu} which is not implemented in warblre)
   ============================================================================ *)

(* Skip: requires Unicode property \P{Lu} support *)

(* ============================================================================
   remove-dotAll-does-not-affect-alternatives-outside.js
   ============================================================================ *)

let%expect_test "remove_dotAll_does_not_affect_alternatives_outside" =
  test_regex
    (((cchar 'a') || (cchar 'b') || (remove_modifiers "" "s" (Dot)) || (cchar 'd')))
    "\n"
    0 ~dotAll:true ();
  [%expect {|
    Regex /a|b|(?-s:.)|d/ on '
    ' at 0:
    No match |}]

(* ============================================================================
   remove-dotAll-does-not-affect-ignoreCase-flag.js
   ============================================================================ *)

let%expect_test "remove_dotAll_does_not_affect_ignoreCase_flag" =
  test_regex
    ((remove_modifiers "" "s" (Dot)) -- (cchar 'a'))
    "\nA"
    0 ~dotAll:true ~ignoreCase:true ();
  [%expect {|
    Regex /(?-s:.)a/ on '
    A' at 0:
    No match |}]

(* ============================================================================
   remove-dotAll-does-not-affect-multiline-flag.js
   ============================================================================ *)

let%expect_test "remove_dotAll_does_not_affect_multiline_flag" =
  test_regex
    ((cchar 'a') -- (remove_modifiers "" "s" (Dot)) -- InputEnd)
    "a\n"
    0 ~dotAll:true ~multiline:true ();
  [%expect {|
    Regex /a(?-s:.)$/ on 'a
    ' at 0:
    No match |}]

(* ============================================================================
   remove-ignoreCase-does-not-affect-alternatives-outside.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_does_not_affect_alternatives_outside" =
  test_regex
    (((cchar 'a') || (cchar 'b') || (remove_modifiers "" "i" (cchar 'c')) || (cchar 'd')))
    "C"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /a|b|(?-i:c)|d/ on 'C' at 0:
    No match |}]

(* ============================================================================
   remove-ignoreCase-does-not-affect-dotAll-flag.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_does_not_affect_dotAll_flag" =
  test_regex
    ((remove_modifiers "" "i" (Dot)) -- (cchar 'a'))
    "\na"
    0 ~ignoreCase:true ~dotAll:true ();
  [%expect {|
    Regex /(?-i:.)a/ on '
    a' at 0:
    Input:
    a
    End: 2
    Captures:
    	None |}]

(* ============================================================================
   remove-ignoreCase-does-not-affect-multiline-flag.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_does_not_affect_multiline_flag" =
  test_regex
    (InputStart -- (remove_modifiers "" "i" ((cchar 'a') -- InputEnd)))
    "a\n"
    0 ~ignoreCase:true ~multiline:true ();
  [%expect {|
    Regex /^(?-i:a$)/ on 'a
    ' at 0:
    Input: a

    End: 1
    Captures:
    	None |}]

(* ============================================================================
   remove-multiline-does-not-affect-alternatives-outside.js
   ============================================================================ *)

let%expect_test "remove_multiline_does_not_affect_alternatives_outside" =
  test_regex
    (((cchar 'a') || (cchar 'b') || (remove_modifiers "" "m" ((cchar 'e') -- (cchar 's') -- InputEnd)) || (cchar 'd')))
    "es\ns"
    0 ~multiline:true ();
  [%expect {|
    Regex /a|b|(?-m:es$)|d/ on 'es
    s' at 0:
    No match |}]

(* ============================================================================
   remove-multiline-does-not-affect-dotAll-flag.js
   ============================================================================ *)

let%expect_test "remove_multiline_does_not_affect_dotAll_flag" =
  test_regex
    ((cchar 'a') -- Dot -- (remove_modifiers "" "m" ((cchar 'e') -- (cchar 's') -- InputEnd)))
    "a\nes\ns"
    0 ~multiline:true ~dotAll:true ();
  [%expect {|
    Regex /a.(?-m:es$)/ on 'a
    es
    s' at 0:
    No match |}]

(* ============================================================================
   remove-multiline-does-not-affect-ignoreCase-flag.js
   ============================================================================ *)

let%expect_test "remove_multiline_does_not_affect_ignoreCase_flag" =
  test_regex
    ((cchar 'A') -- (remove_modifiers "" "m" ((cchar 'e') -- (cchar 's') -- InputEnd)))
    "AES\n"
    0 ~multiline:true ~ignoreCase:true ();
  [%expect {|
    Regex /A(?-m:es$)/ on 'AES
    ' at 0:
    No match |}]

(* ============================================================================
   nesting-remove-dotAll-within-add-dotAll.js
   ============================================================================ *)

let%expect_test "nesting_remove_dotAll_within_add_dotAll" =
  test_regex
    (add_modifiers "s" (remove_modifiers "" "s" (InputStart -- Dot -- InputEnd)))
    "\n"
    0 ();
  [%expect {|
    Regex /(?s:(?-s:^.$))/ on '
    ' at 0:
    No match |}]

(* ============================================================================
   nesting-remove-ignoreCase-within-add-ignoreCase.js
   ============================================================================ *)

let%expect_test "nesting_remove_ignoreCase_within_add_ignoreCase" =
  test_regex
    ((add_modifiers "i" (remove_modifiers "" "i" ((cchar 'a') -- (cchar 'b')))) -- (cchar 'c'))
    "abc"
    0 ();
  [%expect {|
    Regex /(?i:(?-i:ab))c/ on 'abc' at 0:
    Input: abc
    End: 3
    Captures:
    	None |}]

let%expect_test "nesting_remove_ignoreCase_within_add_ignoreCase_no_match" =
  test_regex
    ((add_modifiers "i" (remove_modifiers "" "i" ((cchar 'a') -- (cchar 'b')))) -- (cchar 'c'))
    "ABc"
    0 ();
  [%expect {|
    Regex /(?i:(?-i:ab))c/ on 'ABc' at 0:
    No match |}]

(* ============================================================================
   nesting-remove-multiline-within-add-multiline.js
   ============================================================================ *)

let%expect_test "nesting_remove_multiline_within_add_multiline" =
  test_regex
    ((add_modifiers "m" (remove_modifiers "" "m" ((cchar 'e') -- (cchar 's') -- InputEnd))) || ((cchar 'j') -- (cchar 's')))
    "js"
    0 ();
  [%expect {|
    Regex /(?m:(?-m:es$))|js/ on 'js' at 0:
    Input: js
    End: 2
    Captures:
    	None |}]

(* ============================================================================
   add-multiline-does-not-affect-alternatives-outside.js
   ============================================================================ *)

let%expect_test "add_multiline_does_not_affect_alternatives_outside" =
  test_regex
    (((cchar 'a') || (add_modifiers "m" ((cchar 'e') -- (cchar 's') -- InputEnd)) || (cchar 'd')))
    "es\ns"
    0 ();
  [%expect {|
    Regex /a|(?m:es$)|d/ on 'es
    s' at 0:
    Input: es
    s
    End: 2
    Captures:
    	None |}]

(* ============================================================================
   add-multiline-does-not-affect-dotAll-flag.js
   ============================================================================ *)

let%expect_test "add_multiline_does_not_affect_dotAll_flag" =
  test_regex
    ((cchar 'a') -- (add_modifiers "m" ((cchar 'e') -- (cchar 's') -- InputEnd)))
    "aes\ns"
    0 ~dotAll:true ();
  [%expect {|
    Regex /a(?m:es$)/ on 'aes
    s' at 0:
    Input: aes
    s
    End: 3
    Captures:
    	None |}]

(* ============================================================================
   add-multiline-does-not-affect-ignoreCase-flag.js
   ============================================================================ *)

let%expect_test "add_multiline_does_not_affect_ignoreCase_flag" =
  test_regex
    ((ichar 65) -- (add_modifiers "m" ((ichar 69) -- (ichar 83) -- InputEnd)))
    "AES\ns"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /A(?m:ES$)/ on 'AES
    s' at 0:
    Input: AES
    s
    End: 3
    Captures:
    	None |}]

(* ============================================================================
   add-multiline-does-not-affect-multiline-property.js
   ============================================================================ *)

let%expect_test "add_multiline_does_not_affect_multiline_property" =
  test_regex
    (add_modifiers "m" ((cchar 'e') -- (cchar 's') -- InputEnd))
    "es"
    0 ();
  [%expect {|
    Regex /(?m:es$)/ on 'es' at 0:
    Input: es
    End: 2
    Captures:
    	None |}]

(* ============================================================================
   add-dotAll-does-not-affect-alternatives-outside.js
   ============================================================================ *)

let%expect_test "add_dotAll_does_not_affect_alternatives_outside" =
  test_regex
    (((cchar 'a') || (add_modifiers "s" (Dot)) || (cchar 'd')))
    "\n"
    0 ();
  [%expect {|
    Regex /a|(?s:.)|d/ on '
    ' at 0:
    Input:

    End: 1
    Captures:
    	None |}]

(* ============================================================================
   add-dotAll-does-not-affect-dotAll-property.js
   ============================================================================ *)

let%expect_test "add_dotAll_does_not_affect_dotAll_property" =
  test_regex
    (add_modifiers "s" (Dot))
    "a"
    0 ();
  [%expect {|
    Regex /(?s:.)/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

(* ============================================================================
   add-dotAll-does-not-affect-ignoreCase-flag.js
   ============================================================================ *)

let%expect_test "add_dotAll_does_not_affect_ignoreCase_flag" =
  test_regex
    ((ichar 65) -- (add_modifiers "s" (Dot)))
    "A\n"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /A(?s:.)/ on 'A
    ' at 0:
    Input: A

    End: 2
    Captures:
    	None |}]

(* ============================================================================
   add-dotAll-does-not-affect-multiline-flag.js
   ============================================================================ *)

let%expect_test "add_dotAll_does_not_affect_multiline_flag" =
  test_regex
    ((cchar 'a') -- InputEnd -- (add_modifiers "s" (Dot)) -- InputEnd)
    "a\n"
    0 ~multiline:true ();
  [%expect {|
    Regex /a$(?s:.)$/ on 'a
    ' at 0:
    Input: a

    End: 2
    Captures:
    	None |}]

(* ============================================================================
   add-ignoreCase-does-not-affect-dotAll-flag.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_does_not_affect_dotAll_flag" =
  test_regex
    ((cchar 'a') -- (add_modifiers "i" (cchar 'b')))
    "ab"
    0 ~dotAll:true ();
  [%expect {|
    Regex /a(?i:b)/ on 'ab' at 0:
    Input: ab
    End: 2
    Captures:
    	None |}]

(* ============================================================================
   add-ignoreCase-does-not-affect-ignoreCase-property.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_does_not_affect_ignoreCase_property" =
  test_regex
    (add_modifiers "i" (cchar 'a'))
    "A"
    0 ();
  [%expect {|
    Regex /(?i:a)/ on 'A' at 0:
    Input: A
    End: 1
    Captures:
    	None |}]

(* ============================================================================
   add-ignoreCase-does-not-affect-multiline-flag.js
   ============================================================================ *)

let%expect_test "add_ignoreCase_does_not_affect_multiline_flag" =
  test_regex
    ((cchar 'a') -- InputEnd -- (add_modifiers "i" (cchar 'b')))
    "ab"
    0 ~multiline:true ();
  [%expect {|
    Regex /a$(?i:b)/ on 'ab' at 0:
    No match |}]

(* ============================================================================
   changing-ignoreCase-flag-does-not-affect-ignoreCase-modifier.js
   ============================================================================ *)

let%expect_test "changing_ignoreCase_flag_does_not_affect_ignoreCase_modifier" =
  test_regex
    ((cchar 'a') -- (add_modifiers "i" (cchar 'b')))
    "Ab"
    0 ();
  [%expect {|
    Regex /a(?i:b)/ on 'Ab' at 0:
    No match |}]

(* ============================================================================
   changing-multiline-flag-does-not-affect-multiline-modifier.js
   ============================================================================ *)

let%expect_test "changing_multiline_flag_does_not_affect_multiline_modifier" =
  test_regex
    ((cchar 'a') -- (add_modifiers "m" ((cchar 'e') -- (cchar 's') -- InputEnd)))
    "aes\ns"
    0 ();
  [%expect {|
    Regex /a(?m:es$)/ on 'aes
    s' at 0:
    Input: aes
    s
    End: 3
    Captures:
    	None |}]

(* ============================================================================
   changing-dotAll-flag-does-not-affect-dotAll-modifier.js
   ============================================================================ *)

let%expect_test "changing_dotAll_flag_does_not_affect_dotAll_modifier" =
  test_regex
    ((cchar 'a') -- (add_modifiers "s" (Dot)))
    "a\n"
    0 ();
  [%expect {|
    Regex /a(?s:.)/ on 'a
    ' at 0:
    Input: a

    End: 2
    Captures:
    	None |}]

(* ============================================================================
   remove-dotAll-does-not-affect-dotAll-property.js
   ============================================================================ *)

let%expect_test "remove_dotAll_does_not_affect_dotAll_property" =
  test_regex
    (remove_modifiers "" "s" (Dot))
    "a"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:.)/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

(* ============================================================================
   remove-multiline-does-not-affect-multiline-property.js
   ============================================================================ *)

let%expect_test "remove_multiline_does_not_affect_multiline_property" =
  test_regex
    (remove_modifiers "" "m" ((cchar 'e') -- (cchar 's') -- InputEnd))
    "es"
    0 ~multiline:true ();
  [%expect {|
    Regex /(?-m:es$)/ on 'es' at 0:
    Input: es
    End: 2
    Captures:
    	None |}]

(* ============================================================================
   remove-ignoreCase-does-not-affect-ignoreCase-property.js
   ============================================================================ *)

let%expect_test "remove_ignoreCase_does_not_affect_ignoreCase_property" =
  test_regex
    (remove_modifiers "" "i" (cchar 'a'))
    "A"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:a)/ on 'A' at 0:
    No match |}]

(* ============================================================================
   nesting-dotAll-does-not-affect-alternatives-outside.js
   ============================================================================ *)

let%expect_test "nesting_dotAll_does_not_affect_alternatives_outside" =
  test_regex
    (((cchar 'a') || (remove_modifiers "" "s" (add_modifiers "s" (Dot))) || (cchar 'd')))
    "\n"
    0 ~dotAll:true ();
  [%expect {|
    Regex /a|(?-s:(?s:.))|d/ on '
    ' at 0:
    Input:

    End: 1
    Captures:
    	None |}]

(* ============================================================================
   nesting-multiline-does-not-affect-alternatives-outside.js
   ============================================================================ *)

let%expect_test "nesting_multiline_does_not_affect_alternatives_outside" =
  test_regex
    (((cchar 'a') || (remove_modifiers "" "m" (add_modifiers "m" ((cchar 'e') -- (cchar 's') -- InputEnd))) || (cchar 'd')))
    "es\ns"
    0 ~multiline:true ();
  [%expect {|
    Regex /a|(?-m:(?m:es$))|d/ on 'es
    s' at 0:
    Input: es
    s
    End: 2
    Captures:
    	None |}]

(* ============================================================================
   nesting-ignoreCase-does-not-affect-alternatives-outside.js
   ============================================================================ *)

let%expect_test "nesting_ignoreCase_does_not_affect_alternatives_outside" =
  test_regex
    (((cchar 'a') || (remove_modifiers "" "i" (add_modifiers "i" (cchar 'c'))) || (cchar 'd')))
    "C"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /a|(?-i:(?i:c))|d/ on 'C' at 0:
    Input: C
    End: 1
    Captures:
    	None |}]

(* ============================================================================
   add-and-remove-modifiers.js
   ============================================================================ *)

let%expect_test "add_and_remove_modifiers" =
  test_regex
    (remove_modifiers "is" "m" ((cchar 'a') -- Dot -- InputEnd))
    "a\n"
    0 ~multiline:true ();
  [%expect {|
    Regex /(?is-m:a.$)/ on 'a
    ' at 0:
    Input: a

    End: 2
    Captures:
    	None |}]

(* ============================================================================
   add-and-remove-modifiers-can-have-empty-remove-modifiers.js
   ============================================================================ *)

let%expect_test "add_and_remove_modifiers_can_have_empty_remove_modifiers" =
  test_regex
    (remove_modifiers "i" "" (cchar 'a'))
    "A"
    0 ();
  [%expect {|
    Regex /(?i-:a)/ on 'A' at 0:
    Input: A
    End: 1
    Captures:
    	None |}]
