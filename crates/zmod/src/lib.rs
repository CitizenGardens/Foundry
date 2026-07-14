// ZMOD Continuous Mathematics Verified by Kani

pub fn step_interaction(grad: f64, p: f64) -> f64 {
    // Continuous relaxation: if gradient is a multiple of p (within epsilon), return 1.0
    // Otherwise return a fractional interaction <= 1.0
    if p <= 0.0 {
        return 0.0;
    }
    let remainder = grad % p;
    // Normalized distance
    let dist = (remainder / p).abs();
    // Decay function for fractional interaction
    1.0 / (1.0 + dist)
}

pub fn multiplicity_tensor(grads: &[f64], p: f64) -> f64 {
    let mut sum = 0.0;
    for &g in grads {
        sum += step_interaction(g, p);
    }
    sum
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_step_interaction_bounded() {
        let grad: f64 = kani::any();
        let p: f64 = kani::any();
        
        kani::assume(grad.is_finite() && p.is_finite());
        kani::assume(grad >= 0.0 && p > 0.0);
        
        let interaction = step_interaction(grad, p);
        kani::assert(interaction <= 1.0, "Step interaction must be bounded by 1.0");
        kani::assert(interaction >= 0.0, "Step interaction must be non-negative");
    }

    #[kani::proof]
    fn verify_multiplicity_tensor_bounded() {
        let g1: f64 = kani::any();
        let g2: f64 = kani::any();
        let p: f64 = kani::any();
        
        kani::assume(g1.is_finite() && g2.is_finite() && p.is_finite());
        kani::assume(g1 >= 0.0 && g2 >= 0.0 && p > 0.0);
        
        let grads = [g1, g2];
        let tensor = multiplicity_tensor(&grads, p);
        
        // Bounded by T * 1.0
        kani::assert(tensor <= 2.0, "Multiplicity tensor bounded by T");
    }
}
