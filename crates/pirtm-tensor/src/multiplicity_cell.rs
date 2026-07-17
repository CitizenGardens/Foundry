use ndarray::{Array1, Array2};

/// The Multiplicity Cell trait, implementing the finite-dimensional surrogate
/// of the universal multiplicity recursion on H_lawful.
///
/// For any input state `s`:
///   (coherent_weight, arta_defect) = F(s)
///
/// The operator norm of F must be ≤ 1. This ensures that every application
/// of the cell is contractive, preventing runaway divergence.
pub trait MultiplicityCell {
    /// Dimension of the input state (number of active primes).
    fn dim(&self) -> usize;

    /// Forward pass: state → (coherent_weight, arta_defect).
    fn forward(&self, state: &Array1<f64>) -> (f64, f64);

    /// Operator norm (induced L2 norm) of the linear approximation.
    fn op_norm(&self) -> f64;

    /// True if the cell is strictly contractive (op_norm ≤ 1).
    fn is_contractive(&self) -> bool {
        self.op_norm() <= 1.0
    }
}

/// A multiplicity cell based on a linear map.
///
/// The cell's operator norm is bounded by the Frobenius norm of its parameters,
/// which is enforced to be ≤ 1 at construction time via a debug assertion.
pub struct LinearMultiplicityCell {
    dim: usize,
    w_coherence: Array1<f64>,   // length dim
    w_defect: Array2<f64>,      // shape (k, dim)
    op_norm_sq: f64,            // cached squared operator norm
}

impl LinearMultiplicityCell {
    /// Create a new linear cell.
    ///
    /// # Panics
    /// Panics if `w_defect` does not have `dim` columns, or if the Frobenius
    /// norm of the combined parameters exceeds 1.0.
    pub fn new(w_coherence: Array1<f64>, w_defect: Array2<f64>) -> Self {
        let dim = w_coherence.len();
        assert_eq!(
            w_defect.ncols(),
            dim,
            "Defect matrix must have same number of columns as state dimension"
        );

        // Frobenius norm squared = sum of all squared entries
        let frob_sq = w_coherence.iter().map(|x: &f64| x.powi(2)).sum::<f64>()
            + w_defect.iter().map(|x: &f64| x.powi(2)).sum::<f64>();

        assert!(
            frob_sq <= 1.0 + 1e-12,
            "Combined Frobenius norm must be ≤ 1 for contractivity, got {:.6}",
            frob_sq
        );

        LinearMultiplicityCell {
            dim,
            w_coherence,
            w_defect,
            op_norm_sq: frob_sq,
        }
    }
}

impl MultiplicityCell for LinearMultiplicityCell {
    fn dim(&self) -> usize {
        self.dim
    }

    fn forward(&self, state: &Array1<f64>) -> (f64, f64) {
        let coherent = self.w_coherence.dot(state);
        let defect_vec = self.w_defect.dot(state);
        let defect = defect_vec.dot(&defect_vec).sqrt();
        (coherent, defect)
    }

    fn op_norm(&self) -> f64 {
        self.op_norm_sq.sqrt()
    }
}
