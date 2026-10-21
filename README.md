# Trencho v3

Godot 4.7 project. Open `project.godot` and run (F6/F5 from the main scene/project).

## T3-CMD-009 — Embodied leaders and acting command

Every friendly squad references its existing .1 person as formal SERGEANT/SquadLeader
and its .2 person as qualified CORPORAL/AssistantSquadLeader. Other members remain
unqualified PRIVATE/Rifleman. Rank, normal role, rifle proficiency, command
qualification and acting appointment are distinct data. Local route decisions
identify the commanding person. Authority requires a live formal/acting leader;
it is not an immortal hidden squad token. Sixteen squad people remain sixteen.
Two additional unique LIEUTENANT/PlatoonLeader people physically accompany their
platoons, follow nearby troop movement with independent paths/speed, and carry
their own inventories. They are visible and can become ordinary casualties.
Company/Operational command remains the accepted logical HQ representation.

A formal/acting leader casualty is immediately recognized from the real inactive
person. A0.5world-second disruption freezes squad maneuver without discarding
the existing paths/intent. Eligible local members must be alive, squad members,
command-qualified, Corporal-or-higher and free of incompatible command roles.
Highest rank wins, then stable person-ID. The selected person receives an acting
appointment; formal rank and normal role remain unchanged. Existing intent and
local execution continue without rewriting higher-echelon tasks. Pending supply
readiness/cover decisions wait for available field authority.

If nobody qualifies, the squad remains LEADERLESS_HOLD, retains its intent and
people, and initiates no new maneuver. No replacement or promotion is invented.
Body/inventory/history stay with the dead leader; there is no equipment inheritance.
Leaderless doctrine beyond stationary hold remains unresolved. The enemy defensive
squad remains its previously bounded stationary combat fixture; this task embodies
and governs friendly field authority only.

After the disruption outcome is known, a LEADER_CASUALTY report carries deceased
leader ID, squad, original observation time, acting replacement (or empty), and
send time. It relays Squad->Platoon->Company at1s per hop. A T13casualty appoints
locally atT13.5, reaches Platoon14.5 and Company15.5. Local appointment requires
no superior approval. Higher-command knowledge records do not update from the
person object. Platoon locomotion follows nearby physical troop movement and
does not read acting-appointment metadata as a command-knowledge shortcut.

PA-CMD-001..006 remain provisional: eligibility,0.5s disruption, no new maneuver,
leaderless hold, rank/ID tie order and local acting authority. Additional fixtures
are .1/.2 role assignment, the small rank catalog and platoon follow distance45
(speed47units/s). No permanent promotion, platoon/company/operational succession,
training, morale/career consequences or player commander replacement is added.
This closes PA-HIER-007 for friendly squad/platoon embodiment only.

`check_command.gd` uses one controlled real rifle hit during an active mission,
then isolates further automatic combat to inspect succession. It checks unique
people, rank/qualification/role eligibility, exact disruption, retained mission,
local authority before delayed reports, equipment retention, physical platoon
proximity/navigation, tie handling and the no-successor failure case. Renderer
mode separately shows formal leader, actual death, disruption, corporal acting,
higher report, same-mission completion and leaderless hold. Evidence is in
`artifacts/command_checks.json`, `command_visual.log`, six command PNGs and eight
regression logs. Human experience evaluation remains pending.

## T3-ART-008 — Knowledge-bound indirect fire

The actual main scenario now also enables the fourth Scenario option, artillery.
Mortar-01 is static at(850,650), owns two military MortarShell units, and references
persistent Gunner-01. The active gunner must be assigned to that exact equipment.
No shell production/resupply, targeting control or physical projectile is added.

The first valid local P1-A detection creates one ENEMY_POSITION_OBSERVED record
with observer, coordinate and time. The existing Information layer relays it
Squad->Platoon->Company with1s hops; this contact route stops before HQ. Company
snapshot data is a whitelist. Fire control receives only that delivered snapshot,
stores the reported coordinate without any live enemy reference, prepares1s,
spends one shell and schedules impact2s after actual firing. One autonomous mission
is issued. Gunner unavailability or zero shells prevents fire/expenditure.

Impact resolution is a separate geometry call using current individual actors.
Within45units, an exposed soldier dies. Within90 but outside45, an exposed survivor
adds2 squad suppression. Intervening solid rock/bunker/wall prevents lethal effect
and adds at most1. Outside90 is unaffected. Corpses retain their own inventory and
get the existing persistent casualty history. No organizational blanket damage,
cover destruction, HQ history injection or live aim correction occurs. Impact
history retains weapon, coordinate, time, source report and individual effects.

The artillery fixture adds a small solid wall and separates defender positions:
an exposed target at the reported(790,420), exposed squadmate25units away, protected
squadmate40.31units away, and outer squadmate68.01units away. The artillery-enabled
friendly rifle RNG seed is explicitly4 to keep comparison actors alive until the
blast; the independently accepted rifle fixture stays13. This is a reproducible
proof fixture, not accuracy balancing. Main impact produces two exposed deaths and
two protected survivors, followed by ordinary infantry continuation. Squads now own
suppression/decay fields; friendly blast inputs use the same local tactical response
as rifle suppression. Stationary defender suppression is recorded and decays.

PA-ART-001..007 remain provisional: Company control,1s preparation,2s abstract
flight,45/90 geometry, first suitable report, two starting shells and one gunner.
Added choices are one contact observation, the comparison positions/wall and the
scoped RNG seed. No complete artillery organization, spotting doctrine, dispersion,
friendly-fire doctrine, ballistics, resupply or wound model is implied.

`check_artillery.gd` verifies relay deadlines, no pre-Company mission, copied report
provenance, an enemy moved to(900,600) while aim/impact stay(790,420), operator
dependency, separate shell custody, preparation/flight deadlines, exact radius
boundaries, same-Squad geometry, suppression, body/equipment persistence and hidden
HQ truth. World-time comparisons use1e-6 tolerance around accumulated floating
clock deadlines. Renderer mode runs actual rear production, road vehicles, rifle
contact, delayed report, Company mission, firing, blast and autonomous continuation.
Evidence: `artifacts/artillery_checks.json`, `artillery_visual.log`, five artillery
PNGs and seven regression logs. Human experience evaluation remains pending.

## T3-VEH-007 — Vehicle identity, drivers and legal routes

The actual main scenario enables `Scenario.new(true,true,true)`; the third option
promotes the existing military supply truck into a persistent Vehicle with ID,
position, cargo, mobility, route state and a reference to persistent Driver-01.
TrackedCarrier-01 has separate state/cargo and Driver-02. Drivers occupy their
vehicles; they are not duplicated as walking squad members. Movement requires
an active driver assigned to that exact vehicle. Cargo remains on a driverless
vehicle and no arrival/delivery is reported.

An explicit small weighted graph describes ROAD and OFFROAD edges. Road corridors
have16-unit half-width (32 total). Both vehicles first evaluate the short road;
at the junction they encounter the static blocked crossing and stop. One second
BLOCKED, then one second REPLANNING makes failure/recovery visible. Only then is
the blocked edge excluded. ROAD_ONLY replans via the longer south/west road;
TRACKED can choose the designated passable off-road bypass. No route teleport
or faction exception exists. With no alternate road, the truck remains failed
with its cargo instead of borrowing tracked permissions.

The truck moves at48units/s, tracked carrier at56. In the military-stocked proof,
both dispatch when the eight-round shipment loads at~T6.77. The crossing blocks
them aroundT9.3; tracked reaches(350,200) at~T15.57, truck at~T19.28. Only physical
truck arrival plus ARRIVED route state permits the existing70-unit soldier transfer.
The tracked cargo remains independent and empty. Infantry is not road-restricted.

PA-VEH-001..006 remain provisional: occupied-driver embodiment, waypoint graph,
explicit road tolerance, one static blockage, unarmed tracked comparator and
one automatic legal replan. Added fixture choices are1s blocked +1s replanning,
48/56 speeds, shared departure and this compact authored network. No traffic,
vehicle combat/fuel/damage, driver replacement, road construction or dynamic
bridge destruction is implemented. Vehicle cargo workflow and route states remain
distinct; developer logs expose driver, classification, position, path, destination,
world-diagnostic route legality, failure and cargo.

`check_vehicles.gd` checks independent entities/inventories, driver identity and
availability, continuous legal-position sampling, primary failure, distinct legal
replans, no early arrival/cargo use, unavailable-driver/unassigned-driver cases,
no-road failure, faction independence, infantry movement and full rear/combat
integration. Renderer mode isolates the accepted military-stocked shipment to
inspect primary travel, blockage, replanning, road versus off-road and delivery.
Evidence: `artifacts/vehicle_checks.json`, `vehicle_visual.log`, five vehicle PNGs
and six `vehicle_regression_*.log` files. Human evaluation remains pending.

## T3-COM-006 — Local infantry contact

The normal integrated rear-production scenario now includes a four-person enemy
rifle defense. `Scenario.new(with_rear, with_combat)` keeps prior proofs explicitly
selectable with combat disabled. The actual main view enables both. Enemy members
start with two rounds each (eight explicit fixture rounds), behind spatial low
sandbag cover with a solid bunker nearby. The outcrop and bunker block LOS;
low sandbags reduce hit chance but do not provide complete visual occlusion.

Each individual detects opposing living targets within260units and unobstructed
LOS, keeps its own detected IDs and selects the nearest visible target. Shot-time
LOS is revalidated. A compatible rifle shot consumes one round from that shooter,
at most once per world-second. There are no projectile entities. Hit resolution
uses40% exposed/10% covered probability; low cover must intersect the line to a
target within80units of it. Separate fixed RNG seeds6(enemy) and13(friendly)
make this proof reproducible, including four initial enemy misses.

Each valid incoming shot adds one squad suppression, even on a miss. At4,
P1-A locally abandons exposed forward movement and selects a route north then
west around the outcrop. All four friendly soldiers are alive at this transition.
They reach/hold behind the solid rock. Without incoming fire, suppression loses
one point per2seconds; after reaching at most1 and holding at least1second,
the squad replans its own route toward the unchanged Objective A. No new
Operational/Company/Platoon/player tactical destination is required. This is
suppression behavior, not a morale model.

Successful hits use the explicitly temporary alive->dead subset. The same person
holds the body flag and remaining inventory, and a detached combat-world historical
event records the outcome. Nothing is automatically looted. Existing recovery can
accept a combat body without initializing new fixture ammo. Main-script combat
bodies persist; generalized body collection is not implemented. Combat truth and
local detections do not enter the existing HQ inquiry without reporting; no broader
combat-report vocabulary is introduced in this proof.

The bounded encounter ends when defenders have no living riflemen with ammunition;
empty rifles count as not combat-capable for this proof. Surviving unarmed enemies
are not deleted, surrendered or routed. No melee is modeled. Firing then stops and
surviving P1-A personnel continue the original objective when suppression allows.
The proof requires no second in-fight supply request. The16-round threshold is
initial supply readiness, not a perpetual requirement while actually firing.

Global inventory + actual shot count reconciles initialization + production.
Legacy combat fixture: initial35=prior27+enemy8; final22physical +13expended=35.
Normal integrated flow: initial19=main8+casualty3+enemy8, plus16produced=35.
All casualty inventories remain included until explicitly recovered.

PA-COM-001..007 remain provisional: detection/cadence/hit fixtures, suppression,
safe threshold, death-only subset and limited ending. Additional bounded choices
are the finite2rounds/enemy, nearest-visible target selection, explicit seeds,
80unit cover relevance, west-outcrop local response and1s cover hold. They do not
define final tactics, balance, surrender, wounds, doctrine or difficulty.

`check_combat.gd` validates range/LOS rejection, stale-target revalidation, cadence,
individual expenditure, empty rifle, covered/exposed outcomes, casualty custody,
generic recovery, suppression from misses, local adaptation, decay, reproducible
full encounter, continuous obstacle clearance, unchanged higher intent and hidden
HQ combat truth. Renderer mode performs actual manual/worker production controls,
export, supply and contact, then captures first fire, suppression, unknown inquiry,
cover hold, resumption and objective completion. Evidence: `artifacts/combat_checks.json`,
`combat_visual.log`, `combat_*.png`; prior proof regressions remain available.
Human experience evaluation and final combat tuning remain pending.

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
