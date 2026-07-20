pub mod ace_air;
pub mod certification;
pub mod circuit;
pub mod consensus;
pub mod hamiltonian;
pub mod indexing;
pub mod pell_vdf;
pub mod poseidon2;
pub mod resonance;
pub mod scalar;
pub mod simd;
pub mod simulation;

pub const MODULUS: u64 = 0xFFFF_FFFF_0000_0001;
pub const SCALE_GOLDILOCKS: u64 = 1 << 40;

pub use ace_air::*;
pub use certification::{CertificationStatus, FormalStabilityCertificate, SpectralWitness};
pub use circuit::ConvergencePublicInputsPro;
pub use consensus::*;
pub use hamiltonian::{Hamiltonian, HamiltonianTerm};
pub use indexing::PrimeMask;
pub use poseidon2::*;
pub use resonance::ResonanceWord;
pub use scalar::GoldilocksField;
pub use simulation::AzTftcSimulation;
