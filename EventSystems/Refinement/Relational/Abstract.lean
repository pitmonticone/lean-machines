
/-
  Reuse of abstract events
-/

import EventSystems.Refinement.Relational.Basic
import EventSystems.Refinement.Relational.Convergent

open Refinement

/-
 Q : is there a better way to ease the definition of abstract events ? -/

structure _AbstractREventSpec (AM) [Machine ACTX AM]
                              (M) [Machine CTX M]
                              [Refinement AM M] (α) where

  lift (m: M) : AM

  lift_ref (m : M):
    Machine.invariant m → refine (lift m) m

  refine_uniq (am am' : AM) (m : M):
    Machine.invariant m
    → refine am m → refine am' m
    → am = am'

  unlift (am am' : AM) (m : M) (x : α): M

structure AbstractREventSpec (AM) [Machine ACTX AM]
                             (M) [Machine CTX M]
                            [Refinement AM M] (α) (β)
          extends _AbstractREventSpec AM M α where

  event : OrdinaryEvent AM α β

  step_ref (m : M) (x : α):
    Machine.invariant m
    → event.guard (lift m) x
    → let (_, am') := event.action (lift m) x
      refine am' (unlift (lift m) am' m x)

  step_safe (m : M) (x : α):
    Machine.invariant m
    → event.guard (lift m) x
    → let (_, am') := event.action (lift m) x
      Machine.invariant am' -- redundant but useful
      → Machine.invariant (unlift (lift m) am' m x)

@[simp]
def newAbstractREvent [Machine ACTX AM] [Machine CTX M] [instR:Refinement AM M]
  (abs : AbstractREventSpec AM M α β) : OrdinaryREvent AM M α β :=
  { guard := fun (m : M) (x : α) => abs.event.guard (abs.lift m) x
    action := fun (m : M) (x : α) => let am := abs.lift m
                                     let (y, am') := abs.event.action am x
                                     (y, abs.unlift am am' m x)
    po := {
      safety := fun (m : M) (x : α) => by
        simp
        intros Hinv Hgrd
        have Href := abs.lift_ref m Hinv
        have Hainv := Refinement.refine_safe (abs.lift m) m Hinv Href
        have Hsafe := abs.event.po.safety (abs.lift m) x Hainv Hgrd
        apply abs.step_safe m x Hinv Hgrd Hsafe

      abstract := abs.event.to_Event

      strengthening := fun m x => by simp
                                     intros Hinv Hgrd am Href
                                     have Href' := abs.lift_ref m Hinv
                                     have Ham: am = abs.lift m := by
                                       apply abs.refine_uniq am (abs.lift m) m <;> assumption
                                     rw [Ham]
                                     assumption

      simulation := fun m x => by simp
                                  intros Hinv Hgrd am Href
                                  have Href' := abs.lift_ref m Hinv
                                  have Ham: am = abs.lift m := by
                                    apply abs.refine_uniq am (abs.lift m) m <;> assumption
                                  rw [Ham]
                                  constructor
                                  · simp
                                  apply abs.step_ref m x Hinv Hgrd
    }
  }

structure AbstractREventSpec' (AM) [Machine ACTX AM]
                              (M) [Machine CTX M]
                             [Refinement AM M] (α)
          extends _AbstractREventSpec AM M α where

  event : OrdinaryEvent AM α Unit

  step_ref (m : M) (x : α):
    Machine.invariant m
    → event.guard (lift m) x
    → let (_, am') := event.action (lift m) x
      refine am' (unlift (lift m) am' m x)

  step_safe (m : M) (x : α):
    Machine.invariant m
    → event.guard (lift m) x
    → let (_, am') := event.action (lift m) x
      Machine.invariant am' -- redundant but useful
      → Machine.invariant (unlift (lift m) am' m x)

@[simp]
def AbstractREventSpec'.toAbstractREventSpec [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  (ev : AbstractREventSpec' AM M α) : AbstractREventSpec AM M α Unit :=
  {
    to_AbstractREventSpec := ev.to_AbstractREventSpec
    event := ev.event
    step_ref := ev.step_ref
    step_safe := ev.step_safe
  }

@[simp]
def newAbstractREvent' [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  (abs : AbstractREventSpec' AM M α) : OrdinaryREvent AM M α Unit :=
  newAbstractREvent abs.toAbstractREventSpec

structure AbstractREventSpec'' (AM) [Machine ACTX AM]
                               (M) [Machine CTX M]
                               [Refinement AM M]
          extends _AbstractREventSpec AM M Unit where

  event : OrdinaryEvent AM Unit Unit

  step_ref (m : M):
    Machine.invariant m
    → event.guard (lift m) ()
    → let ((), am') := event.action (lift m) ()
      refine am' (unlift (lift m) am' m ())

  step_safe (m : M):
    Machine.invariant m
    → event.guard (lift m) ()
    → let ((), am') := event.action (lift m) ()
      Machine.invariant am' -- redundant but useful
      → Machine.invariant (unlift (lift m) am' m ())

@[simp]
def AbstractREventSpec''.toAbstractREventSpec [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  (ev : AbstractREventSpec'' AM M) : AbstractREventSpec AM M Unit Unit :=
  {
    to_AbstractREventSpec := ev.to_AbstractREventSpec
    event := ev.event
    step_ref := fun m _ => ev.step_ref m
    step_safe := fun m _ => ev.step_safe m
  }

@[simp]
def newAbstractREvent'' [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  (abs : AbstractREventSpec'' AM M) : OrdinaryREvent AM M Unit Unit :=
  newAbstractREvent abs.toAbstractREventSpec

structure AbstractAnticipatedREventSpec
              (v) [Preorder v]
              (AM) [Machine ACTX AM]
              (M) [Machine CTX M]
              [Refinement AM M] (α) (β)
          extends _AbstractREventSpec AM M α where

  event : AnticipatedEvent v AM α β

  step_ref (m : M) (x : α):
    Machine.invariant m
    → event.guard (lift m) x
    → let (_, am') := event.action (lift m) x
      refine am' (unlift (lift m) am' m x)

  step_safe (m : M) (x : α):
    Machine.invariant m
    → event.guard (lift m) x
    → let (_, am') := event.action (lift m) x
      Machine.invariant am' -- redundant but useful
      → Machine.invariant (unlift (lift m) am' m x)

  step_variant (m : M) (x : α):
    Machine.invariant m
    → event.guard (lift m) x
    → let (_, am') := event.action (lift m) x
      Machine.invariant am' -- redundant but useful
      → event.po.variant (lift (unlift (lift m) am' m x))
      = event.po.variant am'

@[simp]
def newAbstractAnticipatedREvent [Preorder v]
                                 [Machine ACTX AM]
                                 [Machine CTX M]
                                 [instR:Refinement AM M]
  (abs : AbstractAnticipatedREventSpec v AM M α β) : AnticipatedREvent v AM M α β :=
  { guard := fun (m : M) (x : α) => abs.event.guard (abs.lift m) x
    action := fun (m : M) (x : α) => let am := abs.lift m
                                     let (y, am') := abs.event.action am x
                                     (y, abs.unlift am am' m x)
    po := {
      safety := fun (m : M) (x : α) => by
        simp
        intros Hinv Hgrd
        have Href := abs.lift_ref m Hinv
        have Hainv := Refinement.refine_safe (abs.lift m) m Hinv Href
        have Hsafe := abs.event.po.safety (abs.lift m) x Hainv Hgrd
        apply abs.step_safe m x Hinv Hgrd Hsafe

      abstract := abs.event.to_Event

      strengthening := fun m x => by simp
                                     intros Hinv Hgrd am Href
                                     have Href' := abs.lift_ref m Hinv
                                     have Ham: am = abs.lift m := by
                                       apply abs.refine_uniq am (abs.lift m) m <;> assumption
                                     rw [Ham]
                                     assumption

      simulation := fun m x => by simp
                                  intros Hinv Hgrd am Href
                                  have Href' := abs.lift_ref m Hinv
                                  have Ham: am = abs.lift m := by
                                    apply abs.refine_uniq am (abs.lift m) m <;> assumption
                                  rw [Ham]
                                  constructor
                                  · simp
                                  apply abs.step_ref m x Hinv Hgrd

      variant := fun m => abs.event.po.variant (abs.lift m)

      nonIncreasing := fun m x => by simp
                                     intros Hinv Hgrd
                                     have Hinv' := Refinement.refine_safe (abs.lift m) m Hinv (abs.lift_ref m Hinv)
                                     have Hainv := abs.event.po.safety (abs.lift m) x Hinv' Hgrd
                                     have Hni := abs.event.po.nonIncreasing (abs.lift m) x Hinv' Hgrd
                                     simp at Hni
                                     rw [abs.step_variant]
                                     <;> assumption
    }
  }

structure AbstractAnticipatedREventSpec'
              (v) [Preorder v]
              (AM) [Machine ACTX AM]
              (M) [Machine CTX M]
              [Refinement AM M] (α)
          extends AbstractAnticipatedREventSpec v AM M α Unit where


@[simp]
def newAbstractAnticipatedREvent' [Preorder v]
                                  [Machine ACTX AM]
                                  [Machine CTX M]
                                  [Refinement AM M]
  (abs : AbstractAnticipatedREventSpec' v AM M α) : AnticipatedREvent v AM M α Unit :=
  newAbstractAnticipatedREvent abs.toAbstractAnticipatedREventSpec

structure AbstractAnticipatedREventSpec''
              (v) [Preorder v]
              (AM) [Machine ACTX AM]
              (M) [Machine CTX M]
              [Refinement AM M]
          extends AbstractAnticipatedREventSpec v AM M Unit Unit where


@[simp]
def newAbstractAnticipatedREvent'' [Preorder v]
                                   [Machine ACTX AM]
                                   [Machine CTX M]
                                   [Refinement AM M]
  (abs : AbstractAnticipatedREventSpec'' v AM M) : AnticipatedREvent v AM M Unit Unit :=
  newAbstractAnticipatedREvent abs.toAbstractAnticipatedREventSpec


structure AbstractConvergentREventSpec
              (v) [Preorder v] [WellFoundedLT v]
              (AM) [Machine ACTX AM]
              (M) [Machine CTX M]
              [Refinement AM M] (α) (β)
          extends _AbstractREventSpec AM M α where

  event : ConvergentEvent v AM α β

  step_ref (m : M) (x : α):
    Machine.invariant m
    → event.guard (lift m) x
    → let (_, am') := event.action (lift m) x
      refine am' (unlift (lift m) am' m x)

  step_safe (m : M) (x : α):
    Machine.invariant m
    → event.guard (lift m) x
    → let (_, am') := event.action (lift m) x
      Machine.invariant am' -- redundant but useful
      → Machine.invariant (unlift (lift m) am' m x)

  step_variant (m : M) (x : α):
    Machine.invariant m
    → event.guard (lift m) x
    → let (_, am') := event.action (lift m) x
      Machine.invariant am' -- redundant but useful
      → event.po.variant (lift (unlift (lift m) am' m x))
      = event.po.variant am'

@[simp]
def newAbstractConvergentREvent  [Preorder v] [WellFoundedLT v]
                                 [Machine ACTX AM]
                                 [Machine CTX M]
                                 [instR:Refinement AM M]
  (abs : AbstractConvergentREventSpec v AM M α β) : ConvergentREvent v AM M α β :=
  { guard := fun (m : M) (x : α) => abs.event.guard (abs.lift m) x
    action := fun (m : M) (x : α) => let am := abs.lift m
                                     let (y, am') := abs.event.action am x
                                     (y, abs.unlift am am' m x)
    po := {
      safety := fun (m : M) (x : α) => by
        simp
        intros Hinv Hgrd
        have Href := abs.lift_ref m Hinv
        have Hainv := Refinement.refine_safe (abs.lift m) m Hinv Href
        have Hsafe := abs.event.po.safety (abs.lift m) x Hainv Hgrd
        apply abs.step_safe m x Hinv Hgrd Hsafe

      abstract := abs.event.to_Event

      strengthening := fun m x => by simp
                                     intros Hinv Hgrd am Href
                                     have Href' := abs.lift_ref m Hinv
                                     have Ham: am = abs.lift m := by
                                       apply abs.refine_uniq am (abs.lift m) m <;> assumption
                                     rw [Ham]
                                     assumption

      simulation := fun m x => by simp
                                  intros Hinv Hgrd am Href
                                  have Href' := abs.lift_ref m Hinv
                                  have Ham: am = abs.lift m := by
                                    apply abs.refine_uniq am (abs.lift m) m <;> assumption
                                  rw [Ham]
                                  constructor
                                  · simp
                                  apply abs.step_ref m x Hinv Hgrd

      variant := fun m => abs.event.po.variant (abs.lift m)

      nonIncreasing := fun m x => by simp
                                     intros Hinv Hgrd
                                     have Hinv' := Refinement.refine_safe (abs.lift m) m Hinv (abs.lift_ref m Hinv)
                                     have Hainv := abs.event.po.safety (abs.lift m) x Hinv' Hgrd
                                     have Hni := abs.event.po.nonIncreasing (abs.lift m) x Hinv' Hgrd
                                     simp at Hni
                                     rw [abs.step_variant]
                                     <;> assumption

      convergence := fun m x => by simp
                                   intros Hinv Hgrd
                                   have Hinv' := Refinement.refine_safe (abs.lift m) m Hinv (abs.lift_ref m Hinv)
                                   have Hainv := abs.event.po.safety (abs.lift m) x Hinv' Hgrd
                                   have Hcv := abs.event.po.convergence (abs.lift m) x Hinv' Hgrd
                                   simp at Hcv
                                   rw [abs.step_variant]
                                   <;> assumption

    }
  }

structure AbstractConvergentREventSpec'
              (v) [Preorder v] [WellFoundedLT v]
              (AM) [Machine ACTX AM]
              (M) [Machine CTX M]
              [Refinement AM M] (α)
          extends AbstractConvergentREventSpec v AM M α Unit where

@[simp]
def newAbstractConvergentREvent'  [Preorder v] [WellFoundedLT v]
                                  [Machine ACTX AM]
                                  [Machine CTX M]
                                  [Refinement AM M]
  (abs : AbstractConvergentREventSpec' v AM M α) : ConvergentREvent v AM M α Unit :=
  newAbstractConvergentREvent abs.toAbstractConvergentREventSpec

structure AbstractConvergentREventSpec''
              (v) [Preorder v] [WellFoundedLT v]
              (AM) [Machine ACTX AM]
              (M) [Machine CTX M]
              [Refinement AM M]
          extends AbstractConvergentREventSpec v AM M Unit Unit where

@[simp]
def newAbstractConvergentREvent''  [Preorder v] [WellFoundedLT v]
                                   [Machine ACTX AM]
                                   [Machine CTX M]
                                   [Refinement AM M]
  (abs : AbstractConvergentREventSpec'' v AM M) : ConvergentREvent v AM M Unit Unit :=
  newAbstractConvergentREvent abs.toAbstractConvergentREventSpec
