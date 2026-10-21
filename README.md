# Trencho v3

Godot 4.7 project. Open `project.godot` and run (F6/F5 from the main scene/project).

## T3-SUP-003 — Physical ammunition custody

The advancing squad starts with separate inventories of 0 / 6 / 1 / 1 abstract
BoltActionRifleAmmo rounds. At T=1, nearby P1-A.2 gives P1-A.1 two rounds;
sharing requires a 42-unit radius, compatibility, and a donor retaining at
least two rounds. The squad total is derived from living member inventories.
Inactive custody remains accounted but does not contribute to living readiness.

The squad stages at its own first bypass waypoint, then holds below the 16-round
readiness fixture. It requests eight rounds; Company approval does not change
inventory. After a one-second loading interval, a finite military depot loads
8 of its 12 rounds into a truck. The truck travels on a short fixture road at
48 units/second to (350,200); cargo never counts as soldier inventory in transit.
At staging, only compatible soldiers within70units can unload; lowest-inventory
members receive rounds first. Actual delivered inventory permits final approach.
Near (735,290), a soldier within40units secures/retrieves the enemy container's
four compatible rounds. Custody changes exactly once, without faction conversion.
No production/capability-unlock system or grant is introduced.

Initial accounting: soldiers8 + depot12 + truck0 + enemy4 =24.
Final accounting: soldiers20 (4/8/4/4) + depot4 + truck0 + enemy0 =24.
All transfers log source, quantity, destination, scenario time, category and reason.
The truck has a separate cargo inventory and physical position. Driver personnel,
fuel, damage, general routing and combat are not simulated. The depot is already
military-owned; it is not a rear authorization/export implementation.

The supplied fixture reaches staging/requests at aboutT5.7, loads atT6.8,
delivers atT12.2, resumes after actual delivery and captures atT19.5.
PA-SUP-001 through007 remain provisional: abstract round units, deterministic
nearby sharing, 16-round threshold, eight-round shipment, automatic proximity
capture, initial military stock and initialized shortage without firing.

Run `check_supply.gd` using the same command pattern below. Focused checks cover
individual independence, sharing distance/conservation, inactive custody,
remote-unload rejection, 2,100 conservation samples, stationary shortage hold,
request/dispatch non-teleportation, actual delivery readiness, ledger reconciliation,
category compatibility and capture once only. Renderer mode adds the end-to-end
visual capture check. Evidence lives in `artifacts/supply_checks.json`,
`supply_visual.log` and six `supply_*.png` frames. Prior37hierarchy and133rendered
information checks pass with this extension. Developer inspection covers initial
uneven inventory, sharing, hold, road transport, delivery/resume and recovery;
human experience evaluation remains pending.

## T3-INF-002 — Information latency and HQ inquiry

At T=5, a scripted explosion makes reserve soldier P2-B.4 inactive. This is
an information fixture, not a combat system. Local observer P2-B.1 establishes
the explosion, casualty identity/location and observation time, but not the
enemy firing source that the world event privately contains. A partial report
arrives at Platoon T=6, Company T=7, and Operational/HQ T=8. All retain T=5 as
the observation time. The casualty is a reserve member so the previous autonomous
advance/support proof still completes without removing a hierarchy level.

Press B (or click Binocular Inquiry), then click any map coordinate. The query
uses a radius of 54 engine units and only HQ-delivered evidence. Before T=8,
the incident query is unknown; query again after T=8 for the partial history.
Empty locations do not snap to incidents. R reconstructs an established result;
Escape interrupts and resumes. Reconstruction freezes authoritative time and
consumes a separate whitelist of HQ evidence, not the world event. It shows
only the reported location, explosion/casualty, identity and time; no source or
trajectory. Omniscient fixture data is labeled in developer console output,
separate from player inquiry. On-screen receipt diagnostics show echelon timing.

PA-INF-001 through PA-INF-006 remain provisional: 1s hops, HQ query source,
54-unit circular footprint, read-only inquiry, reconstruction pause and one
truthful report. PA-HIER-007 records that leader embodiment remains deferred.
No report loss, contradiction, general recon, general casualties, combat or
complete time controls are implied.

Verification: `check_information.gd` runs 127 model checks; with `-- --visual`
it runs 133 including actual dispatched B/click/R/Escape input and world pause/
resume, using the real renderer. Both passed on Godot4.7.2. All37 hierarchy
checks also passed. Fresh before-report, after-report and reconstruction frames
were personally inspected; early inquiry is unknown while the blast is visible,
the later result retains T=5, and the isolated reconstruction displays only the
partial record. Generated evidence: `artifacts/information_checks.json`,
`information_visual.log`, and `information_*.png`. Human experience evaluation
remains pending. The reconstruction is a minimal static translucent event
depiction, not a full animation/history replay.

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
