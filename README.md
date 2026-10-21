# Trencho v3

Godot 4.7 project. Open `project.godot` and run (F6/F5 from the main scene/project).

## T3-HIER-001 — Hierarchical infantry proof

An autonomous, observation-only scenario: Operational HQ chooses Objective A;
Company assigns the nearest platoon as main effort and retains the second;
the main platoon assigns seizure and support to different squads; the seizure
squad chooses a clear north/south bypass around the rock; soldiers move on
their own paths with distinct positions, speeds, waypoint progress and separation.
No player tactical input exists. Sixteen individuals belong to four squads.

`scenario.gd` owns scenario state and command decisions, `squad.gd` owns local
route planning and separation, `soldier.gd` owns individual movement. `view.gd`
only advances and draws that model. The console emits contextual decision JSON.

These are small proof structures, not a complete command/communications architecture.
Formation sizes, fixed objective, deterministic main/reserve selection, immediate
intent propagation, simple known rectangular terrain and geometric presentation
are provisional fixtures (PA-HIER-001 through PA-HIER-006). There is no combat,
logistics, information propagation, persistence or old v2 feature migration.
Commanders are logical roles with an HQ marker; separate platoon-leader personnel
and succession are not simulated in this slice.

## Verification

Create an `artifacts` folder, then run Godot with:

```
--headless --path . --script check.gd --log-file artifacts/check.log
```

The test checks autonomous completion, command decomposition, reserve immobility,
all sampled individual obstacle clearance, non-overlap, southern alternative
navigation, independent stalled-soldier behavior and five-echelon trace context.
For a real renderer run and timed screenshots, omit `--headless` and append
`-- --visual`. Generated evidence is ignored by Git.

Verified locally with Godot 4.7.2 stable Steam: 37 model checks passed over 40
simulated seconds; a real OpenGL run reached Objective A without input in a
25-second run. Inspected 13-second approach and 25-second arrival captures:
four separate advancing actors, separate support, staged reserve, clear bypass,
and readable diagnostic hierarchy. No human play evaluation or fun claim.

Navigation is intentionally limited to west-to-east approaches around the supplied
single rectangle. Do not reuse it as general terrain pathfinding. No export
verification is claimed. Editor import produced an engine object-profiler
`user://` directory warning under this sandbox; the runtime checks and rendered
scenario completed successfully.
