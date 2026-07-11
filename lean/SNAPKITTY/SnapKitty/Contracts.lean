import SnapKitty.Core

namespace SnapKitty.Contracts

-- Phase 2: Solidity Contract Formalization

-- 1. AttestationRegistry EVM State Machine
-- State tracking for the replay protection nullifier mapping
structure RegistryState where
  usedNullifiers : List Nat

-- 2. Nullifier invariant logic
def submitAttestation (state : RegistryState) (nullifier : Nat) : Option RegistryState :=
  if state.usedNullifiers.contains nullifier then
    none -- Transaction reverts, replay detected
  else
    some { usedNullifiers := nullifier :: state.usedNullifiers }

-- The zero-sorry proof that a nullifier transitions exactly once
theorem nullifier_used_once (state : RegistryState) (nullifier : Nat) (nextState : RegistryState) :
  (submitAttestation state nullifier = some nextState) → 
  (submitAttestation nextState nullifier = none) := by
  intro h
  unfold submitAttestation at h
  split at h
  · contradiction
  · injection h with h_eq
    subst h_eq
    unfold submitAttestation
    simp

end SnapKitty.Contracts
