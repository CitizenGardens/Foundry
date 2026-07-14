/-!
# Universal ADR Governance Scaffolding

This module centralizes the inductive status types and formal consequence 
entailment invariants for Architectural Decision Records across all models.
-/
namespace Core.ADR

inductive ADRStatus
  | Proposed
  | Accepted
  | Deprecated
  | Superseded (byId : String)
  deriving Repr, DecidableEq

structure ArtifactLink where
  rel : String
  url : String
  deriving Repr

structure ADR where
  id : String
  title : String
  status : ADRStatus
  context : Prop
  decision : Prop
  consequences : Prop
  supersedes : Option String
  links : List ArtifactLink

def is_valid_entailment (adr : ADR) : Prop :=
  (adr.context ∧ adr.decision) → adr.consequences

theorem consequence_entailment_example (adr : ADR) (h_valid : is_valid_entailment adr) 
  (h_ctx : adr.context) (h_dec : adr.decision) : adr.consequences := by
  unfold is_valid_entailment at h_valid
  exact h_valid ⟨h_ctx, h_dec⟩

@[export core_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  id > supersedesId

end Core.ADR
