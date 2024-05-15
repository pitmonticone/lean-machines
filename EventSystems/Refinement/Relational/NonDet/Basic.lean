
import EventSystems.NonDet.Basic
import EventSystems.NonDet.Ordinary
import EventSystems.Refinement.Relational.Basic

open Refinement

structure _RNDEventPO  [Machine ACTX AM] [Machine CTX M] [instR: Refinement AM M]
   (ev : _NDEvent M α β) (kind : EventKind) (α' β')
   extends _NDEventPO ev kind where

  abstract : _NDEvent AM α' β'

  lift_in : α → α'
  lift_out : β → β'

  strengthening (m : M) (x : α):
    Machine.invariant m
    → ev.guard m x
    → ∀ am, refine am m
      → abstract.guard am (lift_in x)

  simulation (m : M) (x : α):
    Machine.invariant m
    → ev.guard m x
    → ∀ y, ∀ m', ev.effect m x (y, m')
      → ∀ am, refine am m
        → ∃ am', abstract.effect am (lift_in x) (lift_out y, am')
                 ∧ refine am' m'

structure OrdinaryRNDEvent (AM) [Machine ACTX AM] (M) [Machine CTX M] [instR: Refinement AM M]
  (α β) (α':=α) (β':=β) extends _NDEvent M α β where
  po : _RNDEventPO (instR:=instR) to_NDEvent (EventKind.TransNonDet Convergence.Ordinary) α' β'

@[simp]
def OrdinaryRNDEvent.toOrdinaryNDEvent [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  (ev : OrdinaryRNDEvent AM M α β α' β') : OrdinaryNDEvent M α β :=
  {
    to_NDEvent := ev.to_NDEvent
    po := ev.po.to_NDEventPO
  }

structure RNDEventSpec (AM) [Machine ACTX AM]
                        (M) [Machine CTX M]
                        [Refinement AM M]
  {α β α' β'} (abstract : _NDEvent AM α' β')
  extends NDEventSpec M α β where

  lift_in : α → α'
  lift_out : β → β'

  strengthening (m : M) (x : α):
    Machine.invariant m
    → guard m x
    → ∀ am, refine am m
      → abstract.guard am (lift_in x)

  simulation (m : M) (x : α):
    Machine.invariant m
    → guard m x
    → ∀ y, ∀ m', effect m x (y, m')
      -- XXX : some constraint on output ?
      → ∀ am, refine am m
        → ∃ am', abstract.effect am (lift_in x) (lift_out y, am')
                 ∧ refine am' m'

@[simp]
def newRNDEvent [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  (abs : OrdinaryNDEvent AM α' β') (ev : RNDEventSpec AM M (α:=α) (β:=β) (α':=α') (β':=β') abs.to_NDEvent) : OrdinaryRNDEvent AM M α β α' β' :=
  {
    to_NDEvent := ev.to_NDEvent
    po := {
      safety := ev.safety
      feasibility := ev.feasibility
      abstract := abs.to_NDEvent
      strengthening := ev.strengthening
      simulation := ev.simulation
    }
  }

structure RNDEventSpec' (AM) [Machine ACTX AM]
                        (M) [Machine CTX M]
                        [Refinement AM M]
  {α α'} (abstract : _NDEvent AM α' Unit)
  extends NDEventSpec' M α where

  lift_in : α → α'

  strengthening (m : M) (x : α):
    Machine.invariant m
    → guard m x
    → ∀ am, refine am m
      → abstract.guard am (lift_in x)

  simulation (m : M) (x : α):
    Machine.invariant m
    → guard m x
    → ∀ m', effect m x m'
      -- XXX : some constraint on output ?
      → ∀ am, refine am m
        → ∃ am', abstract.effect am (lift_in x) ((), am')
                 ∧ refine am' m'

@[simp]
def RNDEventSpec'.toRNDEventSpec [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  {α α'} (abs : _NDEvent AM α' Unit) (ev : RNDEventSpec' AM M (α:=α) (α':=α') abs) : RNDEventSpec AM M (α:=α) (β:=Unit) (α':=α') (β':=Unit) abs :=
  {
    toNDEventSpec := ev.toNDEventSpec
    lift_in := ev.lift_in
    lift_out := id
    strengthening := ev.strengthening
    simulation := fun m x => by
      simp
      intros Hinv Hgrd _ m' Heff am Href
      apply ev.simulation m x Hinv Hgrd
      <;> assumption
  }

@[simp]
def newRNDEvent' [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  (abs : OrdinaryNDEvent AM α' Unit) (ev : RNDEventSpec' AM M (α:=α) (α':=α') abs.to_NDEvent) : OrdinaryRNDEvent AM M α Unit α' Unit :=
  newRNDEvent abs ev.toRNDEventSpec

structure RNDEventSpec'' (AM) [Machine ACTX AM]
                        (M) [Machine CTX M]
                        [Refinement AM M]
  (abstract : _NDEvent AM Unit Unit)
  extends NDEventSpec'' M where

  strengthening (m : M):
    Machine.invariant m
    → guard m
    → ∀ am, refine am m
      → abstract.guard am ()

  simulation (m : M):
    Machine.invariant m
    → guard m
    → ∀ m', effect m m'
      → ∀ am, refine am m
        → ∃ am', abstract.effect am () ((), am')
                 ∧ refine am' m'

@[simp]
def RNDEventSpec''.toRNDEventSpec [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  (abs : _NDEvent AM Unit Unit) (ev : RNDEventSpec'' AM M abs) : RNDEventSpec AM M (α:=Unit) (β:=Unit) (α':=Unit) (β':=Unit) abs :=
  {
    toNDEventSpec := ev.toNDEventSpec
    lift_in := id
    lift_out := id
    strengthening := fun m () => ev.strengthening m
    simulation := fun m () => by
      simp
      intros Hinv Hgrd _ m' Heff am Href
      apply ev.simulation m Hinv Hgrd
      <;> assumption
  }

@[simp]
def newRNDEvent'' [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  (abs : OrdinaryNDEvent AM Unit Unit) (ev : RNDEventSpec'' AM M abs.to_NDEvent) : OrdinaryRNDEvent AM M Unit Unit :=
  newRNDEvent abs ev.toRNDEventSpec

/- Initialization events -/

structure _InitRNDEventPO  [Machine ACTX AM] [Machine CTX M] [instR: Refinement AM M]
   (ev : _NDEvent M α β) (kind : EventKind) (α' β')
   extends _InitNDEventPO ev kind where

  abstract : _NDEvent AM α' β'

  lift_in : α → α'
  lift_out : β → β'

  strengthening (x : α):
    ev.guard Machine.reset x
    → ∀ am, refine (self:=instR) am Machine.reset
      → abstract.guard am (lift_in x)

  simulation (x : α):
    ev.guard Machine.reset x
    → ∀ y, ∀ m', ev.effect Machine.reset x (y, m')
      -- XXX : some constraint on output ?
      → ∀ am, refine (self:=instR) am Machine.reset
        → ∃ am', abstract.effect am (lift_in x) (lift_out y, am')
                 ∧ refine am' m'

structure InitRNDEvent (AM) [Machine ACTX AM] (M) [Machine CTX M] [instR: Refinement AM M]
  (α) (β) (α':=α) (β':=β)
  extends _NDEvent M α β where
  po : _InitRNDEventPO (instR:=instR) to_NDEvent (EventKind.InitNonDet) α' β'

@[simp]
def InitRNDEvent.toInitNDEvent [Machine ACTX AM] [Machine CTX M] [Refinement AM M] (ev : InitRNDEvent AM M α β α' β') : InitNDEvent M α β :=
{
  to_NDEvent:= ev.to_NDEvent
  po := ev.po.to_InitNDEventPO
}

@[simp]
def InitRNDEvent.init  [Machine ACTX AM] [Machine CTX M] [Refinement AM M] (ev : InitRNDEvent AM M α β) (x : α) (nxt : β × M) :=
  ev.effect Machine.reset x nxt

@[simp]
def InitRNDEvent.init'  [Machine ACTX AM] [Machine CTX M] [Refinement AM M] (ev : InitRNDEvent AM M Unit β) (nxt: β × M) :=
  ev.init () nxt

@[simp]
def InitRNDEvent.init''  [Machine ACTX AM] [Machine CTX M] [Refinement AM M] (ev : InitRNDEvent AM M Unit Unit) (m : M) :=
  ev.init' ((), m)

structure InitRNDEventSpec (AM) [Machine ACTX AM] (M) [Machine CTX M] [Refinement AM M]
  {α β α' β'} (abstract : InitNDEvent AM α' β')
  extends InitNDEventSpec M α β where

  lift_in : α → α'
  lift_out : β → β'

  strengthening (x : α):
    guard x
    → abstract.guard Machine.reset (lift_in x)

  simulation (x : α):
    guard x
    → ∀ y, ∀ m', init x (y, m')
      -- XXX : some constraint on output ?
      → ∃ am', abstract.effect Machine.reset (lift_in x) (lift_out y, am')
               ∧ refine am' m'

@[simp]
def newInitRNDEvent [Machine ACTX AM] [Machine CTX M] [Refinement AM M]
  {α β α' β'} (abs : InitNDEvent AM α' β')
  (ev : InitRNDEventSpec AM M (α:=α) (β:=β) (α':=α') (β':=β') abs) : InitRNDEvent AM M α β α' β' :=
  {
    to_NDEvent := (newInitNDEvent ev.toInitNDEventSpec).to_NDEvent
    po := {
      lift_in := ev.lift_in
      lift_out := ev.lift_out
      safety := fun x => by simp
                            intros Hgrd y m' Hini
                            apply ev.safety (y:=y) x Hgrd
                            assumption
      feasibility := fun x => by simp
                                 intro Hgrd
                                 apply ev.feasibility x Hgrd
      abstract := abs.to_NDEvent
      strengthening := fun x => by simp
                                   intros Hgrd am Href
                                   have Hstr := ev.strengthening x Hgrd
                                   have Hax := refine_reset am Href
                                   rw [Hax]
                                   assumption
      simulation := fun x => by simp
                                intro Hgrd y m' Hini am Href
                                have Hsim := ev.simulation x Hgrd y m' Hini
                                have Hax := refine_reset am Href
                                rw [Hax]
                                assumption
    }
  }
