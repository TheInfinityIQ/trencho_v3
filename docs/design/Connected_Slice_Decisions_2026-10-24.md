# Trencho Representative Connected Slice Decisions

**Date:** 24 October 2026  
**Status:** Active bounded slice decisions  
**Authority:** Trencho Game Designer under Dawson's direction  
**Parent design:** Trencho Game Design Document v1.1, 20 October 2026

## Document status

This is a new dated design addendum for the Representative Connected War-Machine Slice. It does not modify the byte identity of GDD v1.1 and is not a reconstruction, replacement or claimed copy of the unavailable `GDD_Supplement_2026-10-23.md`.

Its purpose is to resolve only the bounded decisions necessary to assemble and evaluate a connected representative Trencho battle.

## CS-01 — Evaluation target

The existing unified rear/battlefield session is an accepted foundation, not the representative game-evaluation target.

Intermediate connected-slice milestones are verified by engineering and reviewed by the designer. Do not require human experience approval after every internal integration step.

The next broad human experience evaluation occurs after the complete representative connected slice is mechanically verified and design-accepted.

## CS-02 — Representative battle scope

The slice contains exactly two primary belligerents in one bounded battlefield scenario.

The player is the logistics authority for one belligerent. The opposing belligerent is autonomous.

Each belligerent has its own protected rear logistics state and its own military supply chain. The enemy rear may be automated and need not be directly visitable or visible to the player.

Networking and two-human multiplayer are outside this slice.

## CS-03 — Player rear operating loop

The slice uses finite scenario-start raw material rather than implementing the unresolved homeland acquisition economy.

The player's representative rear contains:

- raw-material storage,
- the existing compatible ammunition production workstation,
- ammunition stock,
- a dispatch/loading work location,
- military request/status information,
- AVAILABLE / RESERVE N / LOCKED authorization,
- the player avatar,
- Worker-01.

Worker-01 may perform ammunition production or shipment loading, but not both simultaneously.

The player avatar may manually perform either production or loading. Manual and worker labor use the same world clock.

Active jobs complete before a reassignment takes effect. This bounded rule avoids resolving general mid-job cancellation behavior under this slice.

Existing production and loading durations should be retained unless implementation evidence establishes that an existing value cannot be reused.

The resulting player choice is intentionally small but meaningful: allocate labor to produce, allocate labor to dispatch, manually cover one task, or withhold/protect stock through authorization.

This does not resolve final raw-material acquisition, recruitment, training, full facility construction or final rear balance.

## CS-04 — Side-owned physical supply contract

The representative slice uses one logistics contract that can be instantiated separately for each primary belligerent.

Demand, commitment, cargo, staging and completed-request state belong to a specific side. Logistics truth must not be stored in a shared cross-belligerent proof state.

The legacy standalone Supply/Operations constructors and their fixed proof geometry are not product requirements and must not be treated as drop-in sector adapters. Reuse compatible lower-level behavior where useful, but normal-session logistics must operate against the representative sector's actual geography, scale and authoritative movement systems.

Friendly ammunition follows:

`rear uncommitted → rear committed → active loading → military transit → sector entry/transport where represented → Company staging → eligible individual military inventory → expenditure`

A quantity exists in one physical custody state at a time.

Authorization governs new commitments; it does not teleport goods or erase already valid military cargo.

## CS-04A — Demand and shipment lifecycle

A military demand is a bounded stateful request, not a permanent one-shot flag.

A completed/satisfied demand closes. Later legitimate shortage may create a new distinct demand.

Shipment state likewise returns to a condition that permits later independent cargo after prior cargo has completed its custody chain.

The representative slice must support repeated demand/resupply without stale request, allocation, truck or delivered state suppressing subsequent legitimate requests.

Request context presented to the player or command hierarchy must derive from the actual requesting formation and current mission/readiness state rather than hard-coded proof-scene mission strings.

## CS-05 — Enemy physical supply chain

The opposing primary belligerent has its own finite protected-rear resource state.

It must produce compatible ammunition from finite raw input through real timed production and finite labor capacity, then move it through commitment, loading, transit, Company staging, local distribution and actual individual consumption.

Periodic refills, scripted inventory grants and remote replenishment do not satisfy this requirement.

Enemy rear operation may be automated. Its automation obeys the same relevant resource identity, conservation, production-time, loading-work, transit and custody rules used by the player-aligned chain.

For this slice, an outstanding committed shipment may take enemy rear labor priority over beginning another production job. Otherwise the automated rear may produce when it has valid raw input and military demand.

The player's avatar manual labor is unique player agency and does not imply a free additional enemy labor source.

Enemy rear truth is not exposed to the player.

## CS-06 — Representative command hierarchy and message ownership

Each primary belligerent uses:

`Commander → Company → Platoon → Squad Leader → infantry`

Every echelon adds a decision.

Orders, reports and knowledge transfers are owned by a side and have a defined sender and recipient/echelon. Shared proof arrays that implicitly expose one side's messages to unrelated recipients do not satisfy this rule.

For the representative slice:

- Commander establishes or maintains operational intent.
- Company decides commitment/readiness within known resources and information.
- Platoon coordinates at least two subordinate Squads.
- Squad Leaders solve local movement and engagement problems.
- Infantry executes immediate movement and combat actions.

Initial intent and later changes must reach subordinates through the command path rather than being injected directly into a lower echelon.

Consequential contact and ammunition/readiness information must be capable of travelling upward far enough to influence the echelon responsible for the corresponding decision.

Reuse existing accepted communication timing where available. If no accepted timing exists for a required representative transfer, deterministic provisional latency may be used and recorded as provisional. Communication failure, expiry and replacement remain outside this slice.

## CS-07 — Orders, reports and knowledge

Orders and reports are information transfers, not shared omniscient state.

The slice must represent sending and receiving as distinct events with world timestamps.

At minimum, the integrated hierarchy can propagate consequential contact, ammunition/readiness and casualty/objective information.

Command decisions may use only information legitimately available to the deciding echelon.

## CS-08 — Logistics affects command possibilities

Ammunition shortage and resupply are meaningful inputs to autonomous military decisions.

Command may stage, delay commitment, hold, adapt or resume when its known readiness changes, within the responsibilities already defined by the GDD.

Supplying ammunition does not constitute a player order to attack, choose a route, select a target or nominate an individual recipient.

## CS-09 — Sector-native HQ defeat

Each primary belligerent has a real battlefield military HQ distinct from its protected logistics rear.

The representative two-belligerent battle ends immediately when one primary belligerent's battlefield HQ is destroyed, consistent with `WAR-01`.

HQ position, ownership, damage and destruction must be integrated with the representative sector and compatible sector/combat behavior. Legacy fixed-coordinate battle proofs are not authoritative adapters.

Ammunition exhaustion, ordinary-objective loss or commander casualty is not by itself defeat.

The slice does not resolve simultaneous HQ destruction or broader campaign transition behavior under D-07. The bounded representative scenario should avoid the unresolved simultaneous-destruction case; if it cannot, return for a design decision rather than inventing a tie rule.

## CS-10 — Player-facing information

The player may receive exact information about their own rear-owned stock, labor, jobs, authorization and shipment commitment state.

Battlefield military information presented as operational knowledge must retain its appropriate report/provenance boundary.

Enemy protected-rear stock, production state, shipments and internal command truth are not exposed merely because they exist in the simulation.

Engineering/debug truth remains separate from player presentation.

## CS-11 — Slice acceptance

The connected slice is not complete until one normal session demonstrates:

1. meaningful player rear labor/production/authorization choice;
2. real friendly rear-to-person ammunition custody and expenditure;
3. an independent real enemy rear-to-person ammunition chain;
4. integrated Commander/Company/Platoon/Squad Leader/infantry behavior on both sides;
5. upward and downward information flow through that hierarchy;
6. logistics availability materially affecting autonomous military possibilities;
7. one authoritative shared clock across rear, logistics, command and combat;
8. no tactical battlefield orders from the player;
9. valid two-sided battle termination through HQ destruction.

Engineering verifies mechanics and invariants. Designer review verifies design conformity. Human evaluation then addresses whether the connected experience is understandable, compelling and faithful to the logistics-authority fantasy.

## CS-12 — Exclusions

The representative connected slice does not require:

- final raw-material acquisition,
- recruitment/training pipeline,
- campaign progression or deck systems,
- multiple weapon families,
- combined-arms expansion,
- convoy combat/interdiction/capture,
- fuel,
- unified save/load,
- networking,
- final base-building tools,
- final UI,
- final art,
- final LOS/cover overhaul,
- morale expansion,
- final balance.

These may become later design tasks but do not block the connected-slice validation.

## CS-13 — Continuation authority

The authorized connected-slice sequence is:

`T3-LOG-043 → T3-CMD-047 → T3-LOG-044A → T3-LOG-044 → T3-OPP-048 → T3-OUT-050 → T3-SLICE-049`

The previously proposed standalone `T3-REA-046` is removed. Its bounded production-versus-dispatch labor choice is part of T3-LOG-043.

Each task returns engineering evidence for internal designer review. Repairs remain within the same task.

After a task is design-accepted, the coordinator may dispatch the next listed task without requesting a new human experience gate.

Return for an additional design decision only when implementation evidence reveals a semantic contradiction or an unresolved product choice outside this addendum.

This continuation does not grant code push, merge or release authority.

## CS-04B — Sector-native ammunition handoff locality

For the representative connected slice, Company staging has one authoritative physical ammunition issue point in representative-sector geography.

Local person-level handoff requires the recipient's authoritative sector position to be within 4.0 design meters of that issue point.

This distance is expressed directly in sector design meters. It is not derived from, converted from or constrained by legacy standalone Supply proof radii.

The 4.0-meter value is a bounded connected-slice interaction locality, not a final logistics-distribution radius or general battlefield supply doctrine.

Ammunition cannot be remotely transferred from Company staging to personnel outside this locality.

## CS-04C — Slice replenishment target

Final individual ammunition carrying capacity remains unresolved under D-10.

For the representative connected slice only, each person's authored carried ammunition at representative battle initialization is snapshotted as that person's slice replenishment target for that compatible ammunition category.

Rear/military resupply may restore a person toward this target but may not use this target as proof of a final inventory-capacity rule.

A recipient is eligible only when living, friendly, compatible, assigned a positive target, below that target and physically local under CS-04B.

A person authored with zero starting ammunition has a zero target and is not automatically made a recipient solely because they possess a compatible weapon.

The bounded handoff amount is:

min(target deficit, physically local staging stock)

Dead, incompatible, enemy, zero-target and non-local personnel receive nothing.

## CS-08A — Autonomous resupply rendezvous

When normal autonomous movement does not bring legitimately depleted personnel into Company staging locality, do not enlarge the locality or teleport supply to force the proof.

Company command may autonomously initiate a bounded resupply rendezvous when it legitimately knows both that a subordinate has an ammunition/readiness deficit and that compatible stock is physically available at Company staging.

The player does not select the formation, route or recipient.

For the representative slice:

Company selects the subordinate formation requiring resupply using received readiness;

Platoon selects one eligible Squad with the greatest aggregate positive ammunition deficit, using deterministic ID order for ties;

Squad Leader routes that Squad to Company staging through the authoritative sector movement system;

infantry physically moves;

the Squad's previous intent is preserved while resupply is pending;

after legitimate local resupply completion, that preserved intent may resume.

This is autonomous logistics/command behavior, not player tactical control.

No second movement authority, remote refill or teleportation is permitted.

The behavior should use side-owned semantics so an opposing belligerent can later use the same relevant logic.

## CS-13 — Continuation authority amendment

The authorized connected-slice sequence is now:

T3-LOG-043 → T3-CMD-047 → T3-LOG-044A → T3-LOG-044 → T3-OPP-048 → T3-OUT-050 → T3-SLICE-049

T3-LOG-044A was inserted after source evidence established that no accepted sector-native handoff locality existed and normal autonomous behavior did not bring depleted personnel to Company staging.

This added task resolves physical rendezvous only. T3-LOG-044 remains responsible for actual local inventory transfer, repeated demand/resupply cycles and observable combat-endurance consequence.

No intermediate human experience gate is introduced.
