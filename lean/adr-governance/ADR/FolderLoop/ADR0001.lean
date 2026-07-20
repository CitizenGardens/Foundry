import ADR.Core
import ADR.Proofs

/-!
# ADR-0001 — PhaseMirror Folder-Loop Module

Formal artifact for the architectural decision to build a PhaseMirror module
that runs the loop over a *specified input folder* and writes its report to a
*specified output folder*.

The module reuses the universal `ADRRecord` scaffolding from `ADR.Core` and
the governance invariants from `ADR.Proofs`, so it is machine-checked by the
same `ValidADR` proof block that validates every other governance ADR.
-/

namespace ADR.FolderLoop

open ADR

/-- Stable identifier for this ADR. -/
def thisId : String := "ADR-0001"

/-- Human-readable module label, used in report headers and artifact links. -/
def moduleName : String := "phasemirror-folder-loop"

/--
The fully-formed ADR-0001 record.

- `context` states the operator need for a path-parameterized loop entry point.
- `decision` commits to an (input-folder, output-folder) parameterized module.
- `consequences` lists the four derived outcomes, each individually entailed
  by the `entails` predicate from `ADR.Proofs`.
-/
def adr0001 : ADRRecord := {
  id := thisId
  title := "PhaseMirror Folder-Loop Module"
  status := ADRStatus.Accepted
  context :=
    "Operators need a reusable entry point that applies the PhaseMirror loop " ++
    "to an arbitrary directory of sources and emits a structured report " ++
    "without hard-coding paths into the binary."
  decision :=
    "Build a module that accepts an input folder path and an output folder " ++
    "path (CLI flags or config), runs the loop over the input folder, and " ++
    "writes the generated report into the output folder."
  consequences := [
    "Input and output locations become deployment-time parameters, not build-time constants.",
    "Multiple pipelines can share one binary by varying the two folder arguments.",
    "Report artifacts are isolated per run, simplifying audit and traceability.",
    "The module must validate that the input folder exists and is readable before looping."
  ]
  supersedes := none
  links := [
    ({ url := "docs/folder-loop-design.md" } : ArtifactLink),
    ({ url := "phase-mirror-cli/phasemirror-folder-loop" } : ArtifactLink),
    ({ url := "PhaseMirror-LOOP-GOAL.md" } : ArtifactLink)
  ]
}

/--
Governance validation: `adr0001` satisfies every `ValidADR` invariant.

- `accepted_immutable`: `adr0001` is `Accepted`; per the governance law any
  equal record preserves `Accepted` unless superseded (see
  `adr0001_immutable_when_accepted`).
- `consequences_entailed`: the `entails` checker from `ADR.Proofs` is `True`
  for all `(context, decision, consequence)` triples, so each listed
  consequence is entailed.
- `no_circular_supersession`: `supersedes = none`, decided by `decide`.
- `traceability`: vacuous for `Proposed`; once promoted to `Accepted` the
  `links` field is non-empty, decided by `decide`.
-/
theorem adr0001_valid : ValidADR adr0001 :=
  ValidADR.mk
    (fun _ _ => trivial)
    (fun _ _ => trivial)
    (by decide)
    (by decide)

/--
If `adr0001` is later marked `Accepted` and given no superseding ADR, its
status is immutable under the universal governance law (`accepted_immutable`).
-/
theorem adr0001_immutable_when_accepted
    (b : ADRRecord)
    (h_eq : adr0001 = b) :
    adr0001.status = ADRStatus.Accepted → b.status = ADRStatus.Accepted := by
  intro h_acc
  rw [←h_eq]
  exact h_acc

end ADR.FolderLoop
