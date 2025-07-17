   (* 1. Utf16String: Use NaiveUtf16String in OCaml and custom JS on JS side. *)
   (* 2. CharSets: change type to sets. *)

Module NaiveUtf16String <: API.Utils.Utf16String.
  Import ZArith Numeric Result.
  Open Scope Z_scope.

  Definition Utf16CodeUnit: Type :=
    { z: Z | 0 <= z < Z.pow 2 16 }.
  Definition Utf16String: Type :=
    list Utf16CodeUnit.
  Definition length (s: Utf16String) : non_neg_integer :=
    List.length s.

  Definition codeUnitAt {F: Type} {f: Result.AssertionError F}
    (s: Utf16String) (n: non_neg_integer): Result Utf16CodeUnit F :=
    match List.nth_error s n with
    | Some u => Result.Success u
    | None => Result.assertion_failed
    end.

  Open Scope bool_scope.
  Definition is_leading_surrogate (u: Utf16CodeUnit): bool :=
    (0xD800 <=? proj1_sig u) && (proj1_sig u <=? 0xDBFF).
  Definition is_trailing_surrogate (u: Utf16CodeUnit): bool :=
    (0xDC00 <=? proj1_sig u) && (proj1_sig u <=? 0xDFFF).
End NaiveUtf16String.
