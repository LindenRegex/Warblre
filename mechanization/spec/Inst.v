From Warblre Require Import API.
From Warblre Require Import Frontend.
From Stdlib Require Import Lia NArith ZArith Eqdep_dec.

(* This is one instantiation of the alphabet that can be executed within Rocq. *)
(* This encodes the ASCII alphabet *)

(* TODOs:

   - Merge CharSetExt into CharSet.
     Use MSet API + a few functions / proofs.
   - Update NaiveEngineParameters with new functions.
   - Linden: instantiate and test
 *)

Module Type Alphabet.
  Import RegExpRecord.

  Parameter max: N.
  Parameter canonicalize: RegExpRecord -> nat -> nat.
  Axiom canonicalize_casesenst: forall rer n, RegExpRecord.ignoreCase rer = false -> canonicalize rer n = n.

  Parameter line_terminators: list nat.
  Parameter digits: list nat.
  Parameter white_spaces: list nat.
  Parameter ascii_word_characters: list nat.
End Alphabet.

Module BoundedEngineParameters (A: Alphabet) <: API.EngineParameters.
  Import RegExpRecord Numeric List PeanoNat Result.
  Import List.ListNotations.
  Open Scope list_scope.

  Record bounded := make { value: N; value_bound: N.leb value A.max = true }.

  Definition character: Type := bounded.

  Lemma clamp_bound: forall n, N.leb (N.min n A.max) A.max = true.
  Proof. intro n. apply N.leb_le, N.le_min_r. Qed.

  Definition clamp (n: N): character := make (N.min n A.max) (clamp_bound n).

  Lemma value_inj: forall c d, value c = value d -> c = d.
  Proof. intros [n Hn] [m Hm]; cbn; intros <-. f_equal. apply UIP_dec, Bool.bool_dec. Qed.

  Module Character.
    Definition from_numeric_value (n: nat): character :=
      clamp (N.of_nat n).
    Definition numeric_value (c: character) : nat :=
      N.to_nat (value c).

    Definition equal (c d: character): {c = d} + {c <> d} :=
      match N.eq_dec (value c) (value d) with
      | left E => left (value_inj c d E)
      | right NE => right (fun E => NE (f_equal value E))
      end.

    Lemma numeric_bound: forall c, numeric_value c <= N.to_nat A.max.
    Proof.
      intros [n Hn]; unfold numeric_value; cbn. destruct (N.leb_spec n A.max); [lia|discriminate].
    Qed.

    Lemma numeric_round_trip: forall n, numeric_value (from_numeric_value n) = Nat.min n (N.to_nat A.max).
    Proof.
      intro n; unfold numeric_value, from_numeric_value, clamp; cbn. lia.
    Qed.

    Definition canonicalize (r: RegExpRecord) (ch: character): character :=
      from_numeric_value (A.canonicalize r (numeric_value ch)).

    Theorem numeric_pseudo_bij: forall c, from_numeric_value (numeric_value c) = c.
    Proof.
      intro c. apply value_inj, N2Nat.inj. change (numeric_value (from_numeric_value (numeric_value c)) = numeric_value c).
      rewrite numeric_round_trip. pose proof (numeric_bound c). lia.
    Qed.

    Theorem numeric_round_trip_order: forall l r, l <= r -> (numeric_value (from_numeric_value l)) <= (numeric_value (from_numeric_value r)).
    Proof. intros; rewrite !numeric_round_trip; lia. Qed.

    Theorem canonicalize_casesenst: forall rer chr, RegExpRecord.ignoreCase rer = false -> canonicalize rer chr = chr.
    Proof. intros rer chr H. unfold canonicalize. rewrite A.canonicalize_casesenst by assumption. apply numeric_pseudo_bij. Qed.

    Lemma in_map_from_numeric_value: forall c l, List.forallb (fun n => n <=? N.to_nat A.max) l = true ->
      List.In c (List.map from_numeric_value l) <-> List.In (numeric_value c) l.
    Proof.
      intros c l BOUND. rewrite List.forallb_forall in BOUND. rewrite List.in_map_iff. split.
      - intros (n & <- & IN). rewrite numeric_round_trip, Nat.min_l by (apply Nat.leb_le, BOUND, IN). exact IN.
      - eauto using numeric_pseudo_bij.
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

  Definition char_set: Type := ListSet.set character.

  Module CharSet.
    Definition empty: char_set := ListSet.empty_set character.
    Definition from_list (l: list character) : char_set := List.nodup Character.equal l.
    Definition union (cs0 cs1: char_set) : char_set := ListSet.set_union Character.equal cs0 cs1.
    Definition singleton (c: character) : char_set := [c].
    Definition size (cs: char_set) : nat := List.length (List.nodup Character.equal cs).
    Definition remove_all (l r: char_set) : char_set := ListSet.set_diff Character.equal l r.
    Definition is_empty (cs: char_set) : bool := size cs =? 0.
    Definition elements (cs: char_set): list character := List.nodup Character.equal cs.
    Definition contains (cs: char_set) (c: character) : bool := ListSet.set_mem Character.equal c cs.
    Definition range (first: character) (last: character) : char_set :=
      List.map Character.from_numeric_value
        (List.Range.Nat.Bounds.range (Character.numeric_value first) (Character.numeric_value last + 1)).
    Definition unique (F: Type) (_: Result.AssertionError F) (cs: char_set) : Result character F :=
      match List.nodup Character.equal cs with
      | [x] => Result.Success x (* Assumes deduplicated ListSet *)
      | _ => Result.assertion_failed
      end.
    Definition filter (cs: char_set) (f: character -> bool) : char_set :=
      List.filter f cs.
    Definition exist (cs: char_set) (f: character -> bool) : bool :=
      List.existsb f cs.
    Definition exist_canonicalized (rer: RegExpRecord) (cs: char_set) (c: character): bool :=
      contains (List.map (Character.canonicalize rer) cs) c.

    (*Theorem singleton_size: forall c, size (singleton c) = 1.
    Proof. reflexivity. Qed.
    Theorem singleton_exist: forall c p, exist (singleton c) p = p c.
    Proof. cbv; destruct p; reflexivity. Qed.
    Theorem singleton_unique: forall (F: Type) (af: Result.AssertionError F) c, @unique F af (singleton c) = Success c.
    Proof. reflexivity. Qed.*)
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
    Definition In : character -> char_set -> Prop := @ListSet.set_In character.
    Definition Equal s1 s2 := forall c, In c s1 <-> In c s2.
    Definition Empty s := forall c, ~In c s.
    Definition Exists (P: character -> Prop) s := exists c, In c s /\ P c.
    Theorem empty_spec: forall c, ~In c empty.
    Proof. intros c []. Qed.
    Theorem from_list_spec: forall c l, In c (from_list l) <-> List.In c l.
    Proof.
      intros c l. unfold from_list, In, ListSet.set_In.
      apply List.nodup_In.
    Qed.
    Theorem union_spec: forall c s1 s2, In c (union s1 s2) <-> In c s1 \/ In c s2.
    Proof. apply ListSet.set_union_iff. Qed.
    Theorem singleton_spec: forall x c, In x (singleton c) <-> c = x.
    Proof.
      intros x c. split.
      - intros []; auto. inversion H.
      - intros ->. left. reflexivity.
    Qed.
    Theorem size_spec: forall s, size s = List.length (elements s).
    Proof. reflexivity. Qed.
    Theorem remove_all_spec: forall c s1 s2, In c (remove_all s1 s2) <-> In c s1 /\ ~In c s2.
    Proof. apply ListSet.set_diff_iff. Qed.
    Theorem is_empty_spec: forall s, is_empty s = true <-> Empty s.
    Proof.
      intro s. unfold is_empty, size.
      split.
      - rewrite Nat.eqb_eq. intros H x IN. apply <- (List.nodup_In Character.equal) in IN.
        apply List.length_zero_iff_nil in H. rewrite H in IN. destruct IN.
      - unfold Empty. intro NOTHING. destruct (List.nodup Character.equal s) eqn:Heqnodups; try reflexivity.
        exfalso. apply NOTHING with (c := c). apply (List.nodup_In Character.equal).
        rewrite Heqnodups. left. reflexivity.
    Qed.
    Theorem contains_spec: forall c s, contains s c = true <-> In c s.
    Proof.
      intros c s. split; intro H.
      - apply ListSet.set_mem_correct1 with (Aeq_dec := Character.equal). auto.
      - apply ListSet.set_mem_correct2 with (Aeq_dec := Character.equal). auto.
    Qed.

    (* TODO copied from Linden; should be somewhere else*)
    Theorem range_spec: forall c l h, In c (range l h) <-> Character.numeric_value l <= Character.numeric_value c /\ Character.numeric_value c <= Character.numeric_value h.
    Proof.
      intros c l h. unfold In, ListSet.set_In, range, List.Range.Nat.Bounds.range.
      pose proof (Character.numeric_bound h). rewrite List.Range.Nat.Length.range_seq, Character.in_map_from_numeric_value, List.in_seq; [lia|].
      apply List.forallb_forall. intros n IN%List.in_seq. apply Nat.leb_le. lia.
    Qed.

    Lemma Equal_singleton_nodup:
      forall s c, Equal s (singleton c) <-> List.nodup Character.equal s = [c].
    Proof.
      intros s c. induction s.
      - simpl. split; intro H.
        + exfalso. specialize (H c) as [Hl Hr]. apply Hr. left. reflexivity.
        + discriminate H.
      - destruct s as [|b s].
        + unfold singleton. simpl. split; intro H.
          * f_equal. specialize (H a) as [Hl Hr]. specialize (Hl (or_introl eq_refl)).
            destruct Hl; [auto|contradiction].
          * inversion H. subst. intro c0. split; auto.
        + split.
          * intro EQUAL.
            replace a with c in *. 2: {
              specialize (EQUAL a) as [EQUALl EQUALr].
              specialize (EQUALl (or_introl eq_refl)).
              destruct EQUALl; [auto|contradiction].
            }
            replace b with c in *. 2: {
              specialize (EQUAL b) as [EQUALl EQUALr].
              specialize (EQUALl (or_intror (or_introl eq_refl))).
              destruct EQUALl; [auto|contradiction].
            }
            assert (Equal (c::s) (singleton c)). {
              intro c0. split; intro H.
              - apply EQUAL. right. auto.
              - destruct H; [|inversion H]. subst c0. left. reflexivity.
            }
            remember (c::s) as s'. simpl.
            destruct (List.in_dec Character.equal c s').
            2: { exfalso. apply n. rewrite Heqs'. left. reflexivity. }
            apply IHs. auto.
          * remember (b::s) as s'. simpl.
            destruct List.in_dec.
            -- intro H. rewrite <- IHs in H.
               intro c0. split; intro.
               ++ destruct H0.
                  ** subst c0. specialize (proj1 (H a) i). auto.
                  ** apply H. auto.
               ++ right. apply H. auto.
            -- destruct List.nodup eqn:?. 2: discriminate.
               replace s' with (@nil character). 2: {
                 symmetry.
                 assert (forall c0, ~List.In c0 s'). {
                   intro c0. rewrite <- List.nodup_In with (decA := Character.equal), Heql.
                   apply List.in_nil.
                 }
                 destruct s'; auto. exfalso. apply (H c0). left. reflexivity.
               }
               intro H. inversion H. subst.
               intro c0. split; auto.
    Qed.


    Theorem unique_succ_spec: forall (F: Type) (H: Result.AssertionError F) (c: character) (s: char_set),
      unique F H s = Success c <-> Equal s (singleton c).
    Proof.
      intros F H c s. split.
      - unfold unique, Result.assertion_failed. destruct H.
        destruct List.nodup eqn:?; try discriminate.
        destruct l; try discriminate.
        intro H. injection H as ->. apply Equal_singleton_nodup. auto.
      - intro H0. unfold unique. apply Equal_singleton_nodup in H0. rewrite H0. reflexivity.
    Qed.
    Theorem unique_succ_error: forall (F: Type) (H: Result.AssertionError F) (s: char_set),
      (exists c, unique F H s = Success c) \/ unique F H s = Error (@Result.f F H).
    Proof.
      intros F H s. unfold unique.
      destruct List.nodup.
      - right. unfold Result.assertion_failed, Result.f. destruct H. reflexivity.
      - destruct l. + left. eexists. reflexivity. +  right. unfold Result.assertion_failed, Result.f. destruct H. reflexivity.
    Qed.
    Theorem filter_spec: forall f c s,
      In c (filter s f) <-> In c s /\ f c = true.
    Proof. apply List.filter_In. Qed.
    Theorem exist_spec: forall f s,
      exist s f = true <-> Exists (fun c => f c = true) s.
    Proof. apply List.existsb_exists. Qed.
    Theorem elements_spec1: forall c s, List.In c (elements s) <-> In c s.
    Proof. intros c s. apply List.nodup_In. Qed.
    Theorem elements_spec2: forall s, List.NoDup (elements s).
    Proof. intros s. apply List.NoDup_nodup. Qed.

    Lemma union_empty_actual s: union s empty = s.
    Proof. reflexivity. Qed.

    Lemma Empty_empty s: Empty s -> s = CharSet.empty.
    Proof.
      destruct s.
      - reflexivity.
      - intro H. exfalso. unfold Empty in H. exact (H c (or_introl eq_refl)).
    Qed.

    Theorem union_empty: forall s e, Empty e -> union s e = s.
    Proof.
      intros; rewrite (Empty_empty e) by assumption.
      reflexivity.
    Qed.
  End CharSet.

  Module CharSets.
    Definition all: list character :=
      List.map (fun z => clamp (Z.to_N z)) (List.Range.Int.Length.range 0 (S (N.to_nat A.max))).
    Definition line_terminators: list character :=
      List.map Character.from_numeric_value A.line_terminators.
    Definition digits: list character :=
      List.map Character.from_numeric_value A.digits.
    Definition white_spaces: list character :=
      List.map Character.from_numeric_value A.white_spaces.
    Definition ascii_word_characters: list character :=
      List.map Character.from_numeric_value A.ascii_word_characters.

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
End BoundedEngineParameters.

Module Ascii <: Alphabet.
  Import RegExpRecord List PeanoNat.
  Import List.ListNotations.

  Definition max: N := 0x7F.

  (* ascii-specific canonicalization *)
  (* following https://unicode.org/Public/UCD/latest/ucd/CaseFolding.txt *)
  Definition canonicalize (r: RegExpRecord) (ch: nat): nat :=
    if (RegExpRecord.ignoreCase r && (0x41 <=? ch) && (ch <=? 0x5A))%bool then ch + 0x20 else ch.

  Theorem canonicalize_casesenst: forall rer n, RegExpRecord.ignoreCase rer = false -> canonicalize rer n = n.
  Proof. intros rer n H. unfold canonicalize. rewrite H. auto. Qed.

  Definition line_terminators: list nat := [
      (* line feed *) 0xA;
      (* vertical tab *) 0xB;
      (* form feed *) 0xC;
      (* carriage return *) 0xD
    ].
  Definition digits: list nat :=
    Eval cbv in List.Range.Nat.Bounds.range 0x30 0x3A.
  Definition white_spaces: list nat := [
      (* line feed *) 0x0A;
      (* line tabulation *) 0x0B;
      (* form feed *) 0x0C;
      (* carriage return *) 0x0D;
      (* space *) 0x20
    ].
  Definition ascii_word_characters: list nat :=
    Eval cbv in (
        (List.Range.Nat.Bounds.range 65 91) ++ (* uppercase *)
          (List.Range.Nat.Bounds.range 97 123) ++ (* lowercase *)
          (List.Range.Nat.Bounds.range 48 58) ++ (* numbers *)
          [95] (* '_' *)
      ).
End Ascii.

Module NaiveEngineParameters := BoundedEngineParameters Ascii.



Module NaiveEngine := API.Engine (NaiveEngineParameters).

Require Import Stdlib.Strings.Ascii Stdlib.Strings.String.
Open Scope string_scope.

Import API.Patterns Result.
Import List.ListNotations.
Open Scope list_scope.
Import NaiveEngine.

Definition get_success {S F: Type} (r: Result S F) : match r with Success _ => S | Error _ => unit end :=
  match r with
  | Success s => s
  | Error f => tt
  end.

Definition string_of_String (s: Stdlib.Strings.String.string) :=
  List.map (fun b => NaiveEngineParameters.Character.from_numeric_value (Byte.to_nat b)) (String.list_byte_of_string s).

Definition character_of_Ascii (a: Stdlib.Strings.Ascii.ascii) :=
  NaiveEngineParameters.Character.from_numeric_value (Byte.to_nat (byte_of_ascii a)).

Example flags :=
  (RegExpFlags.make false false false false false tt false).

Notation "! r" := (get_success (initialize r flags)) (at level 9).
Notation "$ c" := (character_of_Ascii c) (at level 9).
Notation "$$ s" := (string_of_String s) (at level 9).

(* Hide the matching functions in the outputs below*)
Arguments Exotic {C S UP}%_type_scope {H H0 H1} _ {_}.
Arguments Null {C S UP}%_type_scope {H H0 H1} {_}.

(*
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
    $$ "ab". *)
