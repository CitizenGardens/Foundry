# ADR-PML-038: Formalize the Canonical MKT Quaternion Axis and non-abelian `SU(2)` prime generators in `lean/dynamics/Quarternion.lean` (gap)

## Status
Proposed

## Axis (Phase Mirror tension class)
intent (documents / corpus narrative) vs implementation (lean/)

## Owner (multi-agent lever)
`the-examiner`

## Dissonance Score
- Impact = severity (4) x blast radius (1) = **4**
- Tractability = **1.0**
- **Score = 4.0**  (cluster rank 1 of 1)

## Context (stated intent vs implementation)
The Multiplicity corpus grounds **Multiplicity Knot Theory (MKT)** and the
**Spin Foam Microfoundations** in a non-abelian quaternion algebra of `SU(2)`
generators. The narrative defines a *Canonical MKT Axis* per prime, an
Abelian-collapsed baseline, and a Canonical Non-Parallelism theorem — none of
which are currently manifested in the verified Lean 4 layer.

### Stated intent (documents / corpus)
  - `docs/multiplicity/Multiplicity_Knot_Theory.tex` — knots are encoded by
    non-abelian braid words over `SU(2)` prime generators `O_p`.
  - Corpus narrative §1 — early scalar/single-axis assignment
    `O^{orig}_p = exp(i log p · σ_x)` yields the **Abelian Collapse Theorem**
    (`[O_p, O_q] = 0`).
  - Corpus narrative §2 — **Canonical MKT Axis**: for each prime `p`,
    `v(p) = (sin(log p), cos(log p), p^{-1/2})`, normalized to
    `n̂_p = v(p) / ‖v(p)‖ ∈ S²`.
  - Corpus narrative §3 — **Theorem 3.3 (Canonical Non-Parallelism)**:
    `n̂_p ≠ n̂_q` for all distinct primes `p ≠ q`; hence
    `O_p = exp(i log p · n̂_p · σ⃗)` has strictly non-zero commutator
    `[O_p, O_q] ≠ 0`, enabling braid words `W_K`.
  - Corpus narrative §4 — the same generators glue `SU(2)`/`Spin(4)` spin
    network chunks in Spin Foam Microfoundations.

### Implementation reality (lean/)
  - `lean/dynamics/Quarternion.lean` does **not exist** (no file at the path).
  - No Lean definition of `v(p)`, `norm_axis`, `canonicalAxis p`, the abelian
    baseline `O_orig p`, the non-abelian generator `O_p`, or
    `canonical_non_parallelism`.
  - The non-abelian claim (`[O_p, O_q] ≠ 0`) and Non-Parallelism theorem are
    unverified in the Lean corpus; MKT braid-word encoding has no formal base.

### Manifested boundary
Leaked (unmanifested): YES — gap is NOT manifested in `alp_sorry_manifest.json`
(silent leak risk for the MKT / Spin-Foam foundational engine).

## Decision (the lever)
Resolve the dissonance by creating `lean/dynamics/Quarternion.lean` that
formally establishes the Canonical MKT Axis and the non-abelian `SU(2)`
generator algebra, with the Abelian-collapse baseline and the
Canonical Non-Parallelism theorem proven in the verified layer. Treat the
*quantitative* non-commutativity metric (`[O_p, O_q] ≠ 0`) as `Proposed` /
manifested-`sorry` until the transcendental non-parallelism proof is fully
closed; the structural scaffolding (axis, norm, generator, commutator form)
must be free of unmanifested `sorry`. Per corpus policy the hard transcendental
theorems are backed by **Rust/Kani** witnesses (no Mathlib dependency).

## Consequences
- **Positive**: MKT braid words and Spin Foam gluing acquire a verified
  quaternion foundation; the Abelian-collapse failure mode is formally
  contrasted, preventing a silent regression to abelian phase theory.
- **Negative / Constraints**: Non-Parallelism rests on a transcendental
  identity (`sin(log p)`, `cos(log p)`, `p^{-1/2}` never co-align across
  distinct primes). A fully constructive Lean proof may require external numeric
  witnesses or a `decidable` finite-prime certificate; per the corpus boundary
  policy we do **not** depend on Mathlib. Instead the two hard theorems
  (`canonical_non_parallelism`, `abelian_collapse`) are manifested `sorry`s in
  Lean, each backed by a **paired Rust/Kani proof** (no Mathlib) in
  `crates/multiplicity/rust/multiplicity-math/src/nonparallelism.rs` and
  registered in `alp_sorry_manifest.json`.
- **Verification Strategy**: re-run `scripts/phase_mirror_loop.py`; the tension
  must drop out of the ranked list (score -> 0) once the module builds clean
  and the manifest is reconciled.

## Metrics (resolution is confirmed when)
- `lean/dynamics/Quarternion.lean` exists and compiles under `lake build`.
- `canonicalAxis` / `norm_axis` / `O_orig` / `O_p` / `commutator_form` are
  defined and free of unmanifested `sorry`.
- `abelian_collapse` (single-axis baseline commutes) is proven.
- `canonical_non_parallelism` is either proven or registered as a manifested
  `sorry` in `alp_sorry_manifest.json` with a paired Rust witness.
- `lake build` succeeds on the `dynamics` module; no new silent leaks.

## Actionable Levers
1. Create `lean/dynamics/Quarternion.lean` defining `Real3`, `rawAxis`,
   `canonicalAxis p : S²`, `O_orig`, `O_p`, `matComm`/`commutes` (no Mathlib;
   core Lean only).
2. Manifest `abelian_collapse` and `canonical_non_parallelism` as `sorry`s and
   register both in `alp_sorry_manifest.json`.
3. Add `crates/multiplicity/rust/multiplicity-math/src/nonparallelism.rs` with a
   **Rust/Kani** backing (no Mathlib): `verify_non_parallelism_distinct_primes`
   and `verify_abelian_collapse_self_commutes`, plus `#[test]` numeric checks
   for the first primes.
4. `cargo test -p multiplicity-math` passes; `kani` proofs verify the two
   manifested lemmas over the bounded prime domain.
5. Re-run `scripts/phase_mirror_loop.py`; confirm this tension's score
   decreases to 0.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
- Source narrative: corpus §1–§4 (MKT / Spin Foam / Canonical MKT Axis)
