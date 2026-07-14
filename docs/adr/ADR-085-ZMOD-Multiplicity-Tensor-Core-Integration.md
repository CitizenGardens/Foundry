# ADR-085: ZMOD Multiplicity Tensor Integration into Core/

## Status
**Adopted**

## Context
The `Prime/lean/ZMOD/Core.lean` module defines the **ZMOD (Z/(2^n)Z Multiplicity)** core primitives:
- `scale : Nat := 10000` (discrete 1.0 representation)
- `step_interaction : Nat → Nat → Nat` — prime-gradient interaction mapped to Nat domain
- `multiplicityTensor : List Nat → Nat → Nat` — accumulation of interactions over gradient lists

ZMOD is the **lowest-level multiplicity interaction kernel** in the Lean substrate. It maps continuous gradient signals into discrete prime-gated multiplicity tensors using axiom-clean scaled integer arithmetic. Currently, ZMOD exists as a standalone module in `Prime/lean/ZMOD/` without:
- Integration into `Prime/lean/Core/` as a base component
- ADR ratification of its production role
- Formal proof obligations linking it to the Sedona Spine Mandate
- CI enforcement that every ZMOD interaction is audited

Without formal integration into `Core/`, the ZMOD multiplicity tensor risks:
- **Duplication**: Other modules may reimplement `step_interaction` or `multiplicityTensor` inconsistently.
- **Drift**: The `scale = 10000` convention may be violated in downstream modules.
- **Missing audit trail**: ZMOD interactions are not recorded in `Archivum` or verified by the Triple-Lock.

## Decision
We will integrate ZMOD as a **foundational Core component** of the Multiplicity Lean substrate with the following mandates:

### 1. Core Integration
- Move `ZMOD/Core.lean` content into `Prime/lean/Core/ZMOD.lean` as the canonical base module for multiplicity tensor operations.
- All other Lean modules (`AFFINE_CORE`, `MOC_CORE`, `PRMS`, `XI_FORMAL`, etc.) must import `Core.ZMOD` rather than reimplementing `step_interaction` or `multiplicityTensor`.
- The `scale = 10000` convention becomes the **global discrete scale** for the entire `Core/` layer.

### 2. Formal Proof Expansion
- Extend `ZMOD/Core.lean` with proofs:
  - `step_interaction_bounds`: `step_interaction grad p ≤ scale` for all valid inputs.
  - `multiplicityTensor_monotone`: Adding gradients never decreases the tensor value.
  - `multiplicityTensor_zero_iff_no_interaction`: `multiplicityTensor grads p = 0` iff no gradient is divisible by `p`.

### 3. Rust Engine Parity
- Implement `crates/zmod/` or extend `crates/core/` with:
  - `ZmodEngine::step_interaction(grad: u64, p: u64) -> u64`
  - `ZmodEngine::multiplicity_tensor(grads: &[u64], p: u64) -> u64`
- The Rust implementation must:
  - Use exact `u64` arithmetic (no floating-point)
  - Return `ZmodViolation` if `grad` overflows `u64` bounds
  - Emit `ZmodTensorWitness` to `Archivum` on every tensor computation

### 4. Kani Verification
- Implement Kani harnesses in `crates/zmod/tests/kani/` proving:
  - `proof_step_interaction_bounded`: Result is always `≤ scale`.
  - `proof_tensor_monotone`: Adding gradients never decreases the result.
  - `proof_no_false_positives`: `step_interaction` returns 0 unless `grad % p == 0`.

### 5. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/Core/` and `cargo kani -p zmod` on every PR touching ZMOD.
- The Guardian lock must verify the `ZmodTensorWitness` before approving state transitions.
- The Examiner lock must audit tensor computations for overflow.
- The Publisher lock must sign ZMOD configurations into `Archivum`.

## Formal Proof Obligations

### 1. Step Interaction Bounded
```lean
namespace Core.ZMOD

/-- Scale: 10000 = 1.0 -/
def scale : Nat := 10000

/-- Interaction of prime p with gradient at step t. -/
def step_interaction (grad : Nat) (p : Nat) : Nat :=
  if p > 0 ∧ grad % p == 0 then scale else 0

@[proof]
theorem step_interaction_bounded (grad p : Nat) :
  step_interaction grad p ≤ scale := by
  unfold step_interaction
  split
  · exact Nat.le_refl _
  · exact Nat.zero_le _

end Core.ZMOD
```

### 2. Multiplicity Tensor Monotone
```lean
namespace Core.ZMOD

def multiplicityTensor (grads : List Nat) (p : Nat) : Nat :=
  match grads with
  | [] => 0
  | g :: gs => step_interaction g p + multiplicityTensor gs p

@[proof]
theorem multiplicityTensor_monotone (grads₁ grads₂ : List Nat) (p : Nat)
  (h_subset : grads₁ ⊆ grads₂) :
  multiplicityTensor grads₁ p ≤ multiplicityTensor grads₂ p := by
  induction grads₂ generalizing grads₁
  | nil => simp [multiplicityTensor]
  | cons g₂ gs₂ ih =>
    cases grads₁ with
    | nil => simp [multiplicityTensor]
    | cons g₁ gs₁ =>
      simp [multiplicityTensor]
      apply Nat.add_le_add
      · unfold step_interaction
        split <;> omega
      · apply ih
        cases h_subset with | head _ => assumption

end Core.ZMOD
```

### 3. Rust Runtime Contract
```rust
// crates/zmod/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZmodTensorWitness {
    pub grads_hash: [u8; 32],
    pub prime: u64,
    pub tensor_value: u64,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum ZmodViolation {
    #[error("gradient overflow")]
    Overflow,
}

pub struct ZmodEngine;

impl ZmodEngine {
    pub fn step_interaction(&self, grad: u64, p: u64) -> Result<u64, ZmodViolation> {
        if p > 0 && grad % p == 0 {
            Ok(10000)
        } else {
            Ok(0)
        }
    }

    pub fn multiplicity_tensor(&self, grads: &[u64], p: u64) -> Result<u64, ZmodViolation> {
        let mut sum: u64 = 0;
        for &g in grads {
            sum = sum.saturating_add(self.step_interaction(g, p)?);
        }
        Ok(sum)
    }
}
```

## Consequences

### Positive
- **Foundational Consistency**: ZMOD becomes the single source of truth for multiplicity tensor operations across the entire Lean substrate.
- **Axiom-Clean Guarantee**: The `scale = 10000` convention and exact `Nat` arithmetic prevent floating-point drift in core computations.
- **Audit-Ready**: Every ZMOD tensor computation emits a witness to `Archivum`.
- **Dependency Clarity**: All downstream modules (`AFFINE_CORE`, `MOC_CORE`, `PRMS`, `XI_FORMAL`) have a clear import path to the multiplicity tensor.

### Negative
- **Import Restructuring**: Moving ZMOD into `Core/` requires updating imports across all dependent modules.
- **Performance Overhead**: The `multiplicityTensor` recursive implementation may be slow for large gradient lists; an iterative Rust implementation is preferred for production.

## Implementation Steps

1. **Refactor `ZMOD/Core.lean`** into `Core/ZMOD.lean`, preserving namespace as `Core.ZMOD`.
2. **Prove expansion theorems** in `Core/ZMOD.lean` (boundedness, monotonicity, zero-iff).
3. **Update all imports** in `AFFINE_CORE/`, `MOC_CORE/`, `PRMS/`, `XI_FORMAL/` to use `Core.ZMOD`.
4. **Create `crates/zmod/`** Rust crate with `step_interaction` and `multiplicity_tensor`.
5. **Implement Kani harness** proving boundedness and monotonicity.
6. **Update CI** to enforce `lake build` on `Core/` + `cargo kani -p zmod`.
7. **Emit Archivum witness** `ZmodTensorProof` on every tensor computation.

## References
- `Prime/lean/ZMOD/Core.lean` — Source module
- `Prime/lean/Core/Spine.lean` — Existing Core module
- `Prime/lean/Core/Drift.lean` — Existing drift metrics
- ADR-002 (Sedona Spine) — Path of Integrity
- ADR-061 (ZMOS) — Zeta-Multiplicity Operator System
- `Prime/crates/core/` — Existing Rust core crate
