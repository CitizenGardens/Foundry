# ADR: Formalization of Operator Specifications from Operators.md and Floer Differential.md

## Status

Proposed

## Context

The `Prime/lean/Core/operators/` directory contains two mathematical specification documents and two partially formalized Lean files:

- **`Operators.md`** (1968 lines): 15 major operator families spanning Fibonacci operators, quantum gates, PEQOMA, stochastic controllers, zeta function controllers, and 11 numbered operator categories.
- **`Floer Differential.md`** (78 lines): Extended Floer differential operator `𝓕(u) = ∂u/∂t + J∇H(u) + Σ T_{ij}·∇Φ(u) + ξ(t)` with tensor interactions, stochastic feedback, and prime encoding.
- **`PrimeSeries.lean`** (71 lines): `PrimeOperatorFamily`, `Xi` (prime-weighted operator sum), `Xi_bounded` (Theorem A1), time-dependent variants. **Proved.**
- **`MultiplicityOperator.lean`** (20 lines): `MultiplicityOp = Λ·I`, norm theorem (Theorem C1). **Proved.**
- **`UpdateOperator.lean`** (76 lines): Full update structure with Lipschitz theorem (Theorem A3). **Proved but depends on mathlib** (`HilbertSchmidtOperator`).

The existing infrastructure provides a solid foundation: prime-indexed operator families with boundedness proofs in a complex Banach space. The gap is that ~95% of the operator specifications remain unformalized.

## Decision

We adopt a **tiered verification strategy** that routes each operator to the appropriate proof backend:

| Tier | Verification Backend | When to Use |
|------|---------------------|-------------|
| **T1: Lean 4 (axiom-clean)** | Core Lean 4 + std only | Discrete/combinatorial operators, finite-dimensional algebra, prime encoding, recursive definitions, norm computations on finite matrices |
| **T2: Lean 4 + Rust/Kani** | Lean states theorem; Rust/Kani proves computational invariant | Operators requiring probabilistic bounds, numerical eigenvalue verification, contraction constants with concrete field arithmetic (Goldilocks), tensor network rank bounds |
| **T3: Lean 4 + Mathlib (optional)** | Lean with mathlib as optional dependency | Infinite-dimensional analysis, PDE operators, Hilbert-Schmidt class, spectral theory — only when mathlib is warranted and the proof is non-trivial |

### Why not pure Lean 4?

The Floer differential involves `∂u/∂t` (time evolution), `∇H` (gradient flows on manifolds), and tensor products `T_{ij}` — all of which require substantial mathematical infrastructure. Rather than blocking on mathlib integration or re-developing functional analysis from scratch, we:

1. **State the theorem in Lean 4** with appropriate type class constraints
2. **Prove computational invariants in Rust/Kani** for concrete instantiations (finite-dimensional, Goldilocks field, specific matrix dimensions)
3. **Bridge the gap** via `sorry`-gated axioms that are explicitly tracked in the sorry manifest and backed by Kani verification

### Why not pure Rust/Kani?

Some operators (Fibonacci recursion, prime encoding, discrete stochastic dynamics) are naturally discrete and don't need field-theoretic infrastructure. These are provable directly in Lean 4 with `decide`, `omega`, and `simp`. Using Lean for these gives us machine-checked proofs without any external tooling.

## Operator Inventory and Verification Routing

### Tier 1: Lean 4 (axiom-clean) — 8 operators

These operators involve discrete mathematics, finite algebra, or prime properties and can be fully proved in core Lean 4.

| # | Operator | Specification | Lean Type | Key Property |
|---|----------|---------------|-----------|--------------|
| 1 | **Fibonacci Operator** | `Fφ(n) = Fφ(n-1) + Fφ(n-2)` | `Nat → Nat` (recursive) | `Fφ(0)=0, Fφ(1)=1`, Zeckendorf uniqueness |
| 2 | **Prime-Based Encoding** | `Fφ(n) = ∏ pᵢ^{wᵢ(n)}` | `Nat → Finset Nat × (Nat → Nat)` | Fundamental theorem of arithmetic |
| 3 | **Prime Encoding Map** | `π(x) = argmin_{pᵢ∈ℙ} |x - pᵢ|` | `Real → Nat` | Nearest-prime property |
| 4 | **Reversible Encoding** | `x = f⁻¹(p,d) = p + d` | `Nat × Nat → Real` | `f⁻¹(f(x)) = x` |
| 5 | **Multidimensional Prime Vector** | `p⃗ = (π(x₁),...,π(xₗ))` | `Vector Nat l` | Well-definedness |
| 6 | **Hadamard Gate** | `H = (1/√2)[1 1; 1 -1]` | `Matrix Complex 2 2` | `H² = I`, unitarity |
| 7 | **CNOT Gate** | `CNOT = [1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0]` | `Matrix Complex 4 4` | Unitarity, entanglement |
| 8 | **Phase/T Gates** | `S = diag(1,i)`, `T = diag(1,e^{iπ/4})` | `Matrix Complex 2 2` | Unitarity, `S² = Z`, `T⁴ = S²` |

### Tier 2: Lean 4 + Rust/Kani — 7 operators

These require numerical verification over concrete finite fields (Goldilocks) that Kani can symbolically execute.

| # | Operator | Specification | Lean Statement | Kani Verification |
|---|----------|---------------|----------------|-------------------|
| 9 | **Fibonacci Tensor Dynamics** | `Fφ(n) = Σ_{i,j,k} T_{ijk}·Fφ(i)·Fφ(j)` | `theorem tensor_fibonacci (T : Tensor3) (n : Nat) : ...` | Kani: verify contraction bounds for concrete `T` |
| 10 | **PEQOMA** | `Â_p = p(n)·Â` (prime-encoded operator) | `theorem peqoma_bounded (p : Nat) (h : Nat.Prime p) : ...` | Kani: verify eigenvalue scaling for Goldilocks matrices |
| 11 | **Quantum Multiplicity Processor** | `M(t) = Σₖ Tₖₗ·Ψₖ(t)⊗Ψₗ(t)` | `theorem multiplicity_processor_bound ...` | Kani: verify tensor contraction for fixed dimension |
| 12 | **SHELL Controller** | `S(t+1) = S(t) + α·F(t)·P(n)` | `theorem shell_stability (α : Real) (h_α : |α| < 1) : ...` | Kani: verify convergence for concrete parameters |
| 13 | **Stochastic Controller** | `dx = f(x,u)dt + σ dW` | `theorem stochastic_bounded (σ : Real) (h : ...)` | Kani: verify moment bounds |
| 14 | **Phase-Adaptive Controller** | `Φ(t) = Σ Cᵢⱼ γᵢⱼ(t) Ψᵢ⊗Ψⱼ e^{i(θᵢ+θⱼ)}` | `theorem phase_coherence ...` | Kani: verify phase locking for concrete `C` |
| 15 | **Adaptive Zeta Controller** | `ζ_N(s) × ζ_S(s)`, `S(t) = |ζ_N' - ζ_S'| → 0` | `theorem zeta_equilibrium ...` | Kani: verify convergence for truncated sums |

### Tier 3: Lean 4 + Mathlib (optional) — 3 operators

These require infinite-dimensional analysis. Mathlib provides the infrastructure; we use it only where the proof is non-trivial.

| # | Operator | Specification | Mathlib Dependency | Priority |
|---|----------|---------------|--------------------|----------|
| 16 | **Floer Differential** | `𝓕(u) = ∂u/tp + J∇H + Σ T∇Φ + ξ` | `InnerProductSpace`, `ContDiff`, `MeasureTheory` | High |
| 17 | **Hilbert-Schmidt Operator** | `HilbertSchmidtOperator H H` | `Analysis.InnerProductSpace.HilbertSchmidt` | High (unblocks UpdateOperator) |
| 18 | **Fourier/Laplace Transforms** | `𝓕(ρ) = ∫ρ(t)e^{-iωt}dt` | `MeasureTheory.Fourier`, `IntegralTransform` | Medium |

### Tier 1+2 Hybrid: 7 operator categories

The 11 numbered operator categories from §7 of Operators.md are mostly restatements of standard mathematical operators applied to the multiplicity framework. We formalize the core types in Lean 4 and verify concrete instances with Kani.

| Category | Lean 4 Statement | Kani Verification |
|----------|------------------|-------------------|
| **Algebraic** (matrix/vector, eigenvalue) | Matrix multiplication, eigenvalue decomposition | Kani: verify eigenvalue correctness |
| **Functional** (exponential, logarithmic) | `e^{βρ}`, `log(1+ρ)` | Kani: verify convergence bounds |
| **Probabilistic** (expectation, Gaussian) | `E[ρ] = ∫ρ·p(ρ)dρ` | Kani: verify for discrete distributions |
| **Topological** (homology, graph Laplacian) | `H(ρ) = βₖ`, `L = D-A` | Lean: decide for finite graphs |
| **Differential Geometry** (curvature, Lie derivative) | `R(ρ) = g^{ij}R_{ij}`, `L_X(ρ) = ∇_X ρ` | Mathlib (if needed) |
| **Chaos/Fractal** (dimension, Lyapunov) | `D_f = lim log N(ε)/log(1/ε)` | Kani: verify for concrete maps |
| **Integral Transform** (Fourier, Laplace) | `F(ρ) = ∫ρ(t)e^{-iωt}dt` | Mathlib (if needed) |

## Implementation Plan

### Phase 6.1: Fibonacci + Prime Encoding (Lean 4 only)

**Files to create:**
```
Prime/lean/Core/operators/FibonacciOperator.lean
Prime/lean/Core/operators/PrimeEncoding.lean
```

**Definitions:**
- `fibonacci : Nat → Nat` (standard recursive)
- `fibonacci_prime_encoding : Nat → Finset Nat × (Nat → Nat)`
- `prime_encoding_map : Real → Nat` (nearest prime)
- `reversible_encode : Nat × Nat → Real`

**Theorems:**
- `fibonacci_zero : fibonacci 0 = 0`
- `fibonacci_one : fibonacci 1 = 1`
- `fibonacci_recurrence : fibonacci (n+2) = fibonacci (n+1) + fibonacci n`
- `zeckendorf_unique` (every positive integer has a unique Zeckendorf representation)
- `prime_encoding_fundamental` (unique prime factorization of encoded terms)
- `reversible_encode_cancel` (round-trip property)

**Verification:** Pure Lean 4, `decide`/`omega`/`simp`. No external tools needed.

### Phase 6.2: Quantum Gates (Lean 4 + Kani)

**Files to create:**
```
Prime/lean/Core/operators/QuantumGates.lean
Prime/crates/core/tests/kani_quantum_gates.rs
```

**Lean definitions:**
- `hadamard : Matrix ℂ 2 2`
- `cnot : Matrix ℂ 4 4`
- `phase_gate : Complex → Matrix ℂ 2 2`
- Unitarity theorems: `hadamard_is_unitary`, `cnot_is_unitary`, etc.

**Kani verification:**
- Symbolically verify `H * H = I` for Goldilocks-backed complex arithmetic
- Verify CNOT acts correctly on computational basis states
- Verify phase gate eigenvalues

### Phase 6.3: Floer Differential (Lean 4 + Mathlib + Kani)

**Files to create:**
```
Prime/lean/Core/operators/FloerDifferential.lean
Prime/crates/core/tests/kani_floer_bounds.rs
```

**Lean definitions (Tier 3):**
- `FloerDifferential` structure with fields: `J : E →L[ℂ] E` (almost complex structure), `H : E → ℝ` (Hamiltonian), `T : E →L[ℂ] (E →L[ℂ] E)` (tensor coefficients), `Φ : E → ℝ` (potential), `ξ : ℝ → E` (stochastic term)
- `floer_operator : FloerDifferential E → (ℝ × E) → E` defined as `fun (t,u) => ∂u/∂t + J * gradient H u + Σ T_{ij} * gradient Φ u + ξ t`
- Well-definedness theorem (requires `sorry` for the partial derivative until PDE infrastructure is available)

**Kani verification:**
- For a concrete finite-dimensional instantiation (e.g., `E = Fin n → Goldilocks`), verify the operator is Lipschitz with computable constant
- Verify the tensor contraction `Σ T_{ij}·∇Φ(u)` is bounded

### Phase 6.4: PEQOMA + Processor (Lean 4 + Kani)

**Files to create:**
```
Prime/lean/Core/operators/PEQOMA.lean
Prime/lean/Core/operators/MultiplicityProcessor.lean
Prime/crates/core/tests/kani_peqoma.rs
```

**Lean definitions:**
- `PrimeEncodedOperator` structure: `base_op : E →L[ℂ] E`, `prime_modulus : Nat → Nat`, `encoding : Nat → ℂ`
- `prime_encoded_action : PrimeEncodedOperator → Nat → E →L[ℂ] E`
- `MultiplicityProcessor` structure: eigenvalues, time evolution, feedback

**Kani verification:**
- Verify eigenvalue scaling: `Â_p|ψ⟩ = p(n)·Â|ψ⟩` for concrete matrices
- Verify processor convergence for specific parameter sets

### Phase 6.5: Controllers (Stochastic, Phase, Zeta, SHELL) — Lean 4 + Kani

**Files to create:**
```
Prime/lean/Core/operators/StochasticController.lean
Prime/lean/Core/operators/PhaseAdaptiveController.lean
Prime/lean/Core/operators/ZetaController.lean
Prime/lean/Core/operators/ShellController.lean
```

**Strategy:** Each controller gets a Lean 4 structure with well-definedness + stability theorems (stated with `sorry` for the hard分析 parts), backed by Kani verification for concrete parameter ranges.

### Phase 6.6: Operator Categories (Lean 4 + Kani)

**Files to create:**
```
Prime/lean/Core/operators/AlgebraicOperators.lean
Prime/lean/Core/operators/FunctionalOperators.lean
Prime/lean/Core/operators/ProbabilisticOperators.lean
```

**Strategy:** Define type classes for each category, prove the standard mathematical properties, verify concrete instances with Kani.

## Build Configuration

### Lakefile Changes

```lean
-- Add to Prime/lean/lakefile.lean
lean_lib Operators where
  srcDir := "."
  roots := #[`Core.operators]
```

### Cargo.toml Changes (for Kani proofs)

```toml
# Add to Prime/crates/core/Cargo.toml
[dev-dependencies]
kani = "0.50"

[[bench]]
name = "kani_quantum_gates"
harness = false
```

## Success Criteria

1. **All 8 Tier 1 operators** proved in Lean 4 with zero sorry, zero axioms
2. **All 7 Tier 2 operators** stated in Lean 4, Kani proofs passing for concrete instances
3. **Floer Differential** stated in Lean 4 with at most 2 sorry'd axioms (PDE derivative, tensor summability), Kani-verified for finite-dimensional instantiation
4. **UpdateOperator** dependency on mathlib resolved (either by providing a local `HilbertSchmidtOperator` definition or by using Kani to verify the bound directly)
5. **All new modules** build with `lake build` and pass `lake test`
6. **CI integration**: `ci-proof-hash.yml` updated to build new operator modules

## Consequences

- **Positive:** 15+ operators move from LaTeX spec to machine-verified theorems. The operator framework becomes a formally verified component of the Phase Mirror.
- **Positive:** The tiered strategy avoids blocking on mathlib for discrete/combinatorial operators while still enabling infinite-dimensional analysis where needed.
- **Negative:** Tier 2 (Kani) proofs are computational, not axiomatic — they verify specific instances, not universal properties. This is an acceptable trade-off for operators that are inherently parameterized.
- **Negative:** Tier 3 (Mathlib) introduces an optional dependency. The `sorry` manifest must track all mathlib-gated axioms explicitly.
- **Risk:** The Floer differential's PDE component (`∂u/∂t`) may require significant mathlib infrastructure. Mitigation: start with the finite-dimensional discretization, defer the full PDE treatment.
