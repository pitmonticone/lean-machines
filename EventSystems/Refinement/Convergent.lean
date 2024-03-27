
import EventSystems.Refinement.Basic
import EventSystems.Convergent

open Refinement

structure _RAnticipatedEventPO (v) [Preorder v]  [Machine ACTX AM] [Machine CTX M] [instR: Refinement AM M] (ev : _Event M α β) (kind : EventKind)
          extends _Variant v, _REventPO (instR:=instR) ev kind  where

  nonIncreasing (m : M) (x : α):
    Machine.invariant m
    → ev.guard m x
    → let (_, m') := ev.action m x
      variant m' ≤ variant m

structure AnticipatedREvent (v) [Preorder v] (AM) [Machine ACTX AM] (M) [Machine CTX M] [instR: Refinement AM M] (α) (β) extends _Event M α β where
  po : _RAnticipatedEventPO v (instR:=instR) to_Event (EventKind.TransDet Convergence.Anticipated)

structure AnticipatedREventSpecFromOrdinary (v) [Preorder v] (AM) [Machine ACTX AM] (M) [Machine CTX M] [Refinement AM M] (α) (β)
  extends _Variant v, REventSpec AM M α β where

  nonIncreasing (m : M) (x : α):
    Machine.invariant m
    → guard m x
    → let m' := (action m x).2
      variant m' ≤ variant m

@[simp]
def AnticipatedREvent_fromOrdinary [Preorder v]  [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  (ev : OrdinaryREvent AM M α β)
  (variant : M → v)
  (Hnincr: ∀ (m : M) (x : α),
    Machine.invariant m
    → ev.guard m x
    → let (_, m') := ev.action m x
      variant m' ≤ variant m) : AnticipatedREvent v AM M α β :=
  {
    guard := ev.guard
    action := ev.action
    po := {
      safety := ev.po.safety
      abstract := ev.po.abstract
      strengthening := ev.po.strengthening
      simulation := ev.po.simulation
      variant := variant
      nonIncreasing := Hnincr
    }
  }

@[simp]
def newAnticipatedREventfromOrdinary [Preorder v] [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
    (ev : AnticipatedREventSpecFromOrdinary v AM M α β) : AnticipatedREvent v AM M α β :=
  AnticipatedREvent_fromOrdinary (newREvent ev.toREventSpec) ev.to_Variant.variant ev.nonIncreasing

structure AnticipatedREventSpecFromAnticipated (v) [Preorder v] (AM) [Machine ACTX AM] (M) [Machine CTX M] [Refinement AM M] (α) (β)
  extends _Variant v (M:=M), EventSpec M α β where

  abstract : AnticipatedEvent v AM α β

  strengthening (m : M) (x : α):
    Machine.invariant m
    → guard m x
    → ∀ am, refine am m
      → abstract.guard am x

  simulation (m : M) (x : α):
    Machine.invariant m
    → guard m x
    → ∀ am, refine am m
      → let (y, m') := action m x
        let (z, am') := abstract.action am x
        y = z ∧ refine am' m'

  nonIncreasing (m : M) (x : α):
    Machine.invariant m
    → guard m x
    → let m' := (action m x).2
      variant m' ≤ variant m

@[simp]
def newAnticipatedREventfromAnticipated [Preorder v] [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
    (ev : AnticipatedREventSpecFromAnticipated v AM M α β) : AnticipatedREvent v AM M α β :=
 {
  guard := ev.guard
  action := ev.action
  po := {
    safety := ev.safety
    variant := ev.variant
    abstract := ev.abstract.to_Event
    strengthening := ev.strengthening
    simulation := ev.simulation
    nonIncreasing := ev.nonIncreasing
  }
 }
