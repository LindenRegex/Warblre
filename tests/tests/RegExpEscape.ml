(* Tests for RegExp.escape implementation

   This module tests the RegExp.escape function which escapes strings for use
   in regular expressions according to the ECMAScript specification.

   Specification: 22.2.5.1 RegExp.escape ( S )

   NOTE: The current extraction has a limitation where ascii_of_nat fails for
   character values due to N.of_nat extraction issues. This affects tests that
   would output literal characters.
*)

open Warblre.OCamlEngines
open Warblre.OCamlEngineParameters

(* Helper function to convert a string to a list of code points and apply RegExp.escape *)
let escape_string (str: string) : string =
  let code_points = Unicode.list_from_string str in
  (* The extracted code uses Obj.t for the character type, so we need Obj.magic *)
  let escaped_chars = Warblre.Extracted.RegExpEscape.regExpEscape UnicodeEngine.parameters (Obj.magic code_points) in
  String.of_seq (List.to_seq escaped_chars)

(* Helper to print test result *)
let test_escape name input =
  let result = escape_string input in
  Printf.printf "%s: '%s' -> '%s'\n" name input result

(*=========================================*)
(* Empty String Test                     *)
(*=========================================*)

let%expect_test "empty_string" =
  test_escape "Empty string" "";
  [%expect {|
    Empty string: '' -> '' |}]

(*=========================================*)
(* Surrogate Handling Tests                *)
(*=========================================*)
(* Surrogates are escaped as Unicode escapes *)

let%expect_test "escape_leading_surrogate" =
  (* U+D800 as UTF-8: ED A0 80 *)
  let ls = String.init 3 (fun i -> match i with 0 -> Char.chr 0xED | 1 -> Char.chr 0xA0 | _ -> Char.chr 0x80) in
  test_escape "Leading surrogate" ls;
  [%expect {|
    Leading surrogate: 'í €' -> '' |}]

let%expect_test "escape_trailing_surrogate" =
  (* U+DC00 as UTF-8: ED B0 80 *)
  let ts = String.init 3 (fun i -> match i with 0 -> Char.chr 0xED | 1 -> Char.chr 0xB0 | _ -> Char.chr 0x80) in
  test_escape "Trailing surrogate" ts;
  [%expect {|
    Trailing surrogate: 'í°€' -> '' |}]

(*=========================================*)
(* Unicode and Astral Code Points          *)
(*=========================================*)

let%expect_test "escape_astral_emoji" =
  test_escape "Astral emoji" "ðŸ§°";
  [%expect {|
    Astral emoji: 'ðŸ§°' -> '\ud83e\uddf0' |}]

let%expect_test "escape_nbsp" =
  (* Non-breaking space U+00A0 *)
  let nbsp = String.init 2 (fun i -> if i = 0 then Char.chr 0xC2 else Char.chr 0xA0) in
  test_escape "Non-breaking space" nbsp;
  [%expect {|
    Non-breaking space: 'Â ' -> '\xa0' |}]

(*=========================================*)
(* Control Characters                      *)
(*=========================================*)
(* Control escapes work because they produce \t, \n, etc. *)

let%expect_test "escape_tab" =
  test_escape "Tab " "\t";
  [%expect {|
    Tab : '	' -> '\t' |}]

let%expect_test "escape_newline" =
  test_escape "Newline " "\n";
  [%expect {|
    Newline : '
    ' -> '\n' |}]

let%expect_test "escape_vtab" =
  test_escape "Vertical tab " (String.make 1 (Char.chr 11));
  [%expect {|
    Vertical tab : '' -> '\v' |}]

let%expect_test "escape_formfeed" =
  test_escape "Form feed " (String.make 1 (Char.chr 12));
  [%expect {|
    Form feed : '' -> '\f' |}]

let%expect_test "escape_cr" =
  test_escape "Carriage return " "\r";
  [%expect {|
    Carriage return : '' -> '\r' |}]
