From Warblre Require Import Typeclasses Result.

(** Types used to represent errors at different stages of the matching pipeline. *)

(* Errors which occur during the early errors phase. *)
Module SyntaxError.
  Inductive type: Type :=
  | AssertionFailed.
End SyntaxError.
Abbreviation SyntaxError := SyntaxError.type.
#[refine] #[export]
Instance eqdec_syntaxError: EqDec SyntaxError := {}. decide equality. Defined.
#[export]
Instance syntax_assertion_error: Result.AssertionError SyntaxError := { f := SyntaxError.AssertionFailed }.

(* Errors which occur during the compilation phase. *)
Module CompileError.
  Inductive type: Type :=
  | AssertionFailed.
End CompileError.
Abbreviation CompileError := CompileError.type.
#[refine] #[export]
Instance eqdec_compileError: EqDec CompileError := {}. decide equality. Defined.
#[export]
Instance compile_assertion_error: Result.AssertionError CompileError := { f := CompileError.AssertionFailed }.

Module MatchError.
  Inductive type :=
  | OutOfFuel
  | AssertionFailed.
End MatchError.
Abbreviation MatchError := MatchError.type.
#[refine] #[export]
Instance eqdec_matchError: EqDec MatchError := {}. decide equality. Defined.
#[export]
Instance match_assertion_error: Result.AssertionError MatchError := { f := MatchError.AssertionFailed }.


(* Shorthands *)
Abbreviation compile_assertion_failed := (Error CompileError.AssertionFailed).
Abbreviation out_of_fuel := (Error MatchError.OutOfFuel).
Abbreviation match_assertion_failed := (Error MatchError.AssertionFailed).
