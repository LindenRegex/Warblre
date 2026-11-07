From Stdlib Require Import PeanoNat ZArith Bool Lia List.
From Warblre Require Import List Typeclasses Result Base Errors Patterns Node NodeProps Notation StaticSemantics Semantics EarlyErrors Match RegExpRecord Frontend.

Import Result.Notations.
Local Open Scope result_flow.

(**
    This file shows that RegExpBuiltinExec never fails on a RegExp instance built by RegExpInitialize,
    and describes the array it returns after a successful search.
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

  (* The substring, match record and index pair of a capture range, and back. *)
  Local Notation substring_at str := (fun r => String.substring str
    (Z.to_nat (CaptureRange.startIndex r)) (Z.to_nat (CaptureRange.endIndex r))).
  Local Notation record_at := (fun r =>
    MatchRecord.mk (Z.to_nat (CaptureRange.startIndex r)) (Z.to_nat (CaptureRange.endIndex r))).
  Local Notation pair_at := (fun r => (Z.to_nat (CaptureRange.startIndex r), Z.to_nat (CaptureRange.endIndex r))).
  Local Notation unpair := (fun p => capture_range (Z.of_nat (fst p)) (Z.of_nat (snd p))).

  (* [g] pairs each group name with the value at that group's position. *)
  Definition Named {V} (names: list (option GroupName)) (values: list V) (g: list (GroupName * V)) :=
    forall name v, In (name, v) g <-> exists k, nth_error names k = Some (Some name) /\ nth_error values k = Some v.

  Lemma named_nil {V}: Named nil (@nil V) nil.
  Proof. intros name v. split; [ intros [] | intros ([ | ] & [=] & _) ]. Qed.

  Lemma named_cons {V}: forall n names (v: V) values g, Named names values g ->
    Named (n :: names) (v :: values) (match n with Some s => (s, v) :: g | None => g end).
  Proof.
    intros n names v values g N name w. split.
    - intros In_g. destruct n as [ s | ]; [ destruct In_g as [ [=<-<-] | In_g ]; [ exists 0; auto | ] | ];
        apply N in In_g as (k & ? & ?); exists (S k); auto.
    - intros ([ | k ] & Eq_n & Eq_v); cbn in Eq_n, Eq_v; [ injection Eq_n as ->; injection Eq_v as ->; now left | ].
      destruct n; [ right | ]; apply N; eauto.
  Qed.

  (** The packaging steps *)
  Section Finish.
    Context (str: String) (Plain: PlainString str).
    Local Notation input := (String.to_char_list str).

    Lemma capture_success: forall c, Match.CaptureRange.Valid input c ->
      capture_to_value str c = Success (option_map (substring_at str) c) /\
      capture_to_record str c = Success (option_map record_at c) /\
      match option_map record_at c with
      | Some m => let! p =<< getMatchIndexPair str m in Success (Some p)
      | None => Success None
      end = Success (option_map pair_at c) /\
      option_map unpair (option_map pair_at c) = c.
    Proof.
      destruct Plain as (Len & _ & Get).
      intros c [ s e Le Is Ie | ]; [ | repeat split ].
      unfold Match.IteratorOn in *. unfold capture_to_value, capture_to_record, MatchRecord.make, getMatchString, getMatchIndexPair.
      cbn [CaptureRange.startIndex CaptureRange.endIndex option_map].
      rewrite !from_int_nonneg by lia. step. rewrite !Get. cbv beta. leb_true. step. leb_true. step.
      repeat split. cbn. rewrite !Z2Nat.id by lia. reflexivity.
    Qed.

    Lemma captures_success: forall caps, List.Forall.Forall caps (Match.CaptureRange.Valid input) ->
      captures_to_array str caps = Success (map (option_map (substring_at str)) caps) /\
      captures_to_indices str caps = Success (map (option_map record_at) caps) /\
      makeMatchIndicesArray str (map (option_map record_at) caps) = Success (map (option_map pair_at) caps) /\
      map (option_map unpair) (map (option_map pair_at) caps) = caps /\
      forall names, length names = length caps -> exists g,
        makeMatchIndicesGroupList str (map (option_map record_at) caps) names = Success g /\
        Named names (map (option_map pair_at) caps) g.
    Proof.
      induction caps as [ | c caps IH ]; intros V.
      { repeat split. intros [ | ] [=]. eexists. split; [ reflexivity | apply named_nil ]. }
      apply List.Forall.cons_inv in V as [ V_c V ].
      destruct (capture_success c V_c) as (Eq_v & Eq_r & Eq_p & Eq_c). destruct (IH V) as (Eq_a & Eq_l & Eq_i & Eq_cs & Eq_g).
      cbn [captures_to_array captures_to_indices makeMatchIndicesArray makeMatchIndicesGroupList map].
      rewrite Eq_v, Eq_r, Eq_a, Eq_l, Eq_p, Eq_i, Eq_c, Eq_cs. step. repeat split.
      intros [ | n names ] [=L]. destruct (Eq_g names L) as (g & -> & N). step.
      exists (match n with Some s => (s, option_map pair_at c) :: g | None => g end).
      split; [ destruct n; reflexivity | apply named_cons, N ].
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
      exists names, captures_to_groupnames r caps k = Success names /\ length names = length caps /\
      exists g, captures_to_groupsmap r str caps k = Success g /\ Named names (map (option_map (substring_at str)) caps) g.
    Proof.
      induction caps as [ | c caps IH ]; intros k V Low High.
      { eexists. split; [ reflexivity | split; [ reflexivity | eexists; split; [ reflexivity | apply named_nil ] ] ]. }
      apply List.Forall.cons_inv in V as [ V_c V ].
      destruct (capture_success c V_c) as (Eq_v & _).
      destruct (nth_group_success r k ltac:(cbn in High; lia)) as (name & body & ctx & Eq_node).
      destruct (IH (k + 1) V ltac:(lia) ltac:(cbn in High; lia)) as (names & Eq_names & L_names & g & Eq_g & N).
      cbn [captures_to_groupsmap captures_to_groupnames map]. rewrite Eq_v, Eq_node. step. rewrite Eq_g, Eq_names. step.
      eexists. split; [ destruct name; reflexivity | split; [ cbn; lia | ] ].
      exists (match name with Some s => (s, option_map (substring_at str) c) :: g | None => g end).
      split; [ destruct name; reflexivity | apply named_cons, N ].
    Qed.
  End Finish.

  (** A successful search yields the exec array of its match. *)
  Theorem regExpBuiltinExec_exotic: forall R str st i,
    Initialized R -> PlainString str ->
    let flags := RegExpInstance.originalFlags R in
    let src := RegExpInstance.originalSource R in
    let start := if RegExpFlags.g flags || RegExpFlags.y flags then Z.to_nat (RegExpInstance.lastIndex R) else 0 in
    repeat_matcher_loop R str (String.length str) (RegExpFlags.g flags) (RegExpFlags.y flags)
      (RegExpInstance.regExpMatcher R) (String.to_char_list str) start (length (String.to_char_list str) + 2) =
      Success (Continues st i) ->
    let ranges := Some (capture_range (Z.of_nat i) (MatchState.endIndex st)) :: MatchState.captures st in
    exists A names,
      regExpBuiltinExec R str = Success (Exotic A (if RegExpFlags.g flags || RegExpFlags.y flags
        then RegExpInstance.setLastIndex R (MatchState.endIndex st) else R)) /\
      captures_to_group_names src (MatchState.captures st) = Success names /\
      ExecArrayExotic.index A = i /\ ExecArrayExotic.input A = str /\
      ExecArrayExotic.array A = map (option_map (substring_at str)) ranges /\
      (if defines_groups src then exists g, ExecArrayExotic.groups A = Some g /\ Named names (tl (ExecArrayExotic.array A)) g
       else ExecArrayExotic.groups A = None) /\
      if RegExpFlags.d flags then exists l, ExecArrayExotic.indices_array A = Some l /\
        map (option_map unpair) l = ranges /\
        if defines_groups src then exists g, ExecArrayExotic.indices_groups A = Some g /\ Named names (tl l) g
        else ExecArrayExotic.indices_groups A = None
      else ExecArrayExotic.indices_array A = None /\ ExecArrayExotic.indices_groups A = None.
  Proof.
    intros R str st i Init Plain flags src start Loop ranges. subst flags src. pose proof Plain as (Len & _ & Get).
    destruct (repeat_matcher_loop_success str Plain R (RegExpFlags.g (RegExpInstance.originalFlags R)) (RegExpFlags.y (RegExpInstance.originalFlags R))
      (length (String.to_char_list str) + 2) start Init ltac:(lia)) as (lr & Loop' & Valid).
    rewrite Loop in Loop'. injection Loop' as <-.
    destruct (Valid st i eq_refl) as [ (_ & End & L_caps & V_caps) Start ]. unfold Match.IteratorOn in End.
    pose proof (initialized_groups _ Init) as Groups.
    destruct (captures_success str Plain _ V_caps) as (Eq_a & Eq_l & _ & _ & Eq_ig).
    assert (V_ranges: List.Forall.Forall ranges (Match.CaptureRange.Valid (String.to_char_list str)))
      by (apply List.Forall.cons; [ constructor; unfold Match.IteratorOn; lia | assumption ]).
    destruct (captures_success str Plain _ V_ranges) as (_ & _ & Eq_ia & Round & _).
    destruct (groups_success str Plain (RegExpInstance.originalSource R) _ 1 V_caps ltac:(lia) ltac:(lia))
      as (names & Eq_names & L_names & g & Eq_g & N_g).
    destruct (Eq_ig names ltac:(lia)) as (ig & Eq_ig' & N_ig).
    unfold regExpBuiltinExec. cbv zeta.
    replace (NonNegInt.from_int _) with (Success (F := MatchError) start)
      by (subst start; destruct Init, (RegExpFlags.g _), (RegExpFlags.y _); cbn [negb andb orb]; now rewrite from_int_nonneg by lia).
    step. rewrite Loop. step.
    unfold MatchRecord.make, getMatchString, captures_to_groups_map, captures_to_group_names, MakeMatchIndicesGroups.
    rewrite from_int_nonneg by lia. step. rewrite Get. unfold NonNegInt.to_int. rewrite Z2Nat.id by lia.
    subst ranges. cbn [map option_map CaptureRange.startIndex CaptureRange.endIndex] in Eq_ia, Round |- *.
    rewrite Nat2Z.id in Eq_ia, Round |- *.
    match goal with
    | [ |- context[ if ?b then RegExpInstance.setLastIndex _ _ else _ ] ] => destruct b
    end; cbn [RegExpInstance.setLastIndex RegExpInstance.regExpRecord RegExpInstance.originalSource];
      rewrite L_caps, Nat.eqb_refl; step; leb_true; step; leb_true; step;
      rewrite Eq_a, Eq_l, Eq_names; step; rewrite length_map, L_caps, Nat.add_1_r, Nat.eqb_refl; step.
    all: destruct (defines_groups _); [ rewrite Eq_g | ]; step;
      destruct (RegExpFlags.d _); step; try rewrite Eq_ia; step;
      rewrite ?L_names, ?length_map, ?Nat.sub_succ, ?Nat.sub_0_r, ?Nat.eqb_refl; step; try rewrite Eq_ig'; step;
      do 2 eexists; (split; [ reflexivity | ]); cbn; repeat split; eauto;
      eexists; (split; [ reflexivity | ]); split; [ exact Round | eauto ].
  Qed.

  (** RegExpBuiltinExec never fails. *)
  Theorem regExpBuiltinExec_success: forall R str,
    Initialized R -> PlainString str ->
    exists res, regExpBuiltinExec R str = Success res.
  Proof.
    intros R str Init Plain. pose proof Plain as (Len & _ & _).
    destruct (repeat_matcher_loop_success str Plain R (RegExpFlags.g (RegExpInstance.originalFlags R))
      (RegExpFlags.y (RegExpInstance.originalFlags R)) (length (String.to_char_list str) + 2)
      (if RegExpFlags.g (RegExpInstance.originalFlags R) || RegExpFlags.y (RegExpInstance.originalFlags R)
       then Z.to_nat (RegExpInstance.lastIndex R) else 0) Init ltac:(lia)) as ([ res | st i ] & Loop & _).
    - exists res. unfold regExpBuiltinExec. cbv zeta.
      destruct Init, (RegExpFlags.g _), (RegExpFlags.y _); cbn [negb andb orb] in *;
        rewrite from_int_nonneg by lia; step; cbn [Z.to_nat]; now rewrite Loop.
    - destruct (regExpBuiltinExec_exotic R str st i Init Plain Loop) as (A & _ & Exec & _). eauto.
  Qed.

  (** RegExpBuiltinExec never fails on a freshly initialized RegExp instance. *)
  Corollary regExpInitialize_exec_success: forall pattern flags R str,
    StaticSemantics.earlyErrors pattern nil = Success false ->
    regExpInitialize pattern flags = Success R ->
    PlainString str ->
    exists res, regExpBuiltinExec R str = Success res.
  Proof. eauto using regExpBuiltinExec_success, regExpInitialize_initialized. Qed.
End BuiltinExec.
