From Stdlib Require Import PeanoNat ZArith Bool Lia List.
From Warblre Require Import List Typeclasses Result Base Errors Patterns Node NodeProps Notation StaticSemantics Semantics EarlyErrors Match RegExpRecord Frontend.

Import Result.Notations.
Local Open Scope result_flow.

(**
    This file shows that RegExpBuiltinExec never fails on a RegExp instance built by RegExpInitialize.
*)
Section BuiltinExec.
  Context `{specParameters: Parameters}.
  Import Patterns.
  Import Notation.
  Import Semantics.
  Import StaticSemantics.

  (* Strings whose indices are character indices. *)
  Definition PlainString (str: String) :=
    String.length str = length (String.to_char_list str) /\
    (forall i, String.advanceStringIndex str i = Datatypes.S i) /\
    (forall i, String.getStringIndex str i = i).

  (* RegExp instances whose matcher is the compiled pattern of an early-error-free source. *)
  Record Initialized (R: RegExpInstance) : Prop := {
    initialized_early_errors: EarlyErrors.Pass_Regex (RegExpInstance.originalSource R) nil;
    initialized_groups: countLeftCapturingParensWithin (RegExpInstance.originalSource R) nil =
      RegExpRecord.capturingGroupsCount (RegExpInstance.regExpRecord R);
    initialized_matcher: compilePattern (RegExpInstance.originalSource R) (RegExpInstance.regExpRecord R) =
      Success (RegExpInstance.regExpMatcher R);
    initialized_last_index: (0 <= RegExpInstance.lastIndex R)%Z;
  }.

  Lemma regExpInitialize_initialized: forall pattern flags R,
    StaticSemantics.earlyErrors pattern nil = Success false ->
    regExpInitialize pattern flags = Success R ->
    Initialized R.
  Proof.
    intros pattern flags R EE Eq_R. unfold regExpInitialize in Eq_R.
    destruct compilePattern eqn:Eq_m; cbn in Eq_R; [ | discriminate ].
    injection Eq_R as <-. constructor; cbn; auto using EarlyErrors.earlyErrors; lia.
  Qed.

  Lemma setLastIndex_initialized: forall R i, Initialized R -> (0 <= i)%Z -> Initialized (RegExpInstance.setLastIndex R i).
  Proof. intros R i [] Le. constructor; assumption. Qed.

  Local Ltac step := cbn [Result.bind negb andb orb length MatchRecord.startIndex MatchRecord.endIndex].
  Local Ltac leb_true := repeat match goal with
    | [ |- context[ Nat.leb ?a ?b ] ] => rewrite (proj2 (Nat.leb_le a b)) by lia
    end.

  Lemma from_int_nonneg {F} `{Result.AssertionError F}: forall z, (0 <= z)%Z ->
    NonNegInt.from_int z = (Success (Z.to_nat z): Result non_neg_integer F).
  Proof. intros z Le. unfold NonNegInt.from_int. destruct (Z.geb_spec z 0); [ reflexivity | lia ]. Qed.

  (** The repeat loop *)
  Section Loop.
    Context (str: String) (Plain: PlainString str).

    Lemma to_list_index_plain: forall i, to_list_index i str = Success i.
    Proof.
      intros i. destruct Plain as (_ & Adv & _). unfold to_list_index.
      match goal with
      | [ |- ?iter _ _ = _ ] =>
          enough (forall c, c <= i -> iter c (i - c) = Success i) as H by (specialize (H i (le_n i)); rewrite Nat.sub_diag in H; exact H)
      end.
      induction c as [ | c IH ]; intros Le; cbv beta iota.
      - rewrite Nat.sub_0_r, EqDec.reflb. reflexivity.
      - rewrite (proj2 (EqDec.inversion_false _ _)) by lia.
        rewrite Adv. replace (S (i - S c)) with (i - c) by lia. apply IH. lia.
    Qed.

    Lemma repeat_matcher_loop_success: forall R global sticky fuel i,
      Initialized R -> S (String.length str) - i < fuel ->
      exists lr, repeat_matcher_loop R str (String.length str) global sticky
          (RegExpInstance.regExpMatcher R) (String.to_char_list str) i fuel = Success lr /\
        forall st j, lr = Continues st j ->
          Match.MatchState.Valid (String.to_char_list str) (RegExpInstance.regExpRecord R) st /\
          (Z.of_nat j <= MatchState.endIndex st)%Z.
    Proof.
      intros R global sticky fuel i [ EE Groups Matcher _ ]. destruct Plain as (Len & Adv & _).
      revert i. induction fuel as [ | fuel IH ]; intros i Fuel; [ lia | ]. cbn [repeat_matcher_loop].
      destruct (Nat.leb (S (String.length str)) i) eqn:Over.
      { eexists. split; [ reflexivity | discriminate ]. }
      apply Nat.leb_gt in Over.
      rewrite to_list_index_plain. step.
      pose proof (Match.termination _ _ (String.to_char_list str) i _ EE Groups Matcher) as Fuel_m.
      pose proof (Match.no_failure _ _ (String.to_char_list str) i _ EE Groups Matcher ltac:(lia)) as Fail_m.
      destruct (RegExpInstance.regExpMatcher R (String.to_char_list str) i) as [ [ st | ] | [] ] eqn:Eq_m;
        try contradiction; step.
      - rewrite (proj2 (EqDec.inversion_false _ _)) by discriminate. cbn.
        eexists. split; [ reflexivity | ]. intros ? ? [=<-<-]. split.
        + eapply Match.validity; eassumption.
        + eapply Match.monotony'; eassumption.
      - rewrite EqDec.reflb. destruct sticky.
        + eexists. split; [ reflexivity | discriminate ].
        + rewrite Adv. apply IH. lia.
    Qed.
  End Loop.

  (** The packaging steps *)
  Section Finish.
    Context (str: String) (Plain: PlainString str).
    Local Notation input := (String.to_char_list str).

    Definition RecordOn (o: option MatchRecord) := match o with
    | None => True
    | Some m => MatchRecord.startIndex m <= MatchRecord.endIndex m <= String.length str
    end.

    Lemma capture_success: forall c, Match.CaptureRange.Valid input c ->
      (exists v, capture_to_value str c = Success v) /\
      (exists m, capture_to_record str c = Success m /\ RecordOn m).
    Proof.
      destruct Plain as (Len & _ & Get).
      intros c [ s e Le Is Ie | ]; [ | split; eexists; [ reflexivity | split; [ reflexivity | exact I ] ] ].
      unfold Match.IteratorOn in *. unfold capture_to_value, capture_to_record, MatchRecord.make, getMatchString.
      cbn [CaptureRange.startIndex CaptureRange.endIndex].
      rewrite !from_int_nonneg by lia. step. rewrite !Get. cbv beta. leb_true. step. leb_true. step.
      split; eexists; [ reflexivity | split; [ reflexivity | cbn; lia ] ].
    Qed.

    Lemma captures_success: forall caps, List.Forall.Forall caps (Match.CaptureRange.Valid input) ->
      (exists a, captures_to_array str caps = Success a /\ length a = length caps) /\
      (exists l, captures_to_indices str caps = Success l /\ length l = length caps /\ Forall RecordOn l).
    Proof.
      induction caps as [ | c caps IH ]; intros V; [ split; eexists; repeat split; constructor | ].
      apply List.Forall.cons_inv in V as [ V_c V ].
      destruct (capture_success c V_c) as [ (v & Eq_v) (m & Eq_m & R_m) ].
      destruct (IH V) as [ (a & Eq_a & L_a) (l & Eq_l & L_l & R_l) ].
      cbn. rewrite Eq_v, Eq_m, Eq_a, Eq_l. step.
      split; eexists; repeat split; cbn; auto.
    Qed.

    Lemma indices_success: forall l, Forall RecordOn l ->
      (exists a, makeMatchIndicesArray str l = Success a) /\
      (forall names, length names = length l -> exists g, makeMatchIndicesGroupList str l names = Success g).
    Proof.
      induction 1 as [ | o l R_o _ [ (a & Eq_a) IH ] ];
        [ split; [ eexists; reflexivity | intros [ | ] [=]; eexists; reflexivity ] | ].
      assert (exists p, match o with
        | Some m => let! p =<< getMatchIndexPair str m in Success (Some p)
        | None => Success None
        end = Success p) as [ p Eq_p ].
      { destruct o as [ m | ]; [ | eexists; reflexivity ].
        unfold getMatchIndexPair. cbn in R_o. leb_true. step. eexists; reflexivity. }
      cbn. rewrite Eq_p. step. split.
      - rewrite Eq_a. eexists; reflexivity.
      - intros [ | n names ] [=L]. destruct (IH names L) as [ g -> ]. step.
        destruct n; eexists; reflexivity.
    Qed.

    Lemma group_count: forall r ctx, length (all_groups_in (r, ctx)) = countLeftCapturingParensWithin r ctx.
    Proof.
      unfold all_groups_in, countLeftCapturingParensWithin.
      induction r; intros ctx; cbn [Zipper.Walk.walk filter countLeftCapturingParensWithin_impl];
        rewrite ?filter_app, ?length_app; cbn [length]; auto.
    Qed.

    Lemma nth_group_success: forall r k, 1 <= k <= countLeftCapturingParensWithin r nil ->
      exists name body ctx, @nth_group _ MatchError _ r k = Success (Group name body, ctx).
    Proof.
      intros r k Bounds. rewrite <- group_count in Bounds.
      unfold nth_group, nth_group_in, indexing, index_using, nat_indexer, List.Indexing.Nat.indexing.
      destruct (Nat.eqb_spec k 0); [ lia | ].
      destruct (nth_error (all_groups_in (r, nil)) (k - 1)) as [ node | ] eqn:Eq_node;
        [ | apply nth_error_None in Eq_node; lia ].
      apply nth_error_In, filter_In in Eq_node as [ _ Is_group ].
      destruct node as [ [] ctx ]; try discriminate. do 3 eexists. reflexivity.
    Qed.

    Lemma groups_success: forall r caps k, List.Forall.Forall caps (Match.CaptureRange.Valid input) ->
      1 <= k -> k - 1 + length caps <= countLeftCapturingParensWithin r nil ->
      (exists g, captures_to_groupsmap r str caps k = Success g) /\
      (exists names, captures_to_groupnames r caps k = Success names /\ length names = length caps).
    Proof.
      induction caps as [ | c caps IH ]; intros k V Low High; [ split; eexists; repeat split; constructor | ].
      apply List.Forall.cons_inv in V as [ V_c V ].
      destruct (capture_success c V_c) as [ (v & Eq_v) _ ].
      destruct (nth_group_success r k ltac:(cbn in High; lia)) as (name & body & ctx & Eq_node).
      destruct (IH (k + 1) V ltac:(lia) ltac:(cbn in High; lia)) as [ (g & Eq_g) (names & Eq_names & L_names) ].
      cbn [captures_to_groupsmap captures_to_groupnames]. rewrite Eq_v, Eq_node. step. rewrite Eq_g, Eq_names. step.
      destruct name; split; (eexists; split; [ reflexivity | cbn; lia ]) || (eexists; reflexivity).
    Qed.
  End Finish.

  (** RegExpBuiltinExec never fails. *)
  Theorem regExpBuiltinExec_success: forall R str,
    Initialized R -> PlainString str ->
    exists res, regExpBuiltinExec R str = Success res.
  Proof.
    intros R str Init Plain. pose proof Plain as (Len & _ & Get).
    unfold regExpBuiltinExec. cbv zeta.
    rewrite from_int_nonneg by (destruct Init; destruct (_ && _); lia). step.
    match goal with
    | [ |- context[ repeat_matcher_loop _ _ _ ?g ?y _ _ ?i ?f ] ] =>
        destruct (repeat_matcher_loop_success str Plain R g y f i Init ltac:(lia)) as ([ res | st i' ] & -> & Valid)
    end; step; [ eauto | ].
    destruct (Valid st i' eq_refl) as [ (_ & End & L_caps & V_caps) Start ]. unfold Match.IteratorOn in End.
    pose proof (initialized_groups _ Init) as Groups.
    destruct (captures_success str Plain _ V_caps) as [ (a & Eq_a & L_a) (l & Eq_l & L_l & R_l) ].
    destruct (groups_success str Plain (RegExpInstance.originalSource R) _ 1 V_caps ltac:(lia) ltac:(lia))
      as [ (g & Eq_g) (names & Eq_names & L_names) ].
    unfold MatchRecord.make, getMatchString, captures_to_groups_map,
      captures_to_group_names, MakeMatchIndicesGroups.
    rewrite from_int_nonneg by lia. step. rewrite Get.
    match goal with
    | [ |- context[ if ?b then RegExpInstance.setLastIndex _ _ else _ ] ] => destruct b
    end; unfold RegExpInstance.setLastIndex; cbn [RegExpInstance.regExpRecord RegExpInstance.originalSource];
      rewrite L_caps, Nat.eqb_refl; step; cbv beta; leb_true; step;
      rewrite Eq_a, Eq_l, Eq_names; step; leb_true; step; rewrite L_a, L_caps, Nat.add_1_r, Nat.eqb_refl; step;
      destruct (indices_success str (Some (MatchRecord.mk i' (Z.to_nat (MatchState.endIndex st))) :: l)
        ltac:(constructor; cbn; [ lia | assumption ])) as [ (ia & Eq_ia) _ ];
      destruct (proj2 (indices_success str l R_l) names ltac:(lia)) as (ig & Eq_ig).
    all: destruct (defines_groups _); [ rewrite Eq_g | ]; step;
      destruct (RegExpFlags.d _); step; try rewrite Eq_ia; step;
      rewrite ?L_names, ?L_l, ?Nat.sub_succ, ?Nat.sub_0_r, ?Nat.eqb_refl; step; try rewrite Eq_ig; step;
      eexists; reflexivity.
  Qed.

  (** RegExpBuiltinExec never fails on a freshly initialized RegExp instance. *)
  Corollary regExpInitialize_exec_success: forall pattern flags R str,
    StaticSemantics.earlyErrors pattern nil = Success false ->
    regExpInitialize pattern flags = Success R ->
    PlainString str ->
    exists res, regExpBuiltinExec R str = Success res.
  Proof. eauto using regExpBuiltinExec_success, regExpInitialize_initialized. Qed.
End BuiltinExec.
