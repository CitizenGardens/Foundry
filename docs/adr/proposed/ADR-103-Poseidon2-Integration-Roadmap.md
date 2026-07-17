# ADR-103: Poseidon2(t=9, r=8) Integration Roadmap (Track B)

**Status:** Proposed
**Supersedes:** — (companion to ADR-046; refines the "5,087 architectural target")
**Related:** `crates/ace-zk/circuits/ace.circom`, `src/f1_surface/witness_commitment.circom`, `constraints.circom` (budget lock), `circuits/LANGLANDSCHECK_170_INVARIANT.md`

---

## Context

The `Poseidon2(t=9, r=8)` topology is the canonical hash for the ACE governance
circuit. Today **every Poseidon2 instantiation in the repository is a stub**:

| File | What it actually is |
|------|----------------------|
| `crates/ace-zk/circuits/poseidon2.circom` | `Poseidon2TopologyLock()` — asserts `t===9`, `r===8` only. No permutation, no S-box, no sponge. |
| `crates/ace-zk/circuits/ace.circom:93-98` | `cas_commitment <== epsilon + delta + ...` — a **linear sum**, explicitly commented *"will be replaced with actual Poseidon2 call."* |
| `src/f1_surface/witness_commitment.circom:3-11` | `Poseidon2Sponge()` / `Poseidon2()` — **empty templates** (`signal input ...; signal output ...; }`). No body. |

Consequently `ace.circom` compiles to **133 constraints** (131 NL + 2 LIN) — the
Poseidon2 hash contributes **zero** of those. The "5,087 architectural budget"
(ADR-046 / ADR-102) decomposes as `384 + 3,171 + 1,500 + 32`. Of these four
buckets:

- `32` (control/routing) — **real**, present in `ace.circom` (the `wac_mode`,
  `N_0`, `M` guards + `Poseidon2TopologyLock`).
- `384` (multiplicity state verification) — **partially** present (the `current_mu[i]*step_n===h_hat[i]`,
  `X_n*proxy_l1_norm===m_bar_n*SCALE`, `R_t*(r_raw-R_t)===0` checks).
- `3,171` (Poseidon_h) and `1,500` (Poseidon_gamma) — **entirely absent**;
  they are *design figures carried forward from the spec*, **not measured from any
  compiled circuit**. There is no code in the repo that would emit them.

**This ADR does NOT re-assert 3,171 / 1,500 / 4,804 as compiled facts.**
Those numbers are explicitly **to-be-measured** (see §Decision, Phase 2). Asserting
them as current would re-introduce the exact "compiled reality" misclaim we removed
in the ADR-046/095/096/097/098/102 + whitepaper correction pass.

Available real substrate (so the roadmap is buildable, not aspirational):
`circuits/node_modules/circomlib/circuits/poseidon.circom` ships the primitive
gates — `Sigma(t)`, `Ark(t, C, r)`, `Mix(t, M)`, `MixLast(t, M, s)` — and
`eddsaposeidon.circom` ships a reference `Poseidon2(t, r)` over the Goldilocks
field. The integration is therefore *wiring existing gates*, not inventing cryptography.

---

## Decision

Replace the stubbed Poseidon2 with a real `Poseidon2(t=9, r=8)` sponge built
from circomlib primitives, delivered as a **phased Track B deliverable**. Each phase
is independently compilable and constraint-counted; no phase asserts a number it has
not measured.

### Phase 1 — Real `Poseidon2(t=9, r=8)` primitive (measurable)
- Implement `crates/ace-zk/circuits/poseidon2.circom` as an actual sponge using
  circomlib `Ark`/`Mix`/`MixLast`/`Sigma` over the BN254/Goldilocks field
  (or import `circomlib/circuits/eddsaposeidon.circom` and parameterize `t=9, r=8`).
- **Measure** its constraint count via `circom ... --r1cs` + `snarkjs r1cs info`.
  Record the real number in this ADR (replacing the *3,171/1,500* placeholders).
- Wire `Poseidon2TopologyLock` to verify the realized `t`/`r` match the primitive.

### Phase 2 — Bind `cas_commitment` to the real hash (measurable)
- In `ace.circom`, replace the linear-sum stub (`ace.circom:97`) with
  `cas_commitment <== poseidon_gamma.out` where `poseidon_gamma` is the Phase-1
  `Poseidon2(5, 9, 8)` (5 inputs: `h_commitment, X_n, R_t, max_wac_product, retry_nonce`).
- **Measure** the new `ace.circom` total. Record it.

### Phase 3 — Reconcile to the 5,087 architectural target (gated)
- Only after Phase 1+2 produce *measured* totals do we compare against
  `384 + 3,171 + 1,500 + 32`. If the measured sum differs, **update the
  architectural target to the measured value** and amend ADR-046/102 — do NOT
  retro-edit the circuit to hit 5,087.
- The `constraints.circom` budget lock (`total_cost === 5087`) becomes a *regression
  guard*: once the real total is known, it asserts that exact measured number.

### Phase 4 — Shared soundness hardening (carried from Vector 3)
- The under-constrained quotient arithmetic found in `langlandsCheck.circom`
  (`term1`/`term2`/`factor` use `<--` without `===`; see
  `circuits/LANGLANDSCHECK_170_INVARIANT.md` §3) is the same class of bug that
  the linear-sum stub in `ace.circom` represents at the hash layer. Both must be
  fixed before either circuit is a trust boundary. Add Kani/Lean guards that the
  compiled constraint count is non-zero for the hash and that every `<--` hint has a
  matching `===` re-constraint.

---

## Consequences

### Positive
- Moves the 5,087 figure from *asymptote* toward *reality* with every phase
  producing a measured, reproducible count.
- Uses shipped circomlib gates — low cryptographic risk, buildable this cycle.
- Converts the budget-lock stub into a genuine regression guard.

### Negative / Constraints
- **Unknown final count.** Until Phase 1 measures it, the 3,171/1,500/4,804
  figures are **unsourced** and must not appear in any external claim.
- Poseidon2 over BN254 with `t=9` is a non-standard width (circomlib reference
  uses `t=3`/Goldilocks `t=5`); parameterization + round-constant selection
  need verification against the spec's field choice.
- Phase 4 hardening is a prerequisite for *any* production use; the current stubs are
  sound only under an honest prover.

---

## Implementation Steps

1. **Implement** `crates/ace-zk/circuits/poseidon2.circom` from circomlib gates; `circom --r1cs` + `snarkjs r1cs info`; record real count here.
2. **Bind** `cas_commitment` in `ace.circom` to `Poseidon2(5,9,8).out`; recompile; record new `ace.circom` total.
3. **Reconcile** measured totals vs `384+3171+1500+32`; amend ADR-046/102 if the target shifts.
4. **Harden** `langlandsCheck.circom` (`<--` → `===`) and add Kani count guards.
5. **Update** `constraints.circom` to assert the *measured* total as a regression lock.
6. **CI**: `circom` compile + `snarkjs r1cs info` constraint-count assertion on every PR touching `crates/ace-zk/circuits/`.

## References
- `crates/ace-zk/circuits/ace.circom` — governance prototype (133 constraints, stubbed hash)
- `crates/ace-zk/circuits/poseidon2.circom` — topology lock only
- `src/f1_surface/witness_commitment.circom` — empty `Poseidon2`/`Poseidon2Sponge` templates (the intended integration point)
- `circuits/LANGLANDSCHECK_170_INVARIANT.md` — Vector 3 formalization + under-constraint finding
- `circuits/node_modules/circomlib/circuits/poseidon.circom` — real `Mix`/`Ark`/`Sigma` primitives
- ADR-046, ADR-102 — 5,087 architectural target (now correctly stratified)
