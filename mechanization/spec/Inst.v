From Warblre Require Import API.
From Warblre Require Import Frontend.

(* TODOs:

   - Merge CharSetExt into CharSet.
     Use MSet API + a few functions / proofs.
   - Update NaiveEngineParameters with new functions.
   - Canonicalize?
   - Linden: instantiate and test
   - Keep just one of FastEngine and NaiveEngine
 *)

Module NaiveEngineParameters <: API.EngineParameters.
  Import RegExpRecord Numeric List PeanoNat Result.
  Import List.ListNotations.
  Open Scope list_scope.

  Definition character : Type := nat.

  Module Character.
    Definition equal: forall (l r: character), {l=r} + {l<>r} :=
      Nat.eq_dec.
    Definition from_numeric_value (n: nat): character :=
      n.
    Definition numeric_value (c: character) : nat :=
      c.
    (* TODO: This naive implementation does not canonicalize. *)
    Definition canonicalize (r: RegExpRecord) (c: character): character :=
      c.

    Theorem numeric_pseudo_bij: forall c, from_numeric_value (numeric_value c) = c.
    Proof. reflexivity. Qed.

    Theorem numeric_round_trip_order: forall l r, l <= r -> (numeric_value (from_numeric_value l)) <= (numeric_value (from_numeric_value r)).
    Proof. easy. Qed.
  End Character.

  Definition string : Type :=
    list character.

  Module String.
    Definition equal: forall (l r: string), {l=r} + {l<>r}.
    Proof.
      decide equality.
      eauto using Character.equal.
    Defined.
    Definition length (str: string) : non_neg_integer :=
      List.length str.
    Definition substring (str: string) (s: non_neg_integer) (e: non_neg_integer) : string :=
      List.take (List.drop str s) (e - s).
    Definition advanceStringIndex (str: string) (i: non_neg_integer) : non_neg_integer :=
      S i.
    Definition getStringIndex (str: string) (i: non_neg_integer) : non_neg_integer :=
      i.
    Definition list_from_string (str: string) : list character :=
      str.
    Definition list_to_string (l: list character) : string :=
      l.
  End String.

  Definition char_set: Type := ListSet.set character.

  Module CharSet.
    Definition empty: char_set := ListSet.empty_set character.
    Definition from_list (l: list character) : char_set := List.nodup Character.equal l.
    Definition union (cs0 cs1: char_set) : char_set := ListSet.set_union Character.equal cs0 cs1.
    Definition singleton (c: character) : char_set := [c].
    Definition size (cs: char_set) : nat := List.length cs.
    Definition remove_all (l r: char_set) : char_set := ListSet.set_diff Character.equal l r.
    Definition is_empty (cs: char_set) : bool := size cs =? 0.
    Definition contains (cs: char_set) (c: character) : bool := ListSet.set_mem Character.equal c cs.
    Definition range (first: character) (last: character) : char_set :=
      List.Range.Nat.Bounds.range first (last + 1).
    Definition unique (F: Type) (_: Result.AssertionError F) (cs: char_set) : Result character F :=
      match cs with
      | [x] => Result.Success x (* Assumes deduplicated ListSet *)
      | _ => Result.assertion_failed
      end.
    Definition filter (cs: char_set) (f: character -> bool) : char_set :=
      List.filter f cs.
    Definition exist (cs: char_set) (f: character -> bool) : bool :=
      List.existsb f cs.
    Definition exist_canonicalized (rer: RegExpRecord) (cs: char_set) (c: character): bool :=
      contains (List.map (Character.canonicalize rer) cs) c.

    Theorem singleton_size: forall c, size (singleton c) = 1.
    Proof. reflexivity. Qed.
    Theorem singleton_exist: forall c p, exist (singleton c) p = p c.
    Proof. cbv; destruct p; reflexivity. Qed.
    Theorem singleton_unique: forall (F: Type) (af: Result.AssertionError F) c, @unique F af (singleton c) = Success c.
    Proof. reflexivity. Qed.
    Theorem exist_canonicalized_equiv rer cs c :
      exist_canonicalized rer cs c =
        exist
          cs
          (fun c0 =>
             if Character.equal (Character.canonicalize rer c0) c
             then true else false).
    Proof.
      induction cs; simpl.
      - reflexivity.
      - unfold exist_canonicalized in *.
        simpl.
        repeat destruct Character.equal.
        all: reflexivity || assumption || congruence.
    Qed.
  End CharSet.

  Module CharSets.
    Definition all: list character :=
      Eval cbv in List.Range.Nat.Bounds.range 0 0x80.
    Definition line_terminators: list character := [
        (* line feed *) 0xA;
        (* vertical tab *) 0xB;
        (* form feed *) 0xC;
        (* carriage return *) 0xD
      ].
    Definition digits: list character :=
      Eval cbv in List.Range.Nat.Bounds.range 0x30 0x3A.
    Definition white_spaces: list character := [
        (* line feed *) 0x0A;
        (* line tabulation *) 0x0B;
        (* form feed *) 0x0C;
        (* carriage return *) 0x0D;
        (* space *) 0x20
      ].
    Definition ascii_word_characters: list character :=
      Eval cbv in (
          (List.Range.Nat.Bounds.range 65 91) ++ (* uppercase *)
            (List.Range.Nat.Bounds.range 97 123) ++ (* lowercase *)
            (List.Range.Nat.Bounds.range 48 58) ++ (* numbers *)
            [95] (* '_' *)
        ).
  End CharSets.

  Definition property: Type := list character.
  Module Property.
    Definition equal: forall (l r: property), {l=r} + {l<>r}.
    Proof.
      decide equality; eauto using Character.equal.
    Defined.
    Definition code_points (p: property) : list character :=
      p.
  End Property.
End NaiveEngineParameters.

From Coq Require Import OrdersEx MSetRBT.

Module FastEngineParameters <: API.EngineParameters.
  Import RegExpRecord Numeric List ZArith Result.
  Import List.ListNotations.
  Open Scope list_scope.
  Open Scope N_scope.

  Definition character : Type := N.

  Module Character.
    Definition equal: forall (l r: character), {l=r} + {l<>r} :=
      N.eq_dec.
    Definition from_numeric_value (n: nat): character :=
      N.of_nat n.
    Definition numeric_value (c: character) : nat :=
      N.to_nat c.
    (* TODO: This naive implementation does not canonicalize. *)
    Definition canonicalize (r: RegExpRecord) (c: character): character :=
      c.

    Theorem numeric_pseudo_bij: forall c, from_numeric_value (numeric_value c) = c.
    Proof. apply Nnat.N2Nat.id. Qed.

    Theorem numeric_round_trip_order: forall l r,
        (l <= r)%nat ->
        (numeric_value (from_numeric_value l) <= numeric_value (from_numeric_value r))%nat.
    Proof.
      unfold numeric_value, from_numeric_value; intros; rewrite !Nnat.Nat2N.id.
      assumption.
    Qed.
  End Character.

  Definition string : Type :=
    list character.

  Module String.
    Definition equal: forall (l r: string), {l=r} + {l<>r}.
    Proof.
      decide equality.
      eauto using Character.equal.
    Defined.
    Definition length (str: string) : non_neg_integer :=
      List.length str.
    Definition substring (str: string) (s: non_neg_integer) (e: non_neg_integer) : string :=
      List.take (List.drop str s) (e - s).
    Definition advanceStringIndex (str: string) (i: non_neg_integer) : non_neg_integer :=
      S i.
    Definition getStringIndex (str: string) (i: non_neg_integer) : non_neg_integer :=
      i.
    Definition list_from_string (str: string) : list character :=
      str.
    Definition list_to_string (l: list character) : string :=
      l.
  End String.

  Module RBT := MSetRBT.Make OrdersEx.N_as_OT.
  Module CS := RBT.Raw.
  Definition char_set: Type := CS.t.

  Module CharSet.
    Definition empty: char_set := CS.empty.
    Definition from_list (l: list character) : char_set :=
      List.fold_left (fun cs c => CS.add c cs) l CS.empty.
    Definition union (cs0 cs1: char_set) : char_set :=
      CS.union cs0 cs1.
    Definition singleton (c: character) : char_set :=
      CS.singleton c.
    Definition size (cs: char_set) : nat :=
      CS.cardinal cs.
    Definition remove_all (l r: char_set) : char_set :=
      CS.diff l r.
    Definition is_empty (cs: char_set) : bool :=
      CS.is_empty cs.
    Definition contains (cs: char_set) (c: character) : bool :=
      CS.mem c cs.
    Definition range (first: character) (last: character) : char_set :=
      N.peano_rect
        (fun _ => CS.t) CS.empty (fun d cs => CS.add (first + d) cs)
        (N.succ last - first).
    Definition unique (F: Type) (_: Result.AssertionError F) (cs: char_set) : Result character F :=
      match cs with
      | CS.Leaf => Result.assertion_failed
      | CS.Node _ _ c _ => Result.Success c
      end.
    Definition filter (cs: char_set) (f: character -> bool) : char_set :=
      CS.filter f cs.
    Definition exist (cs: char_set) (f: character -> bool) : bool :=
      CS.exists_ f cs.
    Definition exist_canonicalized (rer: RegExpRecord) (cs: char_set) (c: character): bool :=
      exist
        cs
        (fun c0 =>
           if Character.equal (Character.canonicalize rer c0) c
           then true else false).
    Theorem singleton_size: forall c, size (singleton c) = 1%nat.
    Proof. reflexivity. Qed.
    Theorem singleton_exist: forall c p, exist (singleton c) p = p c.
    Proof. cbv; destruct p; reflexivity. Qed.
    Theorem singleton_unique: forall (F: Type) (af: Result.AssertionError F) c, @unique F af (singleton c) = Success c.
    Proof. reflexivity. Qed.
    Theorem exist_canonicalized_equiv rer cs c :
      exist_canonicalized rer cs c =
        exist
          cs
          (fun c0 =>
             if Character.equal (Character.canonicalize rer c0) c
             then true else false).
    Proof.
      reflexivity.
    Qed.
  End CharSet.

  Module CharSets.
    Definition N_range first last :=
      List.rev
        (N.peano_rect
           (fun _ => list N) [] (fun d cs => (first + d)%N :: cs)
           (N.succ last - first)%N).
    Definition all: list character :=
      Eval cbv in N_range 0 0x80.
    Definition line_terminators: list character := [
        (* line feed *) 0xA;
        (* vertical tab *) 0xB;
        (* form feed *) 0xC;
        (* carriage return *) 0xD
      ].
    Definition digits: list character :=
      Eval cbv in N_range 0x30 0x3A.
    Definition white_spaces: list character := [
        (* line feed *) 0x0A;
        (* line tabulation *) 0x0B;
        (* form feed *) 0x0C;
        (* carriage return *) 0x0D;
        (* space *) 0x20
      ].
    Definition ascii_word_characters: list character :=
      Eval cbv in (
          (N_range 65 91) ++ (* uppercase *)
            (N_range 97 123) ++ (* lowercase *)
            (N_range 48 58) ++ (* numbers *)
            [95] (* '_' *)
        ).
  End CharSets.

  Definition property: Type := list character.
  Module Property.
    Definition equal: forall (l r: property), {l=r} + {l<>r}.
    Proof.
      decide equality; eauto using Character.equal.
    Defined.
    Definition code_points (p: property) : list character :=
      p.
  End Property.
End FastEngineParameters.

Module NaiveEngine := API.Engine (NaiveEngineParameters).
Module FastEngine := API.Engine (NaiveEngineParameters).

Require Import Coq.Strings.Ascii Coq.Strings.String.
Open Scope string_scope.

Import API.Patterns Result.
Import List.ListNotations.
Open Scope list_scope.
(* Import NaiveEngine. *)
Import FastEngine.

Definition get_success {S F} (r: Result S F) : match r with Success _ => S | Error _ => unit end :=
  match r with
  | Success s => s
  | Error f => tt
  end.

Definition string_of_String (s: Coq.Strings.String.string) :=
  List.map Byte.to_nat (String.list_byte_of_string s).

Definition character_of_Ascii (a: Coq.Strings.Ascii.ascii) :=
  Byte.to_nat (byte_of_ascii a).

Example flags :=
  (RegExpFlags.make false false false false false tt false).

Notation "! r" := (get_success (initialize r flags)) (at level 0).
Notation "$ c" := (character_of_Ascii c) (at level 0).
Notation "$$ s" := (string_of_String s) (at level 0).

Time Compute
  rmatch
    ! (Char $ "l")
    $$ "hello".

Time Compute
  rmatch
    ! (Char $ "z")
    $$ "hello".

Time Compute
  rmatch
    ! (Quantified (Char $ "l") (Greedy Plus))
    $$ "hello".

Time Compute
  rmatch
    ! (Quantified
         (Seq
            (Quantified (Char $ "a") (Greedy Question))
            (Quantified (Char $ "b") (Lazy Question)))
         (Greedy Star))
    $$ "ab".

Time Compute
  rmatch
    ! (Quantified
         (Group
            None
            (Seq
               (Quantified (Char $ "a") (Greedy Question))
               (Quantified (Char $ "b") (Lazy Question))))
         (Greedy Star))
    $$ "ab".
