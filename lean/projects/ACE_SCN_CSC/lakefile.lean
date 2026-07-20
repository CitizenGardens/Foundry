import Lake
open Lake DSL

package ace_scn_csc {
  version := v!"0.1.0"
}

lean_lib Formalization { srcDir := "src" }
  srcDir := "src"
}

@[default_target]
lean_exe Main
