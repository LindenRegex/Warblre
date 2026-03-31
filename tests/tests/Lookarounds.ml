open Warblre.OCamlEngines.UnicodeNotations
open Warblre.OCamlEngines.UnicodeTester

let%expect_test "lookahead_0_pos" =
  test_regex
    (cchar 'a' -- (?= (cchar 'b')))
    "ab"
    0 ();
  [%expect {|
    Regex /a(?=b)/ on 'ab' at 0:
    Input: ab
    End: 1
    Captures:
    	None |}]

let%expect_test "lookahead_0_neg_0" =
  test_regex
    (cchar 'a' -- (?= (cchar 'b')))
    "a"
    0 ();
  [%expect {|
    Regex /a(?=b)/ on 'a' at 0:
    No match |}]

let%expect_test "lookahead_0_neg_1" =
  test_regex
    (cchar 'a' -- (?= (cchar 'b')))
    "aa"
    0 ();
  [%expect {|
    Regex /a(?=b)/ on 'aa' at 0:
    No match |}]


let%expect_test "neglookahead_0_pos_0" =
  test_regex
    (cchar 'a' -- (?! (cchar 'b')))
    "aa"
    0 ();
  [%expect {|
    Regex /a(?!b)/ on 'aa' at 0:
    Input: aa
    End: 1
    Captures:
    	None |}]

let%expect_test "neglookahead_0_pos_1" =
  test_regex
    (cchar 'a' -- (?! (cchar 'b')))
    "a"
    0 ();
  [%expect {|
    Regex /a(?!b)/ on 'a' at 0:
    Input: a
    End: 1
    Captures:
    	None |}]

let%expect_test "neglookahead_0_neg" =
  test_regex
    (cchar 'a' -- (?! (cchar 'b')))
    "ab"
    0 ();
  [%expect {|
    Regex /a(?!b)/ on 'ab' at 0:
    No match |}]
