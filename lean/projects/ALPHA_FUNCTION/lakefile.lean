import Lake
open Lake DSL

package FormalizationPkg {
  name := "formalization"
  version := "0.1.0"
}

lean_lib Formalization

@[default_target]
lean_lib Formalization
lean_lib Formalization { srcDir := "src" }
