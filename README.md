# Trencho v3

Godot 4.7 project. Open `project.godot` and run (F6/F5 from the main scene/project).

For the playable logistics battle, open **operations.tscn** and press **F6**.
See **PLAYER_GUIDE.md** for the controls and five-step supply loop.

## T3-OPS-023 — Playable rear logistics and autonomous battle

The separate operations entry assembles ordinary Scenario/Supply/Rear/Vehicle/
Combat/Information/Artillery/Battle implementations. `operations.gd` authors a
finite scenario and releases Company's existing strategic fire task only after
infantry physically secures Objective A. No player move/fire/target/objective/HQ
command exists in `operations_view.gd`. The default main/proof scenes stay intact.

Starting campaign capability BoltActionAmmoProduction is explicit. Rear starts
Metal4, no bench/stock/job/worker assignment and LOCKED. Main infantry carries9;
one real early contact shot leaves8, then ordinary staging requests8against the
unchanged16round readiness threshold. The scenario opts into contact combat while
holding (default false elsewhere), uses explicit deterministic seed1 and finite
enemy ammunition, and retains actual hit/cadence/LOS rules. Autonomous contact
artillery is disabled for this fixture so the two existing physical mortar shells
remain for the later strategic HQ task. Default artillery behavior is unchanged.

Actual player placement, proximity and labor consume Metal1 and4worldseconds for
8rounds. LOCKED/RESERVE8 keep the sole batch rear-owned; AVAILABLE permits normal
commitment,2second loading,3second inter-map transit, military receiving, truck
loading, legal blockage discovery/replan/detour and physical soldier delivery.
Only carried ammo reaches readiness. Empty-before-delivery recipients then spend
their delivered rounds in ordinary combat. A stalled-member counterexample proves
delivery cannot directly win: infantry must actually complete its mission before
Company releases two normal prep/fire/flight impacts against the primary HQ.
HQ destruction alone ends the battle and freezes world/input mutation.

UI reads the same underlying stock/policy/commitment/shipment/vehicle/readiness
state. Enemy markers come only from copied delivered Company contact records,
explicitly labeled last-known with observation time. No live enemy positions or
hidden sources are displayed. Static HQ locations are the accepted strategic
briefing; enemy integrity is not shown live. Friendly fire-task/projectile feedback
uses friendly mission records. Binocular inquiry retains54radius, delayed HQ
knowledge, provenance and restricted historical reconstruction; reconstruction
pauses the single authoritative clock. Terminal display explains result/freeze.

Inaction for120worldseconds creates no stock/export or readiness shortcut. A full
actual-input run takes about49worldseconds with prompt actions; manual pacing can
extend this into a several-minute evaluation. No global simulation constants were
changed. PA-OPS-001 through003 remain provisional experience assumptions.

Verification: `--headless --path . --script check_operations.gd --log-file artifacts/operations.log`
runs23 checks. Omit headless and append `-- --visual` for37, using actual player
WASD/place/work/authorization/map/inquiry/reconstruction controls. Twelve captures
cover request, early unknown inquiry, empty rear, labor, LOCKED8, authorization,
shipment, truck, reconstruction, delivered readiness, combat and frozen HQ victory.
All pass; all22 prior suites pass (37/127/24/33/21/38/20/30/25/64/39/36/33/33/38/
31/32/42/42/34/31/33). Ammo conservation is checked every simulation tick, including
manufacturing and all friendly/enemy shots. Negative battlefield clicks/hotkeys
leave tactical state untouched. Evidence is in `artifacts/operations_checks.json`,
`operations_visual.log`, `operations_*.png` and `operations_regression_*.log`.

Observed UX risks: a several-stage delivery creates a noticeable passive wait;
the UI exposes custody stages and lets the player observe while waiting. Reserve8
protects the whole first batch, which may initially look like a stalled request.
Stale contact markers intentionally outlive the real guard; their time labels
matter. Worker assignment currently orders one batch and has no player unassign
flow. The one-cycle objective is sufficient here, but these limits need human
evaluation before a broader economy/UI. Engineering completion does not establish
that the logistics agency is fun or clear. Human experience evaluation is pending.
No campaign cards/meta/save-slot UI/new weapons/final art/tutorial/balance/audio
or export verification is claimed.

## T3-RSM-022 — Focused active checkpoint and transactional resume

Open `resume_proof.tscn` and run F6. Explicit SAVE ACTIVE, DESTROY ORIGINAL + LOAD
and RESUME BOTH controls prove one bounded active-state class, identified as
RSM-022-six-actions-v1. This is a separate schema2 entry point; schema1 safe saves
and their active-battle rejection remain unchanged. No general arbitrary-state
save support or migration is claimed.

The fixture starts from the accepted campaign's fresh Battle2 and preserves its
detached progression/archive values. At authored T6.25 (stored exact authoritative
double), six actual systems are unfinished: truck cargo8 still traveling; contact-1
observed at5.5 has not reached Platoon/Company; one shell fired at5.5 is in flight
until7.5; a WOUNDED casualty has original deadline13.5, treatment0.75/2 and Medkit2;
ReinforcedPosition work is0.75/5 with4materials reserved,0consumed/0unreserved;
rear production started5.5, Metal4->3 already charged, output0 and completion9.5.
The local contact uses actual detection/LOS, and the wound uses a real charged
rifle shot with explicit deterministic hit. The shell uses a static Company
briefing at an empty site, not knowledge reconstructed from hidden world truth.

`active_checkpoint.gd` captures a value graph of the supported authored runtime:
logical script/person/squad/vehicle/weapon IDs, mutable script fields, typed vectors,
paths/positions, inventories, jobs/reservations, reports/hop stages/history, weapon
missions and medical state. Weak/shared associations become logical reference
records. Only the fixed compiled fixture script set and matching property/object
sets may reconstruct. A fresh Scenario builds immutable topology and actors with
no simulation ticks; saved values reconnect fresh local objects/weak links. No
saved Object/resource/node address is loaded. Temporary inspection maps release
their object references. Existing Scenario update order and ordered event arrays
preserve same-time execution; report/impact/treatment completions coincide at7.5.

Active doubles use explicit8byte IEEE754 hex values: even full-precision decimal
JSON parsing changed a historical timestamp by one ULP during development. Exact
binary values solve that difference without relaxing logical/time comparisons.
Integers preserve signed64bit text; vector/rectangle historical types retain the
existing value codec. Both RNG seed and stream state reconstruct into new RNGs;
the authored post-checkpoint fixture avoids additional random combat outcomes.
Rear production, artillery mission/shell and wound episode now have stable IDs,
alongside existing report/engineering/vehicle identities.

At T16.25 both branches match the entire encoded mutable graph exactly, including
positions, clock, RNG, all histories and independent progression, with no position
or time tolerance. Truck delivers its8rounds once at about6.467; report receipts
occur6.5/7.5; shell impacts7.5 with one remaining shell; treatment consumes one
Medkit then evacuation completes; engineering finishes10.5 consuming4once; rear
finishes9.5 with Metal3/ammo8. Global ammo27initial-1woundshot+8manufactured=34.
A second save/load at6.75 reaches the same exact result. Untreated reload dies
at original13.5, without resetting its bleed interval. Original resumed-branch
world/casualty are actually destroyed before reconstruction.

Validation bounds active text at4MB and checks schema/fixture/checkpoint,
progression structure, known object/property sets, field types, logical references
and authoritative clock consistency before replacement. Missing state, malformed
text, wrong field types and time mismatch reject without replacing/mutating the
current session. No hostile-file, cryptographic or crash-recovery claim is made.
Cross-property container aliasing in other unproven state classes, new/procedural
actor sets, arbitrary interrupted orders, HELD consumables and schema migration
remain future work. Terminal HQ resume was optional and is not specifically proved.

Verification: `--headless --path . --script check_resume.gd --log-file artifacts/resume.log`
runs33checks; omit headless and append `-- --visual` for36 including actual
save/file-load/resume controls and six inspected captures. All pass; all21 earlier
suites pass (37/127/24/33/21/38/20/30/25/64/39/36/33/33/38/31/32/42/42/34/31).
Evidence: `artifacts/resume_checks.json`, `active_checkpoint_v2.json`,
`active_renderer_v2.json`, `resume_final_semantics_v2.json`, `resume_visual.log`,
`resume_*.png` and `resume_regression_*.log`. PA-RSM-001 through005 are provisional.
Human/player evaluation remains pending; no general active-save or export claim.

## T3-SAV-021 — Explicit safe-checkpoint persistence

Open `save_proof.tscn` and run F6. `checkpoint.gd` serializes only progression at
BETWEEN_BATTLES, CAMPAIGN_ENDED or OUT_OF_CAMPAIGN_META. An ACTIVE battlefield
rejects MID_BATTLE_SAVE_DEFERRED even if a caller supplies a safe label. A HELD
consumable blocks saving with UNSPENT_CONSUMABLE_PERSISTENCE_DEFERRED. No autosave,
mid-battle transfers/orders/timers or physical world persistence is supported.

The explicit schema1 JSON text contains save identity/revision/checkpoint,
meta currency/pool/reward/unlock/results/active-ID/next-ID, campaign identity/status/
index/registry/history/cards/consumed records/capabilities/organization, campaign
eligibility snapshot and completed battle metadata. Archive projection preserves
index/outcome/terminal time/world time/HQ event history; old physical snapshots
(inventory, bodies, vehicles, maps, structures, jobs, rear stock and shipments)
are omitted. Tagged integer/vector/rectangle historical values and full-precision
JSON preserve exact historical types/values, never runtime Object references.

The between-battles fixture prepares the accepted B1 victory transition, commits
survivor/dead/acting records and archive, then discards all runtime projections
before any B2 advancement. After a real file write/read and original-session
destruction, load restores progression only; explicit START FRESH BATTLE 2 creates
a new runtime/local0 from the loaded FIT registry, no dead-leader respawn and no
old physical resources. Archive metadata stays unchanged through advancement.

Successful load validates first and then replaces the session reference, never
merging arrays. Bounded validation checks a2MB text limit, JSON/top-level fields,
schema/checkpoint/progression shapes, known unlock IDs, persistent-person fields,
consumable state and checkpoint/active-campaign consistency. Malformed/missing/
unsupported/invalid structures or unknown type tags reject without session
mutation. This is bounded validation of local proof files, not a migration or
hostile-file security system. Explicit proof files live in ignored `artifacts/`.

Ended loads have no live battle world. Stored completed status, unique source
campaign identity and existing successful-completion reward history prevent
resettlement; saved unlock history/pool/currency preserve the already-spent token.
Repeated loads replace exact values rather than duplicate events/persons/cards.
The saved next-campaign counter generates a distinct later ID. Consumed-card
history survives without physical grant stock or reusable consumables. Loading a
checkpoint replaces progression with that checkpoint; cross-save anti-rollback
economy or external side effects are not implemented.

Verification: `--headless --path . --script check_save.gd --log-file artifacts/save.log`
runs31checks; omit headless and append `-- --visual` for37 including explicit
file/load/start/unlock/invalid-version input and seven inspected captures. All pass;
all20 prior suites37/127/24/33/21/38/20/30/25/64/39/36/33/33/38/31/32/42/42/34 pass.
Evidence: `artifacts/save_checks.json`, `save_between_v1.json`,
`save_completed_v1.json`, `save_unlocked_v1.json`, `save_renderer_v1.json`,
`save_visual.log`, `save_*.png` and `save_regression_*.log`.
PA-SAV-001 through005 remain provisional D-13 decisions. Human evaluation pending.
No active-world resume, save migration, multiple-slot UI, cloud, injury/unspent
consumable persistence, compression/encryption or export verification is claimed.
Later active-battle persistence must define every subsystem's in-progress state
and physical ownership rather than adding runtime references to this format.

## T3-META-020 — Completed campaign reward and persistent unlock eligibility

Open `meta_proof.tscn` and run F6. `meta_session.gd` keeps a value-only `meta`
tree outside campaign data: MetaToken currency0, four initial unlocked IDs
(bolt-ammo/engineering/medical/emergency-shipment), unlock/reward/result histories,
active campaign ID and monotonically distinct campaign IDs. Mortar starts locked.
Runtime campaign/cards/old-campaign references stay outside meta values. Persistence
means across campaign lifecycles in this session; no disk save/load is implemented.

The focused first campaign reaches the accepted real Battle1 victory/transition,
then runs autonomous physical HQ destruction in Battle2. Only final Battle2
friendly victory marks COMPLETED_SUCCESS, campaign_active=false and grants1MetaToken
with one reward event. Result processing is idempotent. ACTIVE blocks meta unlock
and replacement campaigns. Explicit abandon marks ABANDONED, freezes campaign
controller advancement, grants0 and clears shop blocking. Genuine defeat similarly
ends with0 and DEFEAT_REWARD_POLICY_DEFERRED; no defeated continuation is introduced.
A terminal victory already present takes precedence over a stale abandon action.

After the campaign ends, a valid unlock spends1MetaToken and deterministically
unlocks the sole eligible catalog card tech.mortar. No campaign data/world,
capability, shell, mortar or stock is mutated. Insufficient balance and exhausted
eligible pool reject without spending, duplicate IDs or history. The completed
campaign and its Battle1 archive remain unchanged through unlock/new-run actions.

Starting the new campaign creates an independent ID/runtime/progression snapshot
of persistent unlocked eligibility; acquired cards remain empty and MortarSupport
inactive. PA-META-006 explicitly gives this availability fixture one DropToken
and enables a one-candidate Tier2 proof offer for that token. This is not final
Tier2 pricing/offer-count design. Its tech.mortar offer grants no acquisition,
capability or physical output. Existing default CAR/CON fixtures retain their
own deterministic pools and Tier1 behavior; only the meta fixture opts into a
pool override and Tier2 proof access. No third battle is added to the first
campaign. The new run is an availability proof, not a new full campaign UI flow.

PA-META-001 through006 remain provisional. Exact campaign length, defeat rewards,
pricing/weighting and broader progression remain deferred. No performance scoring,
Legendary Soldier meta system, real-money purchase, final shop art/audio,
blacklists, branching, higher-tier economy or cloud/disk persistence is implied.
Future persistence must preserve unique campaign identity, terminal result/reward
idempotence, unlock transaction atomicity and independent campaign pool snapshots.

Verification: `--headless --path . --script check_meta.gd --log-file artifacts/meta.log`
runs34 checks. Omit headless and append `-- --visual` for40 checks, including
actual blocked-unlock, final victory/reward, unlock, new-campaign and Tier2-offer
controls and five inspected screenshots. All pass; all19 prior suites pass
(37/127/24/33/21/38/20/30/25/64/39/36/33/33/38/31/32/42/42). Evidence:
`artifacts/meta_checks.json`, `meta_visual.log`, `meta_*.png` and
`meta_regression_*.log`. Human experience evaluation remains pending; no export
verification is claimed.

## T3-CON-019 — One-time consumable rear-owned windfall

Open `consumable_proof.tscn` and run F6 for the focused five-card pool. The default
four-card CAR proof and its deterministic technology offer remain stable. The
expanded fixture prepends Tier 1 Logistics CONSUMABLE
`cons.ammo_emergency_shipment`, whose explicit RESOURCE_GRANT payload is
BoltActionRifleAmmo8. No display-name parsing drives behavior. Definitions and
fixture pool remain independent of this campaign's acquisition/spending history.

Existing purchase machinery offers shipment/bolt-ammo/engineering, all Tier1.
Selection closes the drop and records one HELD instance, acquired=true,
consumed=false, grant_delivered=false. No ammunition or capability is granted.
Explicit USE validates known/type/acquisition/held state and the canonical payload.
It creates exactly8 ordinary rear-finished-stock rounds, marks CONSUMED/delivered,
removes the usable held instance and records one campaign resolution plus a unique
physical receipt/ledger entry with campaign-consumable source and rear ownership.
Repeated use rejects without stock or history changes; rear receipt identity also
guards duplicate physical delivery. Technology/unknown/unacquired/invalid-payload
uses reject. Acquired IDs/history remain after consumption, excluding reacquisition
even when spent. PA-CON-001 through005 remain provisional proof rules.

The fixture has Metal0, no bench/job/labor and no ammo-production capability.
The windfall needs none of them and changes no production counter/history, stock
authorization policy, commitment or military custody. LOCKED blocks draw over
world time; RESERVE protects its floor. After explicit AVAILABLE authorization,
ordinary commitment,2second loading and3second transit deliver the same physical
rounds to battlefield receiving stock. Grant and production provenance differ;
with a separate active technology/manufacturing fixture, grant8 plus real timed
manufacture8 produce16 without altering the existing job or its Metal input.

No unused-consumable cross-battle policy is invented: the detached reconstruction
probe rejects while a consumable is HELD. Once spent, it preserves historical
consumption, no usable instance and no old physical ammunition. It remains a
detached proof, not an authoritative active-battle transition or save/load.

Verification: `--headless --path . --script check_consumable.gd --log-file artifacts/consumable.log`
runs42 checks; omit headless and append `-- --visual` for49 including actual
purchase/select/use/repeat-use/manufacturing-rejection/reconstruction buttons and
six inspected renderer captures. Both pass. All18 prior suites pass (37/127/24/33/
21/38/20/30/25/64/39/36/33/33/38/31/32/42). Evidence is in
`artifacts/consumable_checks.json`, `consumable_visual.log`, `consumable_*.png` and
`consumable_regression_*.log`. Human experience evaluation remains pending.
Unspent persistence, stacking, multiple copies, personnel/equipment effects,
refunds/discard, meta shop/currency/rewards and final UI/art remain out of scope.
Future save/reward integration must preserve atomic consumption/physical receipt
identity and avoid treating the two provenance records as two stock grants.

## T3-CAR-018 — Campaign card acquisition and physical production

Open `card_proof.tscn` and run that scene (F6) for the protected progression proof.
The default main scene and accepted CAM-017 default fixture remain unchanged.
CAR-018 explicitly starts its campaign without ammo technology, reaches the actual
Battle 1 terminal boundary, and enters fresh Battle 2 with one Drop Token.

`card_progression.gd` defines four stable-ID technology cards and a separate
pre-unlocked availability pool: Tier 1 ammo production/engineering/medical and
Tier 2 mortar. Definitions include tier/category/type/capability. These are fixture
unlocks, not meta-shop purchases. Campaign currency, acquired IDs, closed/open
drops and ordered purchase/acquisition/activation history live as detached values
inside campaign data; pool definitions remain separate and immutable.

Buy spends one token for exactly three deterministic distinct Tier 1 candidates.
Offering grants nothing. Explicitly selecting one offered ID acquires only that
technology, closes the drop and immediately activates its campaign capability.
Unknown/unoffered/closed choices and unfunded purchases reject without mutation.
Owned technologies are excluded from later eligible offers. If fewer than three
eligible Tier 1 cards remain, purchase rejects without spending rather than
inventing duplicate/wrong-tier choices or partial offers. There is no recurring
income or reward flow. PA-CAR-001 through 006 are provisional fixture rules.

Ammo technology binds to the existing rear production gate. Even with an actual
workbench, Metal and nearby Avatar, a pre-card batch rejects MISSING_CAPABILITY.
Acquisition adds no ammunition, workstation, Metal or job. A new valid action
consumes one Metal, performs four world seconds of labor and creates eight rounds.
The other cards carry capability metadata; this slice does not redesign the
existing engineering/medical/mortar fixture mechanics around those capabilities.

The labeled DETACHED NEXT-BATTLE PROBE constructs an independent fresh Battle 3
runtime from a deep campaign-value copy, as permitted by CAR-018. It preserves the
selected card, spent token, capability and drop history while rear stock starts
zero, Metal4 and no workbench/job. It does not transition the authoritative active
Battle 2 or invent another outcome; source campaign/world continue independently.
This is reconstruction evidence, not save/load or an implemented Battle2 victory
transition. Pool and definition accessors return detached diagnostic copies.

Verification: `--headless --path . --script check_cards.gd --log-file artifacts/cards.log`
runs 42 checks. Omit headless and append `-- --visual` for 49 checks, including
actual buy/select/bench/manual-job/reconstruction button input and seven captures.
All pass; all 17 prior focused model suites pass (37/127/24/33/21/38/20/30/25/64/
39/36/33/33/38/31/32). Captures were visually inspected. Evidence:
`artifacts/cards_checks.json`, `cards_visual.log`, `cards_*.png` and
`cards_regression_*.log`. Human experience evaluation is pending. No meta shop,
consumables, rewards, rarity, higher-tier economy, card combinations, final art/UI,
save/load or export verification is implied.

## T3-CAM-017 — Separate campaign identity and battle worlds

`campaign.gd` is a bounded Battle 1 to Battle 2 proof session. Its `data` tree
contains detached campaign values: campaign ID/index/activity, person registry,
organizational history, capabilities and completed battle records. Live and archived
Scenario references stay outside that tree. No save/load system is implied.

Battle 1 uses actual leadership loss, acting succession, rear production,
construction and physical HQ destruction. Only terminal friendly victory permits
the explicit NEXT BATTLE button or N input. PA-CAM-008 confirms victory-only scope;
friendly defeat rejects with CAMPAIGN_DEFEAT_POLICY_DEFERRED. ACTIVE rejects too.
The approved next roster must be FIT; unsupported wounded/stabilized/evacuated
carryover rejects rather than silently healing or inventing a policy.

Battle 2 independently instantiates Sergeant P1-B.1, Corporal P1-A.2, Privates
P1-A.3/P1-A.4 and Platoon Leader P1-PL, preserving IDs, ranks, normal roles,
qualifications and detached personal/appointment/permanent history. Dead P1-A.1
remains historical only. The Sergeant is explicitly the new formal squad leader;
the Corporal's real past acting appointment remains history, with no current
acting appointment or promotion. Morale starts at 100 and suppression at zero.

Each battle has separate HQs, time, people projections, equipment, stocks, vehicles,
infrastructure, bodies, structures, knowledge, workbench, jobs and logistics.
Fresh Battle 2 fixtures are explicit new resources, never inventory copied from
Battle 1. BoltActionAmmoProduction persists as capability only: the empty new rear
still requires workbench placement, Metal, local labor and four world seconds for
one Metal to become eight rear-owned rounds. The archived old runtime is frozen.

Run `--headless --path . --script check_campaign.gd --log-file artifacts/campaign.log`
for 32 model checks. Omit headless and append `-- --visual` for 36 checks including
actual N/Tab/place/manual-production input and seven renderer captures. Both pass;
all 16 prior suites pass (37/127/24/33/21/38/20/30/25/64/39/36/33/33/38/31).
Checks prove active/defeat/nonfit rejection, no simulation objects in campaign
data, distinct runtime instances, fresh custody, historical death/acting continuity,
and unchanged Battle 1 snapshots while Battle 2 advances beyond ten seconds,
damages infrastructure, transfers ammunition and completes new production.
Evidence is in `artifacts/campaign_checks.json`, `campaign_visual.log`, and
`campaign_*.png`. Captures were visually inspected. Human experience evaluation,
campaign defeat progression, injury carryover, longer campaigns, export and
save/load remain unverified or deferred. This is a debug proof, not final UI.

## T3-WAR-016 — Physical HQ destruction and two-sided terminal battle

The optional eighth Scenario fixture flag creates two persistent physical defeat
objects: Friendly-HQ (friendly,100/700) and Enemy-HQ (enemy,850/200), each with stable
ID/ownership/position,56x44geometry, integrity2 and INTACT/DAMAGED/DESTROYED lifecycle.
These are structures, not new immortal commanders or HQ staff people. A qualifying
spatial artillery impact within30units removes one integrity after current occupant
effects and ordinary infrastructure effects resolve. Only a primary HQ reaching0
sets ENDED_FRIENDLY_VICTORY/DEFEAT. Commander loss, Objective A, normal Squad loss,
empty ammunition, rout and ordinary fortification/bridge destruction are nonterminal.

The focused autonomous director receives an explicit static opposing-HQ briefing
(STATIC_HQ_LOCATION), passed through Company fire-mission provenance validation.
No player targeting or binocular truth injection exists. Two accepted mortar
missions use real assigned/active gunner,2physical shells,1second preparation and
2second flight. First impact at aboutT3.017leaves HQ DAMAGED/ACTIVE; after a2second
interval the second mission produces destruction and victory at aboutT8.017.
Mirrored EnemyMortar fixture destroys Friendly-HQ for defeat. Gunner unavailability
prevents fire and result until restored. Empty shells never substitute for defeat.

The destroying impact finishes all person effects, HQ damage/result and its current
mission/impact history before Scenario returns. Later impacts/ticks are blocked.
Terminal result/time are latched once; destroyed HQ identity/geometry/history persist.
Scenario's authoritative entry point freezes movement, firing, suppression/morale,
medicine, vehicles, engineering, rear production/export, recovery and reports.
Direct shot/kill/mission/impact boundaries reject post-terminal mutation; rear avatar
input/production controls also stop. Static rendering/map inspection may continue.
No post-battle results screen, campaign transition or HQ rebuilding is implemented.

`check_battle.gd` verifies actual shell-caused2->1->0, first-hit continuation,
victory/mirrored defeat, gunner requirements, six real nonterminal alternatives,
30unit damage boundary, current-impact occupant ordering, persistent aftermath,
latched result and post-terminal armed-shooter/nonlethal-blast rejection. A busy
fixture terminates with genuine movement, pending vehicle transport, incomplete
production/engineering/treatment, suppression, bleed deadline, recovery and superior
report still in progress; a full detached snapshot stays identical through100later
requested world-seconds. Renderer captures both HQs, first hit/ACTIVE, second shell
in flight, destroyed Enemy-HQ/victory and identical frozen aftermath.
Evidence: `artifacts/battle_checks.json`, `battle.log`, `battle_visual.log`,
`battle_*.png`, `battle_regression_*.log`. PA-WAR001..006 remain provisional.
Only the two-primary-belligerent D-07 subset is resolved. Simultaneous HQ destruction,
multi-sided outcomes/survivor conversion, HQ staff fate and campaign transition are
unresolved. Human evaluation and export verification remain pending.

## T3-MED-015 — Wounding, stabilization and physical evacuation

Persistent people now have FIT/WOUNDED/STABILIZED/DEAD/EVACUATED medical state,
independent of combat-ready `active` and physical battlefield presence. A designated
valid rifle hit in the optional medical fixture creates WOUNDED; all ordinary
non-designated hits retain lethal resolution. Wounded/stabilized people stay alive
and present with their inventories but cannot fire, move normally, command a Squad
or count toward living ammunition readiness. They remain physical rifle/blast
targets; becoming noncombat does not grant invulnerability. DEAD uses the existing
same-person corpse/history/inventory path. EVACUATED remains alive as the same
record with inventory but leaves battlefield representation and creates no corpse.

An unstabilized wound expires after8authoritative world-seconds. A persistent
Medic-01 (MedicQualified true) carries2physical Medkits in personal custody. The
focused wound assigns a direct clear approach to the casualty; the Medic walks at
65units/s and stops within24units. Treatment credits only whole in-range steps and
requires active FIT Medic, qualification and carried Medkit. Missing requirements
pause progress. After2eligible seconds,1Medkit is consumed, casualty becomes
STABILIZED and bleed-out stops. Assignment itself never stabilizes. At the exact
bleed deadline, a still-WOUNDED casualty expires before treatment can reverse death.

Distinct persistent EvacTeam-01 uses the existing recovery-style physical approach
and timed action pattern without corpse looting. It accepts only STABILIZED, walks
at80units/s to24unit pickup range and spends2eligible pickup seconds. Only then does
the same casualty become EVACUATED and leave the map. Team inventory receives no
copy of casualty equipment; no Squad/rear grant occurs. This asset may stop after
one pickup. No hospital transport, triage queue, return-to-duty or ambulance exists.

FIT->WOUNDED applies the existing casualty morale penalty once. Formal-leader wound
adds one leader-unavailability penalty immediately and existing0.5second succession
reacts. Later bleed-out/ordinary lethal hit cannot repeat either morale penalty.
Delayed leadership casualty reports distinguish wounded unavailability from death
instead of calling a living leader deceased. Wound/stabilized/died-from-wounds/
evacuated history is World State evidence, not automatic HQ/binocular knowledge.
Existing scripted death and corpse recovery now also set explicit medical/presence
fields; old inventory/body behavior is retained. Reconstruction pauses the world
and medical clocks together; map switching does not reset deadlines.

`check_medical.gd` proves actual shot wounding, medical/physical/combat distinctions,
personal Medkit consumption, physical treatment/pickup, pause/qualification/supply
failures,8second bleed boundary, stable survival beyond original deadline, preserved
inventory/identity, no corpse for evacuation, corpse for untreated death, leader
succession/morale idempotence, subsequent rifle/blast vulnerability and hidden HQ
knowledge. Renderer captures real wound, Medic approach, treatment, Evac approach,
removal without corpse and separate untreated death/body persistence, with actual
map switches. Evidence: `artifacts/medical_checks.json`, `medical.log`,
`medical_visual.log`, `medical_*.png`, `medical_regression_*.log`.
PA-MED-001..007 remain provisional D-11 choices. Default main does not globally
convert hits to wounds. Human experience evaluation, detailed injuries, enemy care,
medical logistics, field hospitals, return-to-duty, campaign/save-load and export
verification remain outside this focused single-casualty proof.

## T3-BRG-014 — Same-identity bridge reconstruction and route restoration

Bridge-A now supports DESTROYED -> UNDER_RECONSTRUCTION -> INTACT on its existing
infrastructure record and graph edge. Both ROAD_ONLY/TRACKED crossing legality stay
false for any non-INTACT state. Reconstruction requires an active Engineer-qualified
person, actual EngineerToolkit custody,6BuildingMaterial,24unit physical work range
and8eligible world-seconds. Qualification/tool/range/reservation loss pauses labor;
there is no partial connectivity. A dedicated fixture starts8material: free2 plus
reserved6 during work; successful completion leaves free2/reserved0/consumed6.
Toolkit and original Bridge-A identity/geometry remain. Intact or duplicate rebuild
assignments are rejected. No arbitrary bridge placement or hauling is implemented.

A qualifying blast during UNDER_RECONSTRUCTION returns Bridge-A to DESTROYED,
sets its original job to INTERRUPTED and resets progress0. The original6remain
reserved; there is no automatic restart, refund, consumption or duplicate job.
Designer-confirmed PA-BRG-007 permits explicit local fixture resume of the same
job/held reservation. Resume revalidates eligibility, sets UNDER_RECONSTRUCTION
and requires a fresh full8seconds. This is a prototype recovery action, not a
player battlefield control or final rebuilding/cancellation doctrine.

Completion restores original intact route cost and increments infrastructure
revision. Vehicles waiting NO_LEGAL_ROUTE at a safe graph node observe revisions
and retry planning; partial/re-interrupted work still yields no legal crossing.
The focused network retains the tracked bypass while removing the road detour to
prove that the same loaded truck genuinely waits, then plans and physically crosses
the rebuilt bridge before delivery. No fixture path is injected. A vehicle stranded
on destroyed crossing geometry remains outside this safe-node retry rule; rescue
and fall doctrine remain unresolved. Destruction/started/interrupted/resumed/completed
history coexist on Bridge-A without becoming HQ inquiry evidence.

`check_bridge.gd` checks independent requirements, exclusive reservation, physical
approach/pause,7.99vs8second boundary, persistent identity/no duplicate edge, original
cost restoration, waiting-truck revision retry/physical crossing, interrupted labor,
explicit same-job resume and exact material use. Renderer captures waiting truck,
approach/reservation, closed partial work, destructive interruption, explicit resume,
restored crossing, truck physically on Bridge-A and genuine arrival/history.
Evidence: `artifacts/bridge_checks.json`, `bridge.log`, `bridge_visual.log`,
`bridge_*.png`, `bridge_regression_*.log`. PA-BRG-001..007 remain provisional.
Human evaluation, cancellation/refunds, material hauling, arbitrary construction,
bridge weight limits, infantry collapse, final art and save/load remain outside proof.

## T3-ROD-013 — Dynamic road cost, crossing legality and road repair

The optional sixth Scenario fixture flag promotes two existing graph edges into
persistent infrastructure: RoadSegment-A(depot–junction) and Bridge-A(junction–
crossing_exit). Both begin INTACT. One spatial blast within24units of the authored
damage point changes the road to DAMAGED or bridge to DESTROYED, after Soldier
effects, using the existing artillery spatial-impact boundary. No vehicle damage,
general road-tile HP or bridge repair is added. Destroyed bridge geometry/history
remains visible and identifiable, with crossing legality false for both classes.

Current road speed is1.0intact/0.30damaged: the existing truck physically travels
48versus14.4units/s. Tracked vehicles get the same penalty when using that road.
Planner cost is edge length/current speed multiplier (vehicle speed is constant
within each plan). The shared damaged approach remains legal and optimal in this
fixture; the crossing's destruction selects the existing intact-road detour for
ROAD_ONLY and shorter permitted off-road bypass for TRACKED. Faction changes grant
no mobility permissions. Edge diagnostics expose current legality, cost and speed.

Every infrastructure transition increments a revision. An active vehicle compares
its remaining route with current legal/cost-based planning before moving. A stale
route invalidates visibly. From the middle of a still-legal edge, REPLAN_RETURN
physically backtracks to its last safe graph node before the existing BLOCKED /
REPLANNING intervals and new plan; cargo stays onboard. No route array is replaced
by scripted fixture paths, no teleport cuts corners and no early arrival/delivery
is reported. At crossing entry, destruction prevents entry. A vehicle already beyond
the crossing continues legally. If a crossing is destroyed under a vehicle, it
holds NO_LEGAL_ROUTE in place; rescue/fall/vehicle-damage doctrine is deferred.

Engineer road repair uses shared physical-tool/qualification/material/labor checks:
active Engineer qualification, actual EngineerToolkit,2reserved BuildingMaterial,
24unit range and4eligible world-seconds. The dedicated repair stock explicitly
starts4; reservation is free2+reserved2; completion leaves free2/reserved0/consumed2.
Toolkit remains. Restoring the same road to INTACT updates revision and live cost /
speed; the same persistent truck resumes48units/s. Intact road repair is rejected;
destroyed crossing returns REQUIRES_REBUILD. Road/bridge events retain ID, world
time, source/cause and position; no HQ/binocular knowledge is injected.

`check_roads.gd` checks actual same-truck speed before/during/after damage, live plan
costs, route invalidation/backtracking, road-only legality, physical tracked bypass,
per-step displacement, cargo conservation and arrival gating, road repair failures
and exact accounting, intact/entry/mid-crossing/after-crossing destruction behavior,
genuine no-detour failure and persistent history. Renderer mode captures all phases
including actual off-road carrier position. The default integrated battle retains
its previous static-blockage fixture; dynamic infrastructure is opt-in proof state.
Evidence: `artifacts/road_checks.json`, `road.log`, `road_visual.log`, `road_*.png`,
`road_regression_*.log`. PA-ROD001..006 remain provisional. No bridge rebuilding,
stuck randomness, road construction, traffic, vehicle damage or export proof is added.

## T3-DMG-012 — Fortification lifecycle and repair

ReinforcedPosition now retains its identity, position, geometry and history through
INTACT(integrity2), DAMAGED(1), DESTROYED(0). An explicit spatial blast within24units
of its damage point removes one integrity step, once per impact, not per occupant.
No passive degradation/regeneration exists. Foxhole destruction is not included.

Every blast first snapshots current solid obstruction, resolves all occupant
outcomes, then damages structures. Thus an intact wall protects the same impact
that damages it. Later queries derive cover from the current lifecycle: INTACT
provides rifle cover and blast obstruction; DAMAGED provides rifle cover only;
DESTROYED provides neither. Diagnostic flags update with transitions, while actual
combat queries use current state. Rubble remains a persistent identifiable record
and visible debug shape, with no invisible protective geometry.

RepairReinforced targets an existing DAMAGED wall only. It independently requires
an active Engineer-qualified person, actual EngineerToolkit custody,2reserved
BuildingMaterial,24unit physical work range and4eligible world-seconds. It reuses
construction pause/clock semantics, consumes2only on completion, retains the tool,
restores integrity2/INTACT and the same structure's cover. INTACT repair is rejected
as unnecessary; DESTROYED returns REQUIRES_REBUILD. If destruction interrupts a
pending repair, work pauses and its reservation remains held; cancellation/refund
and rebuilding doctrine are outside this task.

The original8material fixture spends4on construction, leaving4for repair. Repair
reservation yields free2+reserved2; completion leaves free2+reserved0 and total
consumed6 (4construction+2repair). No new currency or rear grant is introduced.
Constructed/damaged/repaired/destroyed history records retain structure ID, position,
world time and source/cause. This developer history is not HQ inquiry evidence.
PA-DMG-001..006 remain provisional, including post-occupant damage ordering.

`check_damage.gd` verifies both protections in all states, multi-occupant same-impact
ordering,24unit damage boundary, explicit transitions, no passive changes, repeated
queries, repair eligibility/range/tool/qualification/reservation pauses, full4second
labor, exact consumption, persistent ID/history/rubble, interrupted repair and no HQ
knowledge shortcut. Renderer captures intact cover, first protected impact, damaged
wall's later failed protection, repair travel/reservation/labor, restoration and
destruction aftermath. The intermediate failed-protection impact is30units from the
damage point (outside24) so it can demonstrate lethal exposure while retaining the
damaged target for repair; a separate identical-impact sequence verifies destruction.
Evidence: `artifacts/damage_checks.json`, `damage.log`, `damage_visual.log`,
`damage_*.png` and `damage_regression_*.log`. Human evaluation, save/load and export
verification remain pending; general destruction, debris physics and rebuild are open.

## T3-ENG-011 — Field engineering, tools and Building Material

The optional fifth Scenario fixture flag creates two persistent military people:
Engineer-01 is Engineer-qualified; Rifleman-01 is not. Shovel-01 (BasicShovel)
starts with Rifleman; Toolkit-01 (EngineerToolkit) starts with Engineer. Tool
records have stable identity/category/custodian and derive physical position from
that person (or construction stock). Qualification is a separate person field.
These proof items have no durability/crafting/shared-use/custody-transfer UI.

Autonomous authored assignments send Rifleman to Dig Site A (320,250) for a
BasicFoxhole, and Engineer to Reinforced Site B (650,580) for a reinforced position.
Both walk their own paths at65units/s. Labor requires presence within24units for
the whole credited step, an active constructor, actual required tool custody and
any specialist qualification/reservation. Losing a requirement pauses retained
progress. Labor shares Scenario time and continues across map switches; existing
reconstruction pause freezes it with the rest of the world. Basic digging takes3
eligible seconds, requires a shovel, needs no Engineer qualification/material and
keeps the shovel. Reinforced work requires Engineer qualification plus Toolkit,
4 BuildingMaterial and5 eligible labor seconds, and keeps the reusable Toolkit.

The explicit military construction stock at(200,550) starts with8 BuildingMaterial,
the only construction material currency. Assignment reserves4: free4 + reserved4
=8. Completion consumes the reservation: free4 + reserved0 + consumed4 =8. Ledger
records identify stock/reservation/consumption, amount, world time and job. Reserved
units cannot fund another allocation. There is no cancellation/refund or material
transport system; the task authorizes a stock reservation at assignment.

Completed structures are persistent world records, independent of constructors
and job lifetime. Foxhole has a48x48 protection area and non-solid36x36 geometry;
occupants use existing covered rifle treatment (10% versus40% exposed), with no
LOS or solid-blast obstruction. Reinforced position has an8x56 wall and a36x48
protection area on its east side. It supplies the same rifle cover treatment and
joins the existing artillery blast's solid-obstruction geometry. It does not block
rifle LOS in this low-wall proof. Destruction, repair, general engineering routing,
rear material manufacture and final battlefield construction doctrine remain open.
PA-ENG-001..006 remain provisional. The default integrated battle is unchanged;
the dedicated engineering renderer uses the existing view with the optional fixture.

`check_engineering.gd` verifies each independent requirement, tool loss/inactivity/
range/qualification/reservation pauses, exact labor and material accounting, two
disjoint job reservations, reusable tools, physical departure and persistent world
geometry. Real-shot same-position roll0.2 comparisons kill exposed targets and miss
Foxhole occupants. Equal40unit spatial blasts kill exposed soldiers while a completed
reinforced wall protects another; Foxholes do not stop that blast. Renderer mode
captures travel/reservation, each labor stage, both structures, map-switch continuity,
actual blast comparison and constructors100units away. Evidence is in
`artifacts/engineering_checks.json`, `engineering.log`, `engineering_visual.log`,
`engineering_*.png` and `engineering_regression_*.log`.
Human experience evaluation remains pending; no save/load or export proof is claimed.

## T3-MOR-010 — Squad morale, autonomous routing and rally hold

Every friendly Squad owns morale independently of suppression: initial100,
clamped0–100; STEADY61–100, SHAKEN31–60. A real combat member casualty costs20;
formal Squad Leader death costs an additional20. Acting succession changes neither
penalty nor rank. Repeated casualty calls are idempotent. Suppression crossing4
costs15 once per continuous episode, rearmed only after suppression reaches<=1.
The earlier scripted reserve information incident remains an information fixture,
not a new combat casualty path. Rifle and artillery combat share the casualty path.

At morale<=30, routing latches until safe recovery reaches50, so it stays ROUTING
while recovering through31–49. Available local formal/acting authority selects
west-face outcrop cover (x345, center-y clamped310–405), preserving existing intent.
Individual survivors physically retreat using a small visibility graph around the
single known solid rectangle with10-unit clearance. This also handles retreat from
east of the outcrop; the original forward path remains unchanged. This fixed west
rally is provisional for the accepted eastern contact, not general tactical cover
selection. No authority means the existing leaderless hold; no leader is invented.
Routing blocks forward assignment, supply resumption and attacks. Bodies and their
inventories persist. Higher task records, people and appointments remain unchanged.

Only after physical rally arrival,4world-seconds without incoming fire and
suppression<=1 does the2second recovery interval start. Each interval adds5 up to50;
unsafe time earns no credit. Recovery runs after current-frame combat/artillery,
preventing a gain on a frame that receives fire. At50 the Squad is SHAKEN and
RALLIED_HOLD: no automatic Objective A resumption, perfect restoration or new order.

SQUAD_ROUTING/SQUAD_RALLIED snapshots carry Squad, observation/send time, morale,
state and local formal/acting identities. Existing1second-hop semantics propagate
Squad->Platoon->Company only. Exact morale diagnostics require the explicit developer
fixture flag; HQ/binocular inquiry/reconstruction do not receive these records.
PA-MOR-001..006 remain provisional. Recovery begins with a full2second eligible
interval; no surrender, career judgment, post-rout reassignment or final UI is added.

`check_morale.gd` checks real-shot casualty/episode inputs, ordinary suppression85
and resume, deterministic rout25, acting authority, reverse terrain clearance,
physical retreat and cover LOS, inventory/body persistence, blocked attacks/orders,
unsafe recovery (including fire exactly on the recovery deadline), timed recovery,
stable hold and delayed reports. `-- --visual` captures steady, ordinary suppression,
leader death, acting appointment, second casualty, local rout, delayed report,
retreat, arrival and hold. Evidence: `artifacts/morale_checks.json`, `morale.log`,
`morale_visual.log`, `morale_*.png`; prior focused suites remain available.
Human/player experience evaluation remains pending; no export verification claimed.

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
immediate suppression behavior, distinct from the later T3-MOR-010 morale model.

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
