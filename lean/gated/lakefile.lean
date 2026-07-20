import Lake
open Lake DSL

require std from git "https://github.com/leanprover/std4" @ "v4.32.0"

package gated where

@[default_target]
lean_lib GatedCore where
  srcDir := "."
  roots := #[
    `EMDRA.Emdra,
    `NEUROMORPHIC.Neuromorphic,
    `NEWTON_HOLOGRPAHY.NewtonHologrpahy,
    `MATRIX_ENGINE.MatrixEngine,
    `STRATIFIED_GOVERNANCE.StratifiedGovernance,
    `KNOT_IN_TIME.KnotInTime,
    `Ontoς.Ontoς,
  ]
