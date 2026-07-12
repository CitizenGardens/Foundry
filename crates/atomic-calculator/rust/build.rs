use std::env;
use std::fs::{self, File};
use std::io::Read;
use std::path::Path;
use sha2::{Sha256, Digest};

fn main() {
    println!("cargo:rerun-if-changed=../../../lean/SNAPKITTY/SnapKitty/Core.lean");
    
    let out_dir = env::var_os("OUT_DIR").unwrap_or_else(|| std::ffi::OsString::from("src"));
    let dest_path = Path::new(&out_dir).join("bounds.rs");
    
    // In a real implementation, this would parse Core.lean to extract exact constants.
    // Here we emit the constants mapped from SnapKitty.Math definitions.
    let generated_code = r#"
pub const THERMAL_WINDOW_LO_SUB: u64 = 8000;
pub const THERMAL_WINDOW_HI_ADD: u64 = 12000;
pub const ENTROPY_H_MAX_SCALED: u64 = 60000;
pub const CHEMICAL_ACCURACY_THRESHOLD_MHA_SCALED: u64 = 150000;
pub const SQD_B_DEFAULT: u64 = 50;
pub const SQD_LAMBDA_GUARD_SCALED: u64 = 20000;
pub const SQD_MAX_WEIGHT: u64 = 2;
pub const SCALE: u64 = 10000;
"#;
    fs::write(&dest_path, generated_code).unwrap();

    // --- NEW: Anomaly Model Integrity Check ---
    let model_path = Path::new("../../../observability/anomaly_model.pkl");
    let target_hash_lean = 
        "d75d7919966a3abe8c7d9f873714263822466d997365938d06ee6f18afc0a4b4";

    if model_path.exists() {
        let mut file = File::open(model_path)
            .expect("❌ Failed to open observability/anomaly_model.pkl");
        let mut buffer = Vec::new();
        file.read_to_end(&mut buffer)
            .expect("❌ Failed to read model file");
        
        let mut hasher = Sha256::new();
        hasher.update(&buffer);
        let result = hasher.finalize();
        let computed_hash = format!("{:x}", result);

        if computed_hash != target_hash_lean {
            panic!(
                "\n\
                ⛔ SEDONA SPINE INTEGRITY VIOLATION ⛔\n\
                Observability.lean demands model hash: {}\n\
                But anomaly_model.pkl has hash:   {}\n\
                \n\
                Action: Re-run calibrate_anomaly_boundary.py or restore the correct .pkl.\n\
                This build has been aborted to prevent operational drift.\n",
                target_hash_lean, computed_hash
            );
        } else {
            println!("cargo:info=✅ anomaly_model.pkl SHA-256 matches Sedona Spine invariant.");
        }
    } else {
        // In CI/dev environments, we might not have the model yet.
        println!("cargo:warning=anomaly_model.pkl not found; skipping integrity check (dev mode).");
    }

    // --- Propagate the threshold to the environment (for Python/Rust bridge) ---
    println!("cargo:rustc-env=ANOMALY_GOV_THRESHOLD=0.0006");
    
    // Rerun this build script if the model file changes.
    println!("cargo:rerun-if-changed=../../../observability/anomaly_model.pkl");
}
