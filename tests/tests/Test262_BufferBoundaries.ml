(* Test262 Buffer Boundaries tests
   Converted from test262/test/annexB/built-ins/RegExp/buffer-boundaries/
   Feature: regexp-buffer-boundaries
*)

open Warblre.OCamlEngines.UnicodeNotations
open Warblre.OCamlEngines.UnicodeTester

(* ============================================================================
   File: test/annexB/built-ins/RegExp/buffer-boundaries/not-supported-outside-unicode-modes.js
   Description: \A and \z (and \Z) are treated as IdentityEscape in Annex B outside any unicode mode
   ============================================================================ *)

(* ----------------------------------------------------------------------------
   Test: /^
A$/.test("A") - \A matches literal 'A' in non-unicode mode
   ---------------------------------------------------------------------------- *)
let%expect_test "identity_escape_A_literal_pattern_matches_A" =
  test_regex
    (InputStart -- (cchar 'A') -- InputEnd)
    "A"
    0 ();
  [%expect {|
    Regex /^A$/ on 'A' at 0:
    Input: A
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: !/
Ax/.test("x") - \A does not match start of buffer as literal 'A'
   ---------------------------------------------------------------------------- *)
let%expect_test "identity_escape_A_literal_pattern_no_match_x" =
  test_regex
    ((cchar 'A') -- (cchar 'x'))
    "x"
    0 ();
  [%expect {|
    Regex /Ax/ on 'x' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("^\\A$").test("A") - Constructor form
   ---------------------------------------------------------------------------- *)
let%expect_test "identity_escape_A_constructor_matches_A" =
  test_regex
    (InputStart -- (cchar 'A') -- InputEnd)
    "A"
    0 ();
  [%expect {|
    Regex /^A$/ on 'A' at 0:
    Input: A
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: !new RegExp("\\Ax").test("x") - Constructor form
   ---------------------------------------------------------------------------- *)
let%expect_test "identity_escape_A_constructor_no_match_x" =
  test_regex
    ((cchar 'A') -- (cchar 'x'))
    "x"
    0 ();
  [%expect {|
    Regex /Ax/ on 'x' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: /^\z$/.test("z") - \z matches literal 'z' in non-unicode mode
   ---------------------------------------------------------------------------- *)
let%expect_test "identity_escape_z_literal_pattern_matches_z" =
  test_regex
    (InputStart -- (cchar 'z') -- InputEnd)
    "z"
    0 ();
  [%expect {|
    Regex /^z$/ on 'z' at 0:
    Input: z
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: !/x\z/.test("x") - \z does not match end of buffer as literal 'z'
   ---------------------------------------------------------------------------- *)
let%expect_test "identity_escape_z_literal_pattern_no_match_x" =
  test_regex
    ((cchar 'x') -- (cchar 'z'))
    "x"
    0 ();
  [%expect {|
    Regex /xz/ on 'x' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("^\\z$").test("z") - Constructor form
   ---------------------------------------------------------------------------- *)
let%expect_test "identity_escape_z_constructor_matches_z" =
  test_regex
    (InputStart -- (cchar 'z') -- InputEnd)
    "z"
    0 ();
  [%expect {|
    Regex /^z$/ on 'z' at 0:
    Input: z
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: !new RegExp("x\\z").test("x") - Constructor form
   ---------------------------------------------------------------------------- *)
let%expect_test "identity_escape_z_constructor_no_match_x" =
  test_regex
    ((cchar 'x') -- (cchar 'z'))
    "x"
    0 ();
  [%expect {|
    Regex /xz/ on 'x' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: /^\Z$/.test("Z") - \Z matches literal 'Z' in non-unicode mode
   ---------------------------------------------------------------------------- *)
let%expect_test "identity_escape_Z_literal_pattern_matches_Z" =
  test_regex
    (InputStart -- (cchar 'Z') -- InputEnd)
    "Z"
    0 ();
  [%expect {|
    Regex /^Z$/ on 'Z' at 0:
    Input: Z
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("^\\Z$").test("Z") - Constructor form
   ---------------------------------------------------------------------------- *)
let%expect_test "identity_escape_Z_constructor_matches_Z" =
  test_regex
    (InputStart -- (cchar 'Z') -- InputEnd)
    "Z"
    0 ();
  [%expect {|
    Regex /^Z$/ on 'Z' at 0:
    Input: Z
    End: 1
    Captures:
    	None |}]

(* ============================================================================
   File: slash-lower-case-z-matches-end-of-buffer.js
   Description: \z (lower-case z) matches end of buffer in any unicode mode
   ============================================================================ *)

(* ----------------------------------------------------------------------------
   Test: /x\z/u.test("x") - match at end of buffer, no multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_u_match_x" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0 ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /x\z/um.test("x") - match at end of buffer, with multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_um_match_x" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /x\z/u.test("xy") - no match when not at end of buffer
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_u_no_match_xy" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "xy"
    0 ();
  [%expect {|
    Regex /x\z/ on 'xy' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: /x\z/um.test("xy") - no match when not at end of buffer, multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_um_no_match_xy" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "xy"
    0
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'xy' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: /x\z/u.test("x\ny") - no match when only at end of line
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_u_no_match_x_newline_y" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x\ny"
    0 ();
  [%expect {|
Regex /x\z/ on 'x
y' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: /x\z/um.test("x\ny") - no match when only at end of line, multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_um_no_match_x_newline_y" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x\ny"
    0
    ~multiline:true ();
  [%expect {|
Regex /x\z/ on 'x
y' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: /x\z/v.test("x") - match at end of buffer, unicodeSets mode
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_v_match_x" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0 ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /x\z/vm.test("x") - match at end of buffer, unicodeSets + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_vm_match_x" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /x\z/v.test("xy") - no match when not at end of buffer, unicodeSets
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_v_no_match_xy" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "xy"
    0 ();
  [%expect {|
    Regex /x\z/ on 'xy' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: /x\z/vm.test("xy") - no match when not at end, unicodeSets + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_vm_no_match_xy" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "xy"
    0
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'xy' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: /x\z/v.test("x\ny") - no match when only at end of line, unicodeSets
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_v_no_match_x_newline_y" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x\ny"
    0 ();
  [%expect {|
Regex /x\z/ on 'x
y' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: /x\z/vm.test("x\ny") - no match at end of line, unicodeSets + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_vm_no_match_x_newline_y" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x\ny"
    0
    ~multiline:true ();
  [%expect {|
Regex /x\z/ on 'x
y' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "u").test("x") - constructor form, unicode
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_u_match_x" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0 ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "um").test("x") - constructor form, unicode + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_um_match_x" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "u").test("xy") - constructor form, no match
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_u_no_match_xy" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "xy"
    0 ();
  [%expect {|
    Regex /x\z/ on 'xy' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "um").test("xy") - constructor form, no match, multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_um_no_match_xy" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "xy"
    0
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'xy' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "u").test("x\ny") - constructor form, no match at line end
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_u_no_match_x_newline_y" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x\ny"
    0 ();
  [%expect {|
Regex /x\z/ on 'x
y' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "um").test("x\ny") - constructor form, no match, multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_um_no_match_x_newline_y" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x\ny"
    0
    ~multiline:true ();
  [%expect {|
Regex /x\z/ on 'x
y' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "v").test("x") - constructor form, unicodeSets
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_v_match_x" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0 ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "vm").test("x") - constructor form, unicodeSets + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_vm_match_x" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "v").test("xy") - constructor form, no match, unicodeSets
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_v_no_match_xy" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "xy"
    0 ();
  [%expect {|
    Regex /x\z/ on 'xy' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "vm").test("xy") - constructor form, no match, unicodeSets+multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_vm_no_match_xy" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "xy"
    0
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'xy' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "v").test("x\ny") - constructor form, no match at line end
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_v_no_match_x_newline_y" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x\ny"
    0 ();
  [%expect {|
Regex /x\z/ on 'x
y' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("x\\z", "vm").test("x\ny") - constructor form, no match, unicodeSets+multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_z_constructor_vm_no_match_x_newline_y" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x\ny"
    0
    ~multiline:true ();
  [%expect {|
Regex /x\z/ on 'x
y' at 0:
No match |}]

(* ============================================================================
   File: test/built-ins/RegExp/buffer-boundaries/syntax/u-mode.js
   Description: \A and \z are parsed successfully in u-mode with various flags
   ============================================================================ *)

(* ----------------------------------------------------------------------------
   Test: /\A/u - BufferStart in unicode mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_u_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0 ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/um - BufferStart in unicode + multiline mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_um_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/umi - BufferStart in unicode + multiline + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_umi_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'X'))
    "x"
    0
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /\AX/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/us - BufferStart in unicode + dotAll mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_us_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~dotAll:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/usi - BufferStart in unicode + dotAll + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_usi_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'X'))
    "x"
    0
    ~dotAll:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /\AX/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/usm - BufferStart in unicode + dotAll + multiline mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_usm_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~dotAll:true
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/usmi - BufferStart in unicode + dotAll + multiline + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_usmi_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'X'))
    "x"
    0
    ~dotAll:true
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /\AX/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/u - BufferEnd in unicode mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_u_buffer_end" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0 ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/um - BufferEnd in unicode + multiline mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_um_buffer_end" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/umi - BufferEnd in unicode + multiline + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_umi_buffer_end" =
  test_regex
    ((cchar 'X') -- BufferEnd)
    "x"
    0
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /X\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/us - BufferEnd in unicode + dotAll mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_us_buffer_end" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~dotAll:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/usi - BufferEnd in unicode + dotAll + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_usi_buffer_end" =
  test_regex
    ((cchar 'X') -- BufferEnd)
    "x"
    0
    ~dotAll:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /X\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/usm - BufferEnd in unicode + dotAll + multiline mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_usm_buffer_end" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~dotAll:true
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/usmi - BufferEnd in unicode + dotAll + multiline + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_usmi_buffer_end" =
  test_regex
    ((cchar 'X') -- BufferEnd)
    "x"
    0
    ~dotAll:true
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /X\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ============================================================================
   File: slash-upper-case-a-matches-start-of-buffer.js
   Description: \A matches start of buffer in any unicode mode
   ============================================================================ *)

(* ----------------------------------------------------------------------------
   Test: /\Ax/u.test("x") - match at start of buffer, no multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_u_match_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0 ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\Ax/um.test("x") - match at start of buffer, with multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_um_match_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\Ax/u.test("yx") - no match when not at start of buffer
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_u_no_match_yx" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "yx"
    0 ();
  [%expect {|
    Regex /\Ax/ on 'yx' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: /\Ax/um.test("yx") - no match when not at start, multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_um_no_match_yx" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "yx"
    0
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'yx' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: /\Ax/u.test("y\nx") - no match when only at start of line
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_u_no_match_y_newline_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "y\nx"
    0 ();
  [%expect {|
Regex /\Ax/ on 'y
x' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: /\Ax/um.test("y\nx") - no match when only at start of line, multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_um_no_match_y_newline_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "y\nx"
    0
    ~multiline:true ();
  [%expect {|
Regex /\Ax/ on 'y
x' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: /\Ax/v.test("x") - match at start, unicodeSets mode
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_v_match_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0 ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\Ax/vm.test("x") - match at start, unicodeSets + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_vm_match_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\Ax/v.test("yx") - no match when not at start, unicodeSets
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_v_no_match_yx" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "yx"
    0 ();
  [%expect {|
    Regex /\Ax/ on 'yx' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: /\Ax/vm.test("yx") - no match when not at start, unicodeSets + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_vm_no_match_yx" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "yx"
    0
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'yx' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: /\Ax/v.test("y\nx") - no match when only at start of line, unicodeSets
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_v_no_match_y_newline_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "y\nx"
    0 ();
  [%expect {|
Regex /\Ax/ on 'y
x' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: /\Ax/vm.test("y\nx") - no match at start of line, unicodeSets + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_vm_no_match_y_newline_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "y\nx"
    0
    ~multiline:true ();
  [%expect {|
Regex /\Ax/ on 'y
x' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "u").test("x") - constructor form, unicode
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_u_match_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0 ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "um").test("x") - constructor form, unicode + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_um_match_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "u").test("yx") - constructor form, no match
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_u_no_match_yx" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "yx"
    0 ();
  [%expect {|
    Regex /\Ax/ on 'yx' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "um").test("yx") - constructor form, no match, multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_um_no_match_yx" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "yx"
    0
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'yx' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "u").test("y\nx") - constructor form, no match at line start
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_u_no_match_y_newline_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "y\nx"
    0 ();
  [%expect {|
Regex /\Ax/ on 'y
x' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "um").test("y\nx") - constructor form, no match, multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_um_no_match_y_newline_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "y\nx"
    0
    ~multiline:true ();
  [%expect {|
Regex /\Ax/ on 'y
x' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "v").test("x") - constructor form, unicodeSets
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_v_match_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0 ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "vm").test("x") - constructor form, unicodeSets + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_vm_match_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "v").test("yx") - constructor form, no match, unicodeSets
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_v_no_match_yx" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "yx"
    0 ();
  [%expect {|
    Regex /\Ax/ on 'yx' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "vm").test("yx") - constructor form, no match, unicodeSets+multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_vm_no_match_yx" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "yx"
    0
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'yx' at 0:
    No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "v").test("y\nx") - constructor form, no match at line start
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_v_no_match_y_newline_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "y\nx"
    0 ();
  [%expect {|
Regex /\Ax/ on 'y
x' at 0:
No match |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Ax", "vm").test("y\nx") - constructor form, no match, unicodeSets+multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "slash_A_constructor_vm_no_match_y_newline_x" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "y\nx"
    0
    ~multiline:true ();
  [%expect {|
Regex /\Ax/ on 'y
x' at 0:
No match |}]

(* ============================================================================
   File: test/built-ins/RegExp/buffer-boundaries/syntax/v-mode.js
   Description: \A and \z are parsed successfully in v-mode with various flags
   ============================================================================ *)

(* ----------------------------------------------------------------------------
   Test: /\A/v - BufferStart in unicodeSets mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_v_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0 ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/vm - BufferStart in unicodeSets + multiline mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_vm_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/vmi - BufferStart in unicodeSets + multiline + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_vmi_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'X'))
    "x"
    0
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /\AX/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/vs - BufferStart in unicodeSets + dotAll mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_vs_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~dotAll:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/vsi - BufferStart in unicodeSets + dotAll + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_vsi_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'X'))
    "x"
    0
    ~dotAll:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /\AX/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/vsm - BufferStart in unicodeSets + dotAll + multiline mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_vsm_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~dotAll:true
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\A/vsmi - BufferStart in unicodeSets + dotAll + multiline + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_vsmi_buffer_start" =
  test_regex
    (BufferStart -- (cchar 'X'))
    "x"
    0
    ~dotAll:true
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /\AX/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/v - BufferEnd in unicodeSets mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_v_buffer_end" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0 ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/vm - BufferEnd in unicodeSets + multiline mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_vm_buffer_end" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/vmi - BufferEnd in unicodeSets + multiline + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_vmi_buffer_end" =
  test_regex
    ((cchar 'X') -- BufferEnd)
    "x"
    0
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /X\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/vs - BufferEnd in unicodeSets + dotAll mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_vs_buffer_end" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~dotAll:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/vsi - BufferEnd in unicodeSets + dotAll + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_vsi_buffer_end" =
  test_regex
    ((cchar 'X') -- BufferEnd)
    "x"
    0
    ~dotAll:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /X\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/vsm - BufferEnd in unicodeSets + dotAll + multiline mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_vsm_buffer_end" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~dotAll:true
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: /\z/vsmi - BufferEnd in unicodeSets + dotAll + multiline + ignoreCase mode
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_vsmi_buffer_end" =
  test_regex
    ((cchar 'X') -- BufferEnd)
    "x"
    0
    ~dotAll:true
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /X\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\A", "v") - constructor form, unicodeSets
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_constructor_v" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0 ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\A", "vm") - constructor form, unicodeSets + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_constructor_vm" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\A", "vmi") - constructor form, unicodeSets + multiline + ignoreCase
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_constructor_vmi" =
  test_regex
    (BufferStart -- (cchar 'X'))
    "x"
    0
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /\AX/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\A", "vs") - constructor form, unicodeSets + dotAll
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_constructor_vs" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~dotAll:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\A", "vsi") - constructor form, unicodeSets + dotAll + ignoreCase
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_constructor_vsi" =
  test_regex
    (BufferStart -- (cchar 'X'))
    "x"
    0
    ~dotAll:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /\AX/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\A", "vsm") - constructor form, unicodeSets + dotAll + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_constructor_vsm" =
  test_regex
    (BufferStart -- (cchar 'x'))
    "x"
    0
    ~dotAll:true
    ~multiline:true ();
  [%expect {|
    Regex /\Ax/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\A", "vsmi") - constructor form, unicodeSets + dotAll + multiline + ignoreCase
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_A_constructor_vsmi" =
  test_regex
    (BufferStart -- (cchar 'X'))
    "x"
    0
    ~dotAll:true
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /\AX/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\z", "v") - constructor form, unicodeSets
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_constructor_v" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0 ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\z", "vm") - constructor form, unicodeSets + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_constructor_vm" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\z", "vmi") - constructor form, unicodeSets + multiline + ignoreCase
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_constructor_vmi" =
  test_regex
    ((cchar 'X') -- BufferEnd)
    "x"
    0
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /X\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\z", "vs") - constructor form, unicodeSets + dotAll
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_constructor_vs" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~dotAll:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\z", "vsi") - constructor form, unicodeSets + dotAll + ignoreCase
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_constructor_vsi" =
  test_regex
    ((cchar 'X') -- BufferEnd)
    "x"
    0
    ~dotAll:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /X\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\z", "vsm") - constructor form, unicodeSets + dotAll + multiline
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_constructor_vsm" =
  test_regex
    ((cchar 'x') -- BufferEnd)
    "x"
    0
    ~dotAll:true
    ~multiline:true ();
  [%expect {|
    Regex /x\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\z", "vsmi") - constructor form, unicodeSets + dotAll + multiline + ignoreCase
   ---------------------------------------------------------------------------- *)
let%expect_test "syntax_z_constructor_vsmi" =
  test_regex
    ((cchar 'X') -- BufferEnd)
    "x"
    0
    ~dotAll:true
    ~multiline:true
    ~ignoreCase:true ();
  [%expect {|
    Regex /X\z/ on 'x' at 0:
    Input: x
    End: 1
    Captures:
    	None |}]

(* ============================================================================
   File: test/built-ins/RegExp/buffer-boundaries/syntax/upper-z-escape-reserved-in-unicode-modes.js
   Description: \Z (upper-case Z) is reserved in any unicode mode
   ============================================================================ *)

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Z", "u") throws SyntaxError

   This test verifies that \Z is NOT a valid escape sequence in unicode mode.
   Unlike \A (BufferStart) and \z (BufferEnd), \Z is reserved for future use
   and causes a SyntaxError when used in unicode ('u') or unicodeSets ('v') mode.

   In Warblre, this is represented by the absence of a BufferEndZ construct -
   only BufferStart (\A) and BufferEnd (\z) are supported.
   ---------------------------------------------------------------------------- *)
(* Negative test: \Z is reserved and invalid in unicode mode *)

(* ----------------------------------------------------------------------------
   Test: new RegExp("\\Z", "v") throws SyntaxError

   This test verifies that \Z is NOT a valid escape sequence in unicodeSets mode.
   Unlike \A (BufferStart) and \z (BufferEnd), \Z is reserved for possible future use
   as an extension of the \A and \z assertions and causes a SyntaxError when used
   in unicode ('u') or unicodeSets ('v') mode.

   In Warblre, this is represented by the absence of a BufferEndZ construct -
   only BufferStart (\A) and BufferEnd (\z) are supported.
   ---------------------------------------------------------------------------- *)
(* Negative test: \Z is reserved and invalid in unicodeSets mode *)
