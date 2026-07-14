use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CollatzResult {
    pub start_bound: String,
    pub end_bound: String,
    pub max_steps: u32,
    pub max_value_reached: String,
    pub cycle_detected: bool,
    pub verified: bool,
}

/// Bitwise optimized step
#[inline(always)]
fn next_collatz(n: u128) -> Option<u128> {
    if n & 1 == 0 {
        Some(n >> 1)
    } else {
        // 3n + 1
        n.checked_mul(3)?.checked_add(1)
    }
}

/// Computes the Collatz trajectory for a single number.
/// Returns (steps, max_value) or None if overflow occurs (which is treated as unverified).
fn compute_trajectory(mut n: u128) -> Option<(u32, u128)> {
    let mut steps = 0;
    let mut max_val = n;
    
    while n > 1 {
        n = next_collatz(n)?;
        if n > max_val {
            max_val = n;
        }
        steps += 1;
    }
    
    Some((steps, max_val))
}

#[cfg(not(target_arch = "wasm32"))]
pub fn verify_range(start: u128, end: u128) -> CollatzResult {
    use rayon::prelude::*;

    let result = (start..=end).into_par_iter().map(|n| {
        match compute_trajectory(n) {
            Some((steps, max_val)) => (steps, max_val, false, true),
            None => (0, 0, false, false), // cycle or overflow
        }
    }).reduce(|| (0, 0, false, true), |a, b| {
        (
            a.0.max(b.0),
            a.1.max(b.1),
            a.2 | b.2,
            a.3 & b.3,
        )
    });

    CollatzResult {
        start_bound: start.to_string(),
        end_bound: end.to_string(),
        max_steps: result.0,
        max_value_reached: result.1.to_string(),
        cycle_detected: result.2,
        verified: result.3,
    }
}

#[cfg(target_arch = "wasm32")]
pub fn verify_range(start: u128, end: u128) -> CollatzResult {
    let mut max_steps = 0;
    let mut max_value = 0;
    let mut cycle = false;
    let mut verified = true;

    for n in start..=end {
        if let Some((steps, val)) = compute_trajectory(n) {
            if steps > max_steps { max_steps = steps; }
            if val > max_value { max_value = val; }
        } else {
            verified = false;
        }
    }

    CollatzResult {
        start_bound: start.to_string(),
        end_bound: end.to_string(),
        max_steps,
        max_value_reached: max_value.to_string(),
        cycle_detected: cycle,
        verified,
    }
}
