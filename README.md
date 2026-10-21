# Trencho v3

Godot 4.7 project. Open `project.godot` and run (F6/F5 from the main scene/project).

## T3-PER-005 — Aftermath and historical continuity

P2-B.4 begins with three additional explicit fixture rounds. At the existing
T=5 casualty event the same person becomes inactive, with a physical-body flag
and its existing inventory; no duplicate body or equipment pile is created.
The inactive person cannot move or contribute to living readiness. Its body
and three rounds persist through elapsed time, map changes, production and
report propagation. This is in-run persistence, not save/load persistence.

The Recovery Team starts at(650,650). AtT15 (ten seconds after the quiet reserve
site casualty), it dispatches automatically and physically travels at80units/s.
Within24units it starts a two-world-second action; only completion clears the
current body and moves the three rounds to the team's independent inventory.
The inactive person identity remains. The team keeps the items; there is no
automatic rear/global/squad loot. Recovery logs a single custody transaction.

Neither the authoritative historical event nor HQ-established incident is
rewritten. An after-cleanup location query still reports the originalT5event.
Historical reconstruction remains available from that restricted HQ record;
it does not set the current body flag or recreate equipment. Exiting leaves
the location cleaned. No hidden firing source is learned through recovery.

The new global ammunition count includes all people, body/team custody, depot,
truck, enemy container, rear stock and inter-map shipment. Legacy military
supply-chain accounting remains24 plus the separate3-round casualty fixture
=27 globally. Integrated initial8main+3casualty=11; after two rear batches,
global27=rear8+livingmain16+RecoveryTeam3. Commitment remains a subset, not an
extra inventory. Earlier24-round figures refer to the earlier main supply flow.

PA-PER-001..006 remain provisional: three carried rounds, deterministic quiet-site
dispatch,24-unit/2s recovery, items retained by the team, one fixture actor, and
historical reconstruction independent from current remains. No full casualty,
medical, burial, civilian cleanup, salvage economy or item-return system exists.

`check_recovery.gd` verifies persistence, no auto-loot, physical arrival and
duration, exact custody, retained history/timestamps, hidden-source boundaries,
and post-cleanup reconstruction without corpse respawn. Renderer mode adds
actual view switches, rear work, queries and reconstruction; evidence is in
`artifacts/recovery_checks.json`, `recovery_visual.log` and seven recovery PNGs.
Human/player experience evaluation remains pending.

## T3-REA-004 — Integrated protected rear

The normal project now starts in a separate protected rear map. WASD moves the
avatar. Press P then click a valid free position to place one workbench (clear
of people, storage and edges). Walk within60units and press E for one manual
batch. The avatar remains occupied for four world-seconds. Press F to assign
the single persistent Worker-01 to one automatic batch; the worker walks to
the bench and uses the identical recipe/duration. Tab switches maps. Both maps,
the worker, reports, shipments and battlefield movement advance on the one
Scenario clock, regardless of which map is drawn.

Start: Metal4, rear ammo0, Worker-01 unassigned, production capability unlocked.
Recipe: Metal1 -> ammo8 in4s. First manual batch leaves Metal3/ammo8; worker
batch leaves Metal2/ammo16. This explicit one-batch worker work order avoids
silently consuming all available inputs. One producer/job is exclusive; no
worker duplication, cancellation, reassignment or recruitment is implemented.

Policy keys/buttons: 1 AVAILABLE, 2 RESERVE8, 3 LOCKED. Default LOCKED blocks
new military commitments. Under RESERVE8, sixteen on-hand rounds permit exactly
eight committed outbound. Committed ammo remains a subset of rear-owned on-hand
and cannot satisfy another allocation. Later LOCKED or a higher reserve does
not revoke it. A two-world-second loading step precedes departure. At departure:
rear on-hand -8, committed -8, military shipment +8. Three further world-seconds
in an explicit military shipment precede receiving-point arrival. Only then
does the existing physical battlefield truck chain load, travel and deliver to
individuals. Soldiers remain held until actual member inventory reaches16.

The integrated receiving point and enemy capture container start empty; prior
stocked supply/capture behavior remains an explicit legacy regression fixture
(`Scenario.new(false)`). Integrated initial carried8 + produced16 = final rear8
+ carried16 =24. Metal4 becomes Metal2 plus two completed recipes. Commitments
are not added again to the ammo total. All resource histories include ownership
and cause. No unexplained receiving stock or rear-to-soldier teleport exists.

PA-REA-001..009 remain provisional: free placement, proof recipe/duration,
exclusive job, rear ownership until departure, honored commitments,3s transit,
starting resources/person, unlocked capability and battlefield receiving custody.
Additional bounded choices: one explicit automatic worker batch per assignment,
2s loading,60-unit manual interaction, worker approach at90units/s, no cancellation,
and one outbound shipment. These do not settle final automation quotas, logistics
priorities, recruitment, costs or broader D-01/D-06 semantics.

`check_rear.gd` checks placement, exclusive labor, inputs/capability, exact job
timing, locked/reserve/available policies, commitment/post-policy accounting,
departure, transit deadlines, receiving custody and the complete physical chain.
The renderer mode dispatches WASD/P/click/E/F/Tab/2/3 input, verifies worker clock
continuity across views, checks all major export stages and waits for autonomous
objective completion. Evidence is in `artifacts/rear_checks.json`, `rear_visual.log`
and nine `rear_*.png` frames. Human experience evaluation remains pending.

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
