-- Bifrost.Policy — formal policy as Lean 4 propositions + Boolean decision procedure.
--
-- Structure:
--   1. `valid*`  defs  — declarative Props (what the policy *means*)
--   2. `decide`  def   — computable Bool (what the runtime *checks*)
--   3. `decide_sound` theorem — `decide e s = true → valid_event e s`
--      Proven by case analysis on `e`, unfolding `decide` and each `valid*`
--      def, then applying `Bool.and_eq_true` / `Bool.or_eq_true`.

import UAC.Bifrost.State

namespace Bifrost

-- ── Validity propositions ────────────────────────────────────────────────────

/- A `JitCompile` event is valid when:
    1. The SoulIR source (`souliirCid`) is immutably sealed in WORM_FS.
    2. The WASM output (`wasmCid`) is a fresh artifact (not yet in WORM). -/
def validJitCompile (e : Event) (s : State) : Prop :=
  match e with
  | Event.jitCompile souliir wasm _ _ =>
      s.wormSealed souliir = true ∧ s.wormSealed wasm = false
  | _ => False

/- A `CapTransfer` event is valid when:
    1. The policy CID is sealed in WORM_FS (or is the zero genesis sentinel).
    2. The capability exists in the cap map (runtime-originated mints with zero
       cap_hash bypass this — they are rights-gated at the silverback level). -/
def validCapTransfer (e : Event) (s : State) : Prop :=
  match e with
  | Event.capTransfer _ _ capHash policyCid =>
      (Cid.isZero policyCid ∨ s.wormSealed policyCid = true) ∧
      (Cid.isZero capHash   ∨ s.capExists capHash = true)
  | _ => False

/- An `attestation` event is valid when:
    1. The epoch root matches the state's recorded epoch root.
    2. The signature is over the genesis key (checked externally via `bifrost-attest`). -/
def validAttestation (e : Event) (s : State) : Prop :=
  match e with
  | Event.attestation epoch rootCid _ =>
      s.epochRoot epoch = some rootCid
  | _ => False

/- An event is valid if it satisfies at least one of the valid-event rules. -/
def validEvent (e : Event) (s : State) : Prop :=
  validJitCompile e s ∨ validCapTransfer e s ∨ validAttestation e s

-- ── Decidable decision procedure ──────────────────────────────────────────────

/- Boolean decision procedure — directly executable in Rust after extraction.
    This is the *single source of truth* for the runtime policy enforcer in
    `bifrost-policy/src/lib.rs::policy_decide`. -/
def decide (e : Event) (s : State) : Bool :=
  match e with
  | Event.jitCompile souliir wasm _ _ =>
      s.wormSealed souliir && !s.wormSealed wasm
  | Event.capTransfer _ _ capHash policyCid =>
      (Cid.isZero policyCid || s.wormSealed policyCid) &&
      (Cid.isZero capHash   || s.capExists capHash)
  | Event.attestation epoch rootCid _ =>
      (s.epochRoot epoch) == some rootCid

-- ── Soundness theorem ────────────────────────────────────────────────────────

/- **Soundness**: if `decide` returns `true`, then `validEvent` holds.
    Proof by case analysis on `e`, unfolding `decide` and each `valid*` def,
    and applying `Bool.and_eq_true` / `Bool.or_eq_true` to discharge each
    branch. -/
theorem decide_sound (e : Event) (s : State)
    (h : decide e s = true) : validEvent e s := by
  unfold decide validEvent validJitCompile validCapTransfer validAttestation at *
  cases e
  -- jitCompile
  · rw [Bool.and_eq_true] at h
    cases h with
    | intro hSealed hFresh => exact Or.inl ⟨hSealed, Bool.not_eq_true hFresh⟩
  -- capTransfer
  · rw [Bool.and_eq_true] at h
    cases h with
    | intro hLeft hRight =>
      rw [Bool.or_eq_true] at hLeft hRight
      exact Or.inr (Or.inl ⟨hLeft, hRight⟩)
  -- attestation
  · exact Or.inr (Or.inr h)

/- **Completeness** (aspirational, week 4+):
    if `validEvent` holds, then `decide` returns `true`. -/
-- theorem decide_complete (e : Event) (s : State)
--     (h : validEvent e s) : decide e s = true := by
--   ()

end Bifrost
