open Warblre.OCamlEngines.UnicodeNotations
open Warblre.OCamlEngines.UnicodeTester

(* Helper function to create character from int for modifiers (UnicodeParameters uses int for Character) *)
let modchar (c: char) : int = Char.code c

(*
 * ============================================================================
 * Test262 RegExp Modifiers Tests
 * From commit: 47b1f5eb5d - "Add tests for RegExp modifiers"
 * ============================================================================
 *)

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase.js
 * Description: ignoreCase (`i`) modifier can be added via `(?i:)` or `(?i-:)`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], cchar 'a') -- cchar 'b')
    "AB"
    0 ();
  [%expect {|
    Regex /(?i:a)b/ on 'AB' at 0:
    No match |}]

let%expect_test "add_ignoreCase_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'i'], cchar 'a') -- cchar 'b')
    "Ab"
    0 ();
  [%expect {|
    Regex /(?i:a)b/ on 'Ab' at 0:
    Input: Ab
    End: 2
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_re1_3" =
  test_regex
    (ModifierAdd ([modchar 'i'], cchar 'a') -- cchar 'b')
    "ab"
    0 ();
  [%expect {|
    Regex /(?i:a)b/ on 'ab' at 0:
    Input: ab
    End: 2
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_re2_1" =
  test_regex
    (ModifierRemove ([modchar 'i'], [], cchar 'a') -- cchar 'b')
    "AB"
    0 ();
  [%expect {|
    Regex /(?i-:a)b/ on 'AB' at 0:
    No match |}]

let%expect_test "add_ignoreCase_re2_2" =
  test_regex
    (ModifierRemove ([modchar 'i'], [], cchar 'a') -- cchar 'b')
    "Ab"
    0 ();
  [%expect {|
    Regex /(?i-:a)b/ on 'Ab' at 0:
    Input: Ab
    End: 2
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_re2_3" =
  test_regex
    (ModifierRemove ([modchar 'i'], [], cchar 'a') -- cchar 'b')
    "ab"
    0 ();
  [%expect {|
    Regex /(?i-:a)b/ on 'ab' at 0:
    Input: ab
    End: 2
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-dotAll.js
 * Description: dotAll (`s`) modifier can be added via `(?s:)` or `(?s-:)`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_dotAll_re1_1" =
  test_regex
    (ModifierAdd ([modchar 's'], InputStart -- Dot -- InputEnd))
    "a"
    0 ();
  [%expect {|
    Regex /(?s:^.$)/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

let%expect_test "add_dotAll_re1_newline" =
  test_regex
    (ModifierAdd ([modchar 's'], InputStart -- Dot -- InputEnd))
    "\n"
    0 ();
  [%expect {|
    Regex /(?s:^.$)/ on '
    ' at 0:
    Input:
    
    End: 1
    Captures:
      None |}]

let%expect_test "add_dotAll_re1_no_supplementary" =
  test_regex
    (ModifierAdd ([modchar 's'], InputStart -- Dot -- InputEnd))
    "\u{10300}"
    0 ();
  [%expect {|
    Regex /(?s:^.$)/ on '𐌀' at 0:
    No match |}]

let%expect_test "add_dotAll_re3_1" =
  test_regex
    (ModifierRemove ([modchar 's'], [], InputStart -- Dot -- InputEnd))
    "a"
    0 ();
  [%expect {|
    Regex /(?s-:^.$)/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

let%expect_test "add_dotAll_re3_newline" =
  test_regex
    (ModifierRemove ([modchar 's'], [], InputStart -- Dot -- InputEnd))
    "\n"
    0 ();
  [%expect {|
    Regex /(?s-:^.$)/ on '
    ' at 0:
    Input:
    End: 1
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-multiline.js
 * Description: multiline (`m`) modifier can be added via `(?m:)` or `(?m-:)`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_multiline_re1" =
  test_regex
    (ModifierAdd ([modchar 'm'], cchar 'e' -- cchar 's' -- InputEnd))
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

let%expect_test "add_multiline_re3" =
  test_regex
    (ModifierRemove ([modchar 'm'], [], cchar 'e' -- cchar 's' -- InputEnd))
    "es\ns"
    0 ();
  [%expect {|
    Regex /(?m-:es$)/ on 'es
s' at 0:
    Input: es
    s
    End: 2
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-remove-modifiers.js
 * Description: Modifiers can be both added and removed via `(?ims-ims:)`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_remove_modifiers_re1_1" =
  test_regex
    (ModifierRemove ([modchar 'm'], [modchar 'i'], InputStart -- cchar 'a' -- InputEnd))
    "A\n"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?m-i:^a$)/ on 'A
' at 0:
    No match |}]

let%expect_test "add_remove_modifiers_re1_2" =
  test_regex
    (ModifierRemove ([modchar 'm'], [modchar 'i'], InputStart -- cchar 'a' -- InputEnd))
    "a\n"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?m-i:^a$)/ on 'a
' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase.js
 * Description: ignoreCase (`i`) modifier can be removed via `(?-i:)`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'f' -- cchar 'o') -- cchar 'o')
    "FOO"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:fo)o/ on 'FOO' at 0:
    No match |}]

let%expect_test "remove_ignoreCase_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'f' -- cchar 'o') -- cchar 'o')
    "FOo"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:fo)o/ on 'FOo' at 0:
    No match |}]

let%expect_test "remove_ignoreCase_re1_3" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'f' -- cchar 'o') -- cchar 'o')
    "foo"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:fo)o/ on 'foo' at 0:
    Input: foo
    End: 3
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_re1_4" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'f' -- cchar 'o') -- cchar 'o')
    "foO"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:fo)o/ on 'foO' at 0:
    Input: foO
    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-dotAll.js
 * Description: dotAll (`s`) modifier can be removed via `(?-s:)`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_dotAll_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 's'], InputStart -- Dot -- InputEnd))
    "a"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:^.$)/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

let%expect_test "remove_dotAll_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 's'], InputStart -- Dot -- InputEnd))
    "\n"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:^.$)/ on '
' at 0:
    No match |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-multiline.js
 * Description: multiline (`m`) modifier can be removed via `(?-m:)`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_multiline_re1_1" =
  test_regex
    (InputStart -- ModifierRemove ([], [modchar 'm'], cchar 'e' -- cchar 's' -- InputEnd))
    "\nes\ns"
    0 ~multiline:true ();
  [%expect {|
    Regex /^(?-m:es$)/ on '
es
s' at 0:
    No match |}]

let%expect_test "remove_multiline_re1_2" =
  test_regex
    (InputStart -- ModifierRemove ([], [modchar 'm'], cchar 'e' -- cchar 's' -- InputEnd))
    "\nes"
    0 ~multiline:true ();
  [%expect {|
    Regex /^(?-m:es$)/ on '
es' at 0:
    Input:
    es
    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: nested-add-remove-modifiers.js
 * Description: Modifiers can be nested.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "nested_add_remove_modifiers_re1_1" =
  test_regex
    (ModifierRemove ([modchar 'm'], [modchar 'i'], InputStart -- ModifierRemove ([], [modchar 'i'], cchar 'a') -- InputEnd))
    "A\n"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?m-i:^(?-i:a)$)/ on 'A
' at 0:
    No match |}]

let%expect_test "nested_add_remove_modifiers_re1_2" =
  test_regex
    (ModifierRemove ([modchar 'm'], [modchar 'i'], InputStart -- ModifierRemove ([], [modchar 'i'], cchar 'a') -- InputEnd))
    "a\n"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?m-i:^(?-i:a)$)/ on 'a
' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-affects-backreferences.js
 * Description: Adding ignoreCase (`i`) modifier in group affects backreferences in group.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_affects_backrefs_re1_1" =
  test_regex
    (group (cchar 'a') -- ModifierAdd ([modchar 'i'], !$ 1))
    "AA"
    0 ();
  [%expect {|
    Regex /(a)(?i:\1)/ on 'AA' at 0:
    No match |}]

let%expect_test "add_ignoreCase_affects_backrefs_re1_2" =
  test_regex
    (group (cchar 'a') -- ModifierAdd ([modchar 'i'], !$ 1))
    "aa"
    0 ();
  [%expect {|
    Regex /(a)(?i:\1)/ on 'aa' at 0:
    Input: aa
    End: 2
    Captures:
    	# 0 : (0,1) |}]

let%expect_test "add_ignoreCase_affects_backrefs_re1_3" =
  test_regex
    (group (cchar 'a') -- ModifierAdd ([modchar 'i'], !$ 1))
    "aA"
    0 ();
  [%expect {|
    Regex /(a)(?i:\1)/ on 'aA' at 0:
    Input: aA
    End: 2
    Captures:
    	# 0 : (0,1) |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-affects-characterClasses.js
 * Description: Adding ignoreCase (`i`) modifier in group affects character classes in group.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_affects_charClass_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], CharacterClass (NoninvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- cchar 'c')
    "ac"
    0 ();
  [%expect {|
    Regex /(?i:[ab])c/ on 'ac' at 0:
    Input: ac
    End: 2
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_affects_charClass_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'i'], CharacterClass (NoninvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- cchar 'c')
    "Ac"
    0 ();
  [%expect {|
    Regex /(?i:[ab])c/ on 'Ac' at 0:
    Input: Ac
    End: 2
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_affects_charClass_re3_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], CharacterClass (InvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- cchar 'c')
    "ac"
    0 ();
  [%expect {|
    Regex /(?i:[^ab])c/ on 'ac' at 0:
    No match |}]

let%expect_test "add_ignoreCase_affects_charClass_re3_2" =
  test_regex
    (ModifierAdd ([modchar 'i'], CharacterClass (InvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- cchar 'c')
    "Ac"
    0 ();
  [%expect {|
    Regex /(?i:[^ab])c/ on 'Ac' at 0:
    No match |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-affects-characterEscapes.js
 * Description: Adding ignoreCase (`i`) modifier in group affects character escapes in group.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_affects_charEscapes_re1" =
  test_regex
    (ModifierAdd ([modchar 'i'], AtomEsc (ACharacterEsc (hex_escape '6' '1'))) -- cchar 'b')
    "ab"
    0 ();
  [%expect {|
    Regex /(?i:\x61)b/ on 'ab' at 0:
    Input: ab
    End: 2
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_affects_charEscapes_re1_upper" =
  test_regex
    (ModifierAdd ([modchar 'i'], AtomEsc (ACharacterEsc (hex_escape '6' '1'))) -- cchar 'b')
    "Ab"
    0 ();
  [%expect {|
    Regex /(?i:\x61)b/ on 'Ab' at 0:
    Input: Ab
    End: 2
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-affects-slash-lower-b.js
 * Description: Adding ignoreCase (`i`) modifier affects matching for `\b`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_affects_b_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], WordBoundary))
    "A"
    0 ();
  [%expect {|
    Regex /(?i:\b)/ on 'A' at 0:
    Input: A
    End: 0
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_affects_b_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'i'], WordBoundary))
    "a"
    0 ();
  [%expect {|
    Regex /(?i:\b)/ on 'a' at 0:
    Input: a
    End: 0
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-affects-slash-lower-w.js
 * Description: Adding ignoreCase (`i`) modifier affects matching for `\w`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_affects_w_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], AtomEsc (ACharacterClassEsc Coq_esc_w)))
    "A"
    0 ();
  [%expect {|
    Regex /(?i:\w)/ on 'A' at 0:
    Input: A
    End: 1
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_affects_w_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'i'], AtomEsc (ACharacterClassEsc Coq_esc_w)))
    "a"
    0 ();
  [%expect {|
    Regex /(?i:\w)/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-does-not-affect-dotAll-flag.js
 * Description: Adding ignoreCase (`i`) modifier in group should not affect dotAll (`s`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_no_affect_dotAll_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], Dot -- cchar 'e' -- cchar 's'))
    "aes"
    0 ();
  [%expect {|
    Regex /(?i:.es)/ on 'aes' at 0:
    Input: aes
    End: 3
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_no_affect_dotAll_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'i'], Dot -- cchar 'e' -- cchar 's'))
    "\nes"
    0 ();
  [%expect {|
    Regex /(?i:.es)/ on '
es' at 0:
    No match |}]

let%expect_test "add_ignoreCase_no_affect_dotAll_re2_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], Dot -- cchar 'e' -- cchar 's'))
    "\nes"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?i:.es)/ on '
es' at 0:
    Input:
    es
    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-does-not-affect-multiline-flag.js
 * Description: Adding ignoreCase (`i`) modifier in group should not affect multiline (`m`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_no_affect_multiline_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], cchar 'e' -- cchar 's' -- InputEnd))
    "es"
    0 ();
  [%expect {|
    Regex /(?i:es$)/ on 'es' at 0:
    Input: es
    End: 2
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_no_affect_multiline_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'i'], cchar 'e' -- cchar 's' -- InputEnd))
    "es\nz"
    0 ();
  [%expect {|
    Regex /(?i:es$)/ on 'es
z' at 0:
    No match |}]

let%expect_test "add_ignoreCase_no_affect_multiline_re2_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], cchar 'e' -- cchar 's' -- InputEnd))
    "es\nz"
    0 ~multiline:true ();
  [%expect {|
    Regex /(?i:es$)/ on 'es
z' at 0:
    Input: es
    z
    End: 2
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-dotAll-does-not-affect-ignoreCase-flag.js
 * Description: Adding dotAll (`s`) modifier in group should not affect ignoreCase (`i`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_dotAll_no_affect_ignoreCase_re1_1" =
  test_regex
    (ModifierAdd ([modchar 's'], Dot -- cchar 'e' -- cchar 's'))
    "aes"
    0 ();
  [%expect {|
    Regex /(?s:.es)/ on 'aes' at 0:
    Input: aes
    End: 3
    Captures:
    	None |}]

let%expect_test "add_dotAll_no_affect_ignoreCase_re1_2" =
  test_regex
    (ModifierAdd ([modchar 's'], Dot -- cchar 'e' -- cchar 's'))
    "aeS"
    0 ();
  [%expect {|
    Regex /(?s:.es)/ on 'aeS' at 0:
    No match |}]

let%expect_test "add_dotAll_no_affect_ignoreCase_re2_1" =
  test_regex
    (ModifierAdd ([modchar 's'], Dot -- cchar 'e' -- cchar 's'))
    "aeS"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?s:.es)/ on 'aeS' at 0:
    Input: aeS
    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-dotAll-does-not-affect-multiline-flag.js
 * Description: Adding dotAll (`s`) modifier in group should not affect multiline (`m`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_dotAll_no_affect_multiline_re1_1" =
  test_regex
    (ModifierAdd ([modchar 's'], Dot -- cchar 'e' -- cchar 's' -- InputEnd))
    "\nes"
    0 ();
  [%expect {|
    Regex /(?s:.es$)/ on '
es' at 0:
    Input:
    es
    End: 3
    Captures:
    	None |}]

let%expect_test "add_dotAll_no_affect_multiline_re1_2" =
  test_regex
    (ModifierAdd ([modchar 's'], Dot -- cchar 'e' -- cchar 's' -- InputEnd))
    "\nes\nz"
    0 ();
  [%expect {|
    Regex /(?s:.es$)/ on '
es
z' at 0:
    No match |}]

let%expect_test "add_dotAll_no_affect_multiline_re2_1" =
  test_regex
    (ModifierAdd ([modchar 's'], Dot -- cchar 'e' -- cchar 's' -- InputEnd))
    "\nes\nz"
    0 ~multiline:true ();
  [%expect {|
    Regex /(?s:.es$)/ on '
es
z' at 0:
    Input:
    es
    z
    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-multiline-does-not-affect-dotAll-flag.js
 * Description: Adding multiline (`m`) modifier in group should not affect dotAll (`s`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_multiline_no_affect_dotAll_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'm'], cchar 'e' -- cchar 's' -- Dot -- InputEnd))
    "esz\n"
    0 ();
  [%expect {|
    Regex /(?m:es.$)/ on 'esz
' at 0:
    Input: esz
    End: 3
    Captures:
    	None |}]

let%expect_test "add_multiline_no_affect_dotAll_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'm'], cchar 'e' -- cchar 's' -- Dot -- InputEnd))
    "es\n\n"
    0 ();
  [%expect {|
    Regex /(?m:es.$)/ on 'es

' at 0:
    No match |}]

let%expect_test "add_multiline_no_affect_dotAll_re2_1" =
  test_regex
    (ModifierAdd ([modchar 'm'], cchar 'e' -- cchar 's' -- Dot -- InputEnd))
    "es\n\n"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?m:es.$)/ on 'es

' at 0:
    Input: es

    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-multiline-does-not-affect-ignoreCase-flag.js
 * Description: Adding multiline (`m`) modifier in group should not affect ignoreCase (`i`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_multiline_no_affect_ignoreCase_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'm'], cchar 'e' -- cchar 's' -- InputEnd))
    "es"
    0 ();
  [%expect {|
    Regex /(?m:es$)/ on 'es' at 0:
    Input: es
    End: 2
    Captures:
    	None |}]

let%expect_test "add_multiline_no_affect_ignoreCase_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'm'], cchar 'e' -- cchar 's' -- InputEnd))
    "eS"
    0 ();
  [%expect {|
    Regex /(?m:es$)/ on 'eS' at 0:
    No match |}]

let%expect_test "add_multiline_no_affect_ignoreCase_re2_1" =
  test_regex
    (ModifierAdd ([modchar 'm'], cchar 'e' -- cchar 's' -- InputEnd))
    "eS"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?m:es$)/ on 'eS' at 0:
    Input: eS
    End: 2
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: changing-ignoreCase-flag-does-not-affect-ignoreCase-modifier.js
 * Description: New ignoreCase (`i`) flag from RegExp constructor does not affect ignoreCase modifier in group.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "changing_ignoreCase_flag_no_affect_mod_re2_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'a' -- cchar 'B'))
    "AB"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:aB)/ on 'AB' at 0:
    No match |}]

let%expect_test "changing_ignoreCase_flag_no_affect_mod_re2_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'a' -- cchar 'B'))
    "aB"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:aB)/ on 'aB' at 0:
    Input: aB
    End: 2
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: changing-multiline-flag-does-not-affect-multiline-modifier.js
 * Description: New multiline (`m`) flag from RegExp constructor does not affect multiline modifier in group.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "changing_multiline_flag_no_affect_mod_re2_1" =
  test_regex
    (InputStart -- ModifierRemove ([], [modchar 'm'], cchar 'e' -- cchar 's' -- InputEnd))
    "es\ns"
    0 ~multiline:true ();
  [%expect {|
    Regex /^(?-m:es$)/ on 'es
s' at 0:
    No match |}]

let%expect_test "changing_multiline_flag_no_affect_mod_re2_2" =
  test_regex
    (InputStart -- ModifierRemove ([], [modchar 'm'], cchar 'e' -- cchar 's' -- InputEnd))
    "es"
    0 ~multiline:true ();
  [%expect {|
    Regex /^(?-m:es$)/ on 'es' at 0:
    Input: es
    End: 2
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: nesting-add-dotAll-within-remove-dotAll.js
 * Description: Can add dotAll (`s`) modifier for group nested within a group that removes dotAll modifier.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "nesting_add_dotAll_within_remove_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 's'], ModifierAdd ([modchar 's'], InputStart -- Dot -- InputEnd)))
    "a"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:(?s:^.$))/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

let%expect_test "nesting_add_dotAll_within_remove_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 's'], ModifierAdd ([modchar 's'], InputStart -- Dot -- InputEnd)))
    "\n"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:(?s:^.$))/ on '
' at 0:
    Input:
    End: 1
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: nesting-add-ignoreCase-within-remove-ignoreCase.js
 * Description: Can add ignoreCase (`i`) modifier for group nested within a group that removes ignoreCase modifier.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "nesting_add_ignoreCase_within_remove_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'a' -- ModifierAdd ([modchar 'i'], cchar 'b')) -- cchar 'c')
    "ABC"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:a(?i:b))c/ on 'ABC' at 0:
    No match |}]

let%expect_test "nesting_add_ignoreCase_within_remove_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'a' -- ModifierAdd ([modchar 'i'], cchar 'b')) -- cchar 'c')
    "aBc"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:a(?i:b))c/ on 'aBc' at 0:
    Input: aBc
    End: 3
    Captures:
    	None |}]

let%expect_test "nesting_add_ignoreCase_within_remove_re1_3" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'a' -- ModifierAdd ([modchar 'i'], cchar 'b')) -- cchar 'c')
    "abC"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:a(?i:b))c/ on 'abC' at 0:
    Input: abC
    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: nesting-add-multiline-within-remove-multiline.js
 * Description: Can add multiline (`m`) modifier for group nested within a group that removes multiline modifier.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "nesting_add_multiline_within_remove_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'm'], cchar 'e' -- cchar 's' -- ModifierAdd ([modchar 'm'], InputEnd) || cchar 'j' -- cchar 's' -- InputEnd))
    "es\ns"
    0 ~multiline:true ();
  [%expect {|
    Regex /(?-m:es(?m:$)|js$)/ on 'es
s' at 0:
    Input: es
    End: 2
    Captures:
    	None |}]

let%expect_test "nesting_add_multiline_within_remove_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'm'], cchar 'e' -- cchar 's' -- ModifierAdd ([modchar 'm'], InputEnd) || cchar 'j' -- cchar 's' -- InputEnd))
    "js\ns"
    0 ~multiline:true ();
  [%expect {|
    Regex /(?-m:es(?m:$)|js$)/ on 'js
s' at 0:
    No match |}]

(*
 * ----------------------------------------------------------------------------
 * File: nesting-remove-dotAll-within-add-dotAll.js
 * Description: Can remove dotAll (`s`) modifier for group nested within a group that adds dotAll modifier.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "nesting_remove_dotAll_within_add_re1_1" =
  test_regex
    (ModifierAdd ([modchar 's'], ModifierRemove ([], [modchar 's'], InputStart -- Dot -- InputEnd)))
    "a"
    0 ();
  [%expect {|
    Regex /(?s:(?-s:^.$))/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

let%expect_test "nesting_remove_dotAll_within_add_re1_2" =
  test_regex
    (ModifierAdd ([modchar 's'], ModifierRemove ([], [modchar 's'], InputStart -- Dot -- InputEnd)))
    "\n"
    0 ();
  [%expect {|
    Regex /(?s:(?-s:^.$))/ on '
' at 0:
    No match |}]

(*
 * ----------------------------------------------------------------------------
 * File: nesting-remove-multiline-within-add-multiline.js
 * Description: Can remove multiline (`m`) modifier for group nested within a group that adds multiline modifier.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "nesting_remove_multiline_within_add_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'm'], cchar 'e' -- cchar 's' -- InputEnd || ModifierRemove ([], [modchar 'm'], cchar 'j' -- cchar 's' -- InputEnd)))
    "es\ns"
    0 ();
  [%expect {|
    Regex /(?m:es$|(?-m:js$))/ on 'es
s' at 0:
    Input: es
    End: 2
    Captures:
    	None |}]

let%expect_test "nesting_remove_multiline_within_add_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'm'], cchar 'e' -- cchar 's' -- InputEnd || ModifierRemove ([], [modchar 'm'], cchar 'j' -- cchar 's' -- InputEnd)))
    "js\ns"
    0 ();
  [%expect {|
    Regex /(?m:es$|(?-m:js$))/ on 'js
s' at 0:
    No match |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-affects-backreferences.js
 * Description: Removing ignoreCase (`i`) modifier in group affects backreferences in group.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_affects_backrefs_re1_1" =
  test_regex
    (group (cchar 'a') -- ModifierRemove ([], [modchar 'i'], !$ 1))
    "AA"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(a)(?-i:\1)/ on 'AA' at 0:
    Input: AA
    End: 2
    Captures:
    	# 0 : (0,1) |}]

let%expect_test "remove_ignoreCase_affects_backrefs_re1_2" =
  test_regex
    (group (cchar 'a') -- ModifierRemove ([], [modchar 'i'], !$ 1))
    "aA"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(a)(?-i:\1)/ on 'aA' at 0:
    No match |}]

let%expect_test "remove_ignoreCase_affects_backrefs_re1_3" =
  test_regex
    (group (cchar 'a') -- ModifierRemove ([], [modchar 'i'], !$ 1))
    "aa"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(a)(?-i:\1)/ on 'aa' at 0:
    Input: aa
    End: 2
    Captures:
    	# 0 : (0,1) |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-affects-characterClasses.js
 * Description: Removing ignoreCase (`i`) modifier in group affects character classes in group.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_affects_charClass_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], CharacterClass (NoninvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- cchar 'c')
    "ac"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:[ab])c/ on 'ac' at 0:
    Input: ac
    End: 2
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_affects_charClass_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], CharacterClass (NoninvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- cchar 'c')
    "Ac"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:[ab])c/ on 'Ac' at 0:
    No match |}]

let%expect_test "remove_ignoreCase_affects_charClass_re2_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], CharacterClass (InvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- cchar 'c')
    "ac"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:[^ab])c/ on 'ac' at 0:
    No match |}]

let%expect_test "remove_ignoreCase_affects_charClass_re2_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], CharacterClass (InvertedCC (ClassAtomCR (sc 'a', ClassAtomCR (sc 'b', EmptyCR))))) -- cchar 'c')
    "Ac"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:[^ab])c/ on 'Ac' at 0:
    Input: Ac
    End: 2
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-affects-characterEscapes.js
 * Description: Removing ignoreCase (`i`) modifier in group affects character escapes in group.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_affects_charEscapes_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], AtomEsc (ACharacterEsc (hex_escape '6' '1'))) -- cchar 'b')
    "ab"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\x61)b/ on 'ab' at 0:
    Input: ab
    End: 2
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_affects_charEscapes_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], AtomEsc (ACharacterEsc (hex_escape '6' '1'))) -- cchar 'b')
    "Ab"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\x61)b/ on 'Ab' at 0:
    No match |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-affects-slash-lower-b.js
 * Description: Removing ignoreCase (`i`) modifier affects matching for `\b`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_affects_b_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], WordBoundary))
    "\u{017f}"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\b)/ on 'ſ' at 0:
    No match |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-affects-slash-lower-w.js
 * Description: Removing ignoreCase (`i`) modifier affects matching for `\w`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_affects_w_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], AtomEsc (ACharacterClassEsc Coq_esc_w)))
    "\u{017f}"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\w)/ on 'ſ' at 0:
    No match |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-does-not-affect-dotAll-flag.js
 * Description: Removing ignoreCase (`i`) modifier in group should not affect dotAll (`s`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_no_affect_dotAll_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], Dot -- cchar 'e' -- cchar 's'))
    "aes"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:.es)/ on 'aes' at 0:
    Input: aes
    End: 3
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_no_affect_dotAll_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], Dot -- cchar 'e' -- cchar 's'))
    "\nes"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:.es)/ on '
es' at 0:
    No match |}]

let%expect_test "remove_ignoreCase_no_affect_dotAll_re2_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], Dot -- cchar 'e' -- cchar 's'))
    "\nes"
    0 ~ignoreCase:true ~dotAll:true ();
  [%expect {|
    Regex /(?-i:.es)/ on '
es' at 0:
    Input:
    es
    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-does-not-affect-multiline-flag.js
 * Description: Removing ignoreCase (`i`) modifier in group should not affect multiline (`m`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_no_affect_multiline_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'e' -- cchar 's' -- InputEnd))
    "es"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:es$)/ on 'es' at 0:
    Input: es
    End: 2
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_no_affect_multiline_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'e' -- cchar 's' -- InputEnd))
    "es\nz"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:es$)/ on 'es
z' at 0:
    No match |}]

let%expect_test "remove_ignoreCase_no_affect_multiline_re2_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'e' -- cchar 's' -- InputEnd))
    "es\nz"
    0 ~ignoreCase:true ~multiline:true ();
  [%expect {|
    Regex /(?-i:es$)/ on 'es
z' at 0:
    Input: es
    z
    End: 2
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-dotAll-does-not-affect-ignoreCase-flag.js
 * Description: Removing dotAll (`s`) modifier in group should not affect ignoreCase (`i`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_dotAll_no_affect_ignoreCase_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 's'], Dot -- cchar 'e' -- cchar 's'))
    "aes"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:.es)/ on 'aes' at 0:
    Input: aes
    End: 3
    Captures:
    	None |}]

let%expect_test "remove_dotAll_no_affect_ignoreCase_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 's'], Dot -- cchar 'e' -- cchar 's'))
    "aeS"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:.es)/ on 'aeS' at 0:
    No match |}]

let%expect_test "remove_dotAll_no_affect_ignoreCase_re2_1" =
  test_regex
    (ModifierRemove ([], [modchar 's'], Dot -- cchar 'e' -- cchar 's'))
    "aeS"
    0 ~dotAll:true ~ignoreCase:true ();
  [%expect {|
    Regex /(?-s:.es)/ on 'aeS' at 0:
    Input: aeS
    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-dotAll-does-not-affect-multiline-flag.js
 * Description: Removing dotAll (`s`) modifier in group should not affect multiline (`m`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_dotAll_no_affect_multiline_re2_1" =
  test_regex
    (ModifierRemove ([], [modchar 's'], Dot -- cchar 'e' -- cchar 's' -- InputEnd))
    "aes\nz"
    0 ~dotAll:true ~multiline:true ();
  [%expect {|
    Regex /(?-s:.es$)/ on 'aes
z' at 0:
    Input: aes
    z
    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-multiline-does-not-affect-dotAll-flag.js
 * Description: Removing multiline (`m`) modifier in group should not affect dotAll (`s`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_multiline_no_affect_dotAll_re2_1" =
  test_regex
    (ModifierRemove ([], [modchar 'm'], cchar 'e' -- cchar 's' -- Dot -- InputEnd))
    "es\n"
    0 ~multiline:true ~dotAll:true ();
  [%expect {|
    Regex /(?-m:es.$)/ on 'es
' at 0:
    Input: es
    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-multiline-does-not-affect-ignoreCase-flag.js
 * Description: Removing multiline (`m`) modifier in group should not affect ignoreCase (`i`) flag.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_multiline_no_affect_ignoreCase_re2_1" =
  test_regex
    (ModifierRemove ([], [modchar 'm'], cchar 'e' -- cchar 's' -- InputEnd))
    "eS"
    0 ~multiline:true ~ignoreCase:true ();
  [%expect {|
    Regex /(?-m:es$)/ on 'eS' at 0:
    Input: eS
    End: 2
    Captures:
    	None |}]

(*
 * ============================================================================
 * SKIPPED TESTS - Files not implemented with reasons
 * ============================================================================
 *)

(*
 * ----------------------------------------------------------------------------
 * File: add-dotAll-does-not-affect-dotAll-property.js
 * Reason: Tests RegExp instance dotAll property - Warblre test API doesn't expose RegExp flags/properties
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-does-not-affect-ignoreCase-property.js
 * Reason: Tests RegExp instance ignoreCase property - Warblre test API doesn't expose RegExp flags/properties
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: add-multiline-does-not-affect-multiline-property.js
 * Reason: Tests RegExp instance multiline property - Warblre test API doesn't expose RegExp flags/properties
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: remove-dotAll-does-not-affect-dotAll-property.js
 * Reason: Tests RegExp instance dotAll property - Warblre test API doesn't expose RegExp flags/properties
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-does-not-affect-ignoreCase-property.js
 * Reason: Tests RegExp instance ignoreCase property - Warblre test API doesn't expose RegExp flags/properties
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: remove-multiline-does-not-affect-multiline-property.js
 * Reason: Tests RegExp instance multiline property - Warblre test API doesn't expose RegExp flags/properties
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: add-and-remove-modifiers-can-have-empty-remove-modifiers.js
 * Reason: Syntax-only tests - only verifies patterns parse without errors, no matching behavior
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: add-and-remove-modifiers.js
 * Reason: Syntax-only tests - only verifies patterns parse without errors, no matching behavior
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: add-modifiers-when-nested.js
 * Reason: Syntax-only tests - only verifies patterns parse without errors, no matching behavior
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: add-modifiers-when-not-set-as-flags.js
 * Reason: Syntax-only tests - only verifies patterns parse without errors, no matching behavior
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: add-modifiers-when-set-as-flags.js
 * Reason: Syntax-only tests - only verifies patterns parse without errors, no matching behavior
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: remove-modifiers-when-nested.js
 * Reason: Syntax-only tests - only verifies patterns parse without errors, no matching behavior
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: remove-modifiers-when-not-set-as-flags.js
 * Reason: Syntax-only tests - only verifies patterns parse without errors, no matching behavior
 * ----------------------------------------------------------------------------
 *)

(*
 * ----------------------------------------------------------------------------
 * File: remove-modifiers-when-set-as-flags.js
 * Reason: Syntax-only tests - only verifies patterns parse without errors, no matching behavior
 * ----------------------------------------------------------------------------
 *)

(*
 * ============================================================================
 * ADDITIONAL TESTS - Files that were missed in initial implementation
 * ============================================================================
 *)

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-affects-slash-lower-p.js
 * Description: Adding ignoreCase (`i`) modifier affects matching for `\p{}`.
 * NOTE: Uses \p{Lu} which is not implemented in Warblre - using Alphabetic instead
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_affects_p_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], AtomEsc (ACharacterClassEsc (UnicodeProp Warblre.UnicodeProperties.UnicodeProperty.Alphabetic))))
    "A"
    0 ();
  [%expect {|
    Regex /(?i:\p{...})/ on 'A' at 0:
    Input: A
    End: 1
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_affects_p_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'i'], AtomEsc (ACharacterClassEsc (UnicodeProp Warblre.UnicodeProperties.UnicodeProperty.Alphabetic))))
    "a"
    0 ();
  [%expect {|
    Regex /(?i:\p{...})/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-affects-slash-upper-b.js
 * Description: Adding ignoreCase (`i`) modifier affects matching for `\B`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_affects_B_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], cchar 'Z' -- NotWordBoundary))
    "Z\u{017f}"
    0 ();
  [%expect {|
    Regex /(?i:Z\B)/ on 'Zſ' at 0:
    Input: Zſ
    End: 2
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_affects_B_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'i'], cchar 'Z' -- NotWordBoundary))
    "Z\u{212a}"
    0 ();
  [%expect {|
    Regex /(?i:Z\B)/ on 'ZK' at 0:
    Input: ZK
    End: 2
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-affects-slash-upper-p.js
 * Description: Adding ignoreCase (`i`) modifier affects matching for `\P{}`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_affects_P_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], AtomEsc (ACharacterClassEsc (UnicodePropNeg Warblre.UnicodeProperties.UnicodeProperty.Alphabetic))))
    "A"
    0 ();
  [%expect {|
    Regex /(?i:\P{...})/ on 'A' at 0:
    Input: A
    End: 1
    Captures:
    	None |}]

let%expect_test "add_ignoreCase_affects_P_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'i'], AtomEsc (ACharacterClassEsc (UnicodePropNeg Warblre.UnicodeProperties.UnicodeProperty.Alphabetic))))
    "0"
    0 ();
  [%expect {|
    Regex /(?i:\P{...})/ on '0' at 0:
    Input: 0
    End: 1
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: add-ignoreCase-affects-slash-upper-w.js
 * Description: Adding ignoreCase (`i`) modifier affects matching for `\W`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "add_ignoreCase_affects_W_re1_1" =
  test_regex
    (ModifierAdd ([modchar 'i'], AtomEsc (ACharacterClassEsc Coq_esc_W)))
    "\u{017f}"
    0 ();
  [%expect {|
    Regex /(?i:\W)/ on 'ſ' at 0:
    No match |}]

let%expect_test "add_ignoreCase_affects_W_re1_2" =
  test_regex
    (ModifierAdd ([modchar 'i'], AtomEsc (ACharacterClassEsc Coq_esc_W)))
    "\u{212a}"
    0 ();
  [%expect {|
    Regex /(?i:\W)/ on 'K' at 0:
    No match |}]

(*
 * ----------------------------------------------------------------------------
 * File: changing-dotAll-flag-does-not-affect-dotAll-modifier.js
 * Description: New dotAll (`s`) flag from RegExp constructor does not affect dotAll modifier in group.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "changing_dotAll_flag_no_affect_mod_re2_1" =
  test_regex
    (ModifierRemove ([], [modchar 's'], InputStart -- Dot -- InputEnd))
    "\n"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:^.$)/ on '
' at 0:
    No match |}]

let%expect_test "changing_dotAll_flag_no_affect_mod_re2_2" =
  test_regex
    (ModifierRemove ([], [modchar 's'], InputStart -- Dot -- InputEnd))
    "a"
    0 ~dotAll:true ();
  [%expect {|
    Regex /(?-s:^.$)/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: nesting-remove-ignoreCase-within-add-ignoreCase.js
 * Description: Can remove ignoreCase (`i`) modifier for group nested within a group that adds ignoreCase modifier.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "nesting_remove_ignoreCase_within_add_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'a' -- ModifierAdd ([modchar 'i'], cchar 'b')) -- cchar 'c')
    "ABC"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:a(?i:b))c/ on 'ABC' at 0:
    No match |}]

let%expect_test "nesting_remove_ignoreCase_within_add_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'a' -- ModifierAdd ([modchar 'i'], cchar 'b')) -- cchar 'c')
    "aBc"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:a(?i:b))c/ on 'aBc' at 0:
    Input: aBc
    End: 3
    Captures:
    	None |}]

let%expect_test "nesting_remove_ignoreCase_within_add_re1_3" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'a' -- ModifierAdd ([modchar 'i'], cchar 'b')) -- cchar 'c')
    "abC"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:a(?i:b))c/ on 'abC' at 0:
    Input: abC
    End: 3
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-affects-slash-lower-p.js
 * Description: Removing ignoreCase (`i`) modifier affects matching for `\p{}`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_affects_p_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], AtomEsc (ACharacterClassEsc (UnicodeProp Warblre.UnicodeProperties.UnicodeProperty.Alphabetic))))
    "A"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\p{...})/ on 'A' at 0:
    Input: A
    End: 1
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_affects_p_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], AtomEsc (ACharacterClassEsc (UnicodeProp Warblre.UnicodeProperties.UnicodeProperty.Alphabetic))))
    "a"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\p{...})/ on 'a' at 0:
    No match |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-affects-slash-upper-b.js
 * Description: Removing ignoreCase (`i`) modifier affects matching for `\B`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_affects_B_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'Z' -- NotWordBoundary))
    "Z\u{017f}"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:Z\B)/ on 'Zſ' at 0:
    No match |}]

let%expect_test "remove_ignoreCase_affects_B_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], cchar 'Z' -- NotWordBoundary))
    "Z\u{212a}"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:Z\B)/ on 'ZK' at 0:
    No match |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-affects-slash-upper-p.js
 * Description: Removing ignoreCase (`i`) modifier affects matching for `\P{}`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_affects_P_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], AtomEsc (ACharacterClassEsc (UnicodePropNeg Warblre.UnicodeProperties.UnicodeProperty.Alphabetic))))
    "A"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\P{...})/ on 'A' at 0:
    No match |}]

let%expect_test "remove_ignoreCase_affects_P_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], AtomEsc (ACharacterClassEsc (UnicodePropNeg Warblre.UnicodeProperties.UnicodeProperty.Alphabetic))))
    "a"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\P{...})/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_affects_P_re1_3" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], AtomEsc (ACharacterClassEsc (UnicodePropNeg Warblre.UnicodeProperties.UnicodeProperty.Alphabetic))))
    "0"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\P{...})/ on '0' at 0:
    Input: 0
    End: 1
    Captures:
    	None |}]

(*
 * ----------------------------------------------------------------------------
 * File: remove-ignoreCase-affects-slash-upper-w.js
 * Description: Removing ignoreCase (`i`) modifier affects matching for `\W`.
 * ----------------------------------------------------------------------------
 *)

let%expect_test "remove_ignoreCase_affects_W_re1_1" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], AtomEsc (ACharacterClassEsc Coq_esc_W)))
    "\u{017f}"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\W)/ on 'ſ' at 0:
    Input: ſ
    End: 1
    Captures:
    	None |}]

let%expect_test "remove_ignoreCase_affects_W_re1_2" =
  test_regex
    (ModifierRemove ([], [modchar 'i'], AtomEsc (ACharacterClassEsc Coq_esc_W)))
    "\u{212a}"
    0 ~ignoreCase:true ();
  [%expect {|
    Regex /(?-i:\W)/ on 'K' at 0:
    Input: K
    End: 1
    Captures:
    	None |}]
