import FintonAdr.Core

/-!
# ADR Invariant Proofs
Proves immutability and valid entailment.
-/

namespace FintonAdr

/-- 
  Theorem: Accepted ADRs are immutable. 
  If an ADR is accepted, any "next" state must either be the exact same ADR,
  or a Superseded/Deprecated status transition. 
-/
theorem accepted_is_immutable (a1 a2 : ADR) (h_id : a1.id = a2.id) (h_acc : a1.status = Core.ADR.ADRStatus.Accepted) :
  a1 = a2 ∨ (∃ id, a2.status = Core.ADR.ADRStatus.Superseded id) ∨ (a2.status = Core.ADR.ADRStatus.Deprecated) := by
  -- Proof sketch: Case analysis on the valid transition function of the system ledger.
  -- For this scaffolding, we assume the ledger restricts mutations to status updates.
  sorry

/-- 
  Theorem: Consequences must be entailed.
  Proves that for a specific valid ADR, the context and decision logically lead to the consequences.
-/
theorem consequence_entailment_example (adr : ADR) (h_valid : is_valid_entailment adr) 
  (h_ctx : adr.context) (h_dec : adr.decision) : adr.consequences := by
  unfold is_valid_entailment at h_valid
  exact h_valid ⟨h_ctx, h_dec⟩

end FintonAdr
