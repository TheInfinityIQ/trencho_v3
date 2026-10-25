Trencho Playable Version 0
Rear Foundation 02 — Workshop Construction, Production & Dispatch Staging

Date: 24 October 2026
Status: Design complete for implementation handoff
Authority: Trencho Game Designer under Dawson's direction
Dependencies: Accepted PV0 Rear Foundation 01 / T3-PV0-REA-051
Parent design: GDD v1.1 and current Playable Version 0 design history

1. Player outcome

The player can turn physically stored raw materials into a functioning production operation.

The playable chain is:

stored raw resources → workshop blueprint → construction materials → player construction work → completed workshop → production instruction → workshop input → player/Worker production → physical finished ammunition crate → Dispatch Area

Nothing in this chain is an abstract global-resource conversion.

The player should be able to see where materials are, why work is waiting, who is performing the work, what has been produced, and why production has stopped.

2. Scope

This package adds:

Blueprints Menu;

one buildable Ammunition Workshop;

physical blueprint material requirements;

manual workshop construction;

Workshop Duty;

manual workshop production;

automated workshop production;

Rifle Ammunition recipe;

Build Once;

Build Once Per Shipment;

workshop input/output positions;

Dispatch Area;

Hauler support for construction, workshop inputs and completed outputs.

This package does not send anything to HQ yet.

Dispatch Area is physical outbound staging only.

3. Blueprint Menu

The player receives a Blueprints Menu.

For this capability it contains one buildable structure:

Ammunition Workshop

Selecting it enters workshop placement mode.

The proposed workshop:

follows the mouse;

snaps to the logistics placement grid;

appears as an opaque-blue blueprint;

visibly shows its reserved operator position.

For PV0 the workshop has one fixed orientation.

Rotation is not yet a player control.

4. Workshop placement requirements

A blueprint is valid only if:

its physical footprint is on buildable logistics ground;

the footprint is not occupied by another structure, blueprint or crate;

its reserved operator position is free and reachable;

its required input and output interaction positions are usable;

it does not overlap Deliverables, Storage, Barracks or Dispatch zoning;

it does not obstruct the incoming logistics access.

A person merely walking through a prospective location may temporarily prevent placement while physically occupying it.

Invalid placement provides clear world feedback and does not place a partial blueprint.

The player must deliberately Clear Zone before converting zoned ground into workshop space.

5. Ammunition Workshop construction cost

PV0 construction cost:

4 Wood

2 Metal

This is a provisional playable-version value.

The accepted first shipment of 12 Wood / 3 Metal therefore contains enough material to establish one workshop while leaving raw material for continued play.

6. Blueprint material state

After placement, the workshop exists as a blueprint with visible requirements:

Wood 0 / 4

Metal 0 / 2

Construction 0 / 6 seconds

Materials delivered to a blueprint remain physically committed to that blueprint.

They are no longer Storage stock and cannot simultaneously satisfy another request.

The blueprint visibly communicates delivered versus missing materials.

7. Delivering construction material manually

The player may carry a compatible raw-resource crate to the blueprint.

The blueprint accepts only the quantity it still requires.

Example:

Blueprint requires Wood 4.

Player carries Wood 10.

After delivery:

blueprint has Wood 4/4;

player still carries Wood 6.

The excess does not disappear and is not committed.

Wrong resource types are refused.

8. Hauler construction-material work

A blueprint with missing construction material creates a valid rear logistics job.

A Hauler may take the needed resource from Storage and physically deliver it.

The Hauler may carry a crate containing more than the requirement.

At the blueprint:

only the required quantity transfers into blueprint custody;

any physical remainder stays with the Hauler;

the Hauler returns that remainder to valid Storage before accepting unrelated work.

The worker does not discard or invisibly split away excess material.

9. Construction work

Construction begins only after all required Wood and Metal have been delivered.

Construction requires:

6 world seconds of active work

For this capability construction work is performed by the player.

Automated construction workers are not yet introduced.

The player stands at the blueprint's reserved operator position and holds E.

While E is held and the player remains in the valid position:

construction progress advances on the shared world clock.

If the player stops working or moves away:

progress pauses;

progress does not reset.

Pause freezes construction.

Accepted time acceleration affects construction consistently with world time.

10. Construction completion

At 6 completed world seconds:

the committed 4 Wood and 2 Metal are consumed;

the opaque-blue blueprint becomes a completed Ammunition Workshop;

construction progress disappears;

the reserved operator position remains the workshop's working position.

No additional resource is created during construction.

11. Blueprint cancellation

An incomplete blueprint may be cancelled through its inspection interaction.

If no material has been delivered, it is simply removed.

If material has been delivered:

all staged material is released back into physical raw-resource crates at the cleared blueprint site;

quantities remain exact;

those crates become Unstored and are eligible for Hauling.

Partial construction progress is lost.

No delivered material is destroyed because a blueprint is cancelled.

Cancellation is unavailable only if the blueprint site cannot physically contain the released crates; the player must clear the obstruction first.

12. Blueprint operator position blocked

The reserved construction/operator position may not be used as crate storage or another permanent zone position.

If it becomes physically inaccessible:

construction cannot progress;

the blueprint reports Operator Position Blocked.

Once access is restored, construction can resume from existing progress.

13. Completed workshop physical positions

The Ammunition Workshop has three player-readable functional locations:

Operator position

Input position

Output position

The operator position is where the player or Workshop Duty worker performs work.

The input position holds one compatible physical Metal crate.

The output position holds one finished ammunition crate.

These positions remain visibly associated with the workshop.

14. Workshop inspection

At a completed workshop:

F opens the workshop's compact management interface;

E performs manual work while the player is at the operator position and valid work exists.

The workshop interface shows:

current production instruction;

scheduling mode;

current input state;

current job state;

work progress;

output state;

reason the workshop is waiting, when applicable.

It is not a general logistics dashboard.

15. Initial production recipe

The first playable production recipe is:

Rifle Ammunition

Input:

1 Metal

Output:

1 Rifle Ammunition Crate containing 8 rifle rounds

Work required:

4 world seconds

This preserves the already established representative production conversion while making both the input and output physical in PV0.

16. Finished ammunition crate

A Rifle Ammunition Crate is a physical finished good.

It contains exactly:

8 rifle rounds

For this playable version ammunition crates do not merge with one another.

Each crate remains a distinct outbound logistics package.

The crate visibly identifies:

Rifle Ammunition;

quantity 8.

It is not raw Storage stock.

17. Workshop input

The workshop input position accepts:

Metal only

One Metal crate may occupy the input position.

That crate may contain more than one Metal.

Each production job consumes one unit.

Example:

Input crate = Metal 3.

After one completed Rifle Ammunition job:

input crate = Metal 2;

one Ammo Crate 8 exists at output.

The remaining Metal stays physically at workshop input.

18. Delivering production input manually

The player may carry Metal from Storage or loose ground to the workshop input.

If an existing input Metal crate has room under the raw-crate stack rule, compatible quantities may merge up to 10.

If the input position cannot accept the carried material, placement is refused and nothing changes.

19. Hauler production-input work

A pending workshop job that lacks Metal creates a valid Hauling request.

A Hauler may physically move Metal from Storage to the workshop input.

As with construction delivery, excess carried Metal remains physical and must be returned/stored if the workshop cannot accept all of it.

Workshop Duty workers do not fetch raw ingredients.

Material movement remains Hauling work.

20. Workshop output position

A production job may begin only when the workshop output position is available for its eventual finished crate.

The output position is reserved for workshop output and does not accept unrelated crates.

When production finishes:

one Ammo Crate 8 appears there;

that crate physically occupies the output position;

another production job cannot begin until that output has been removed.

This makes outbound congestion visible.

21. Momentary output obstruction

People may cross the workshop area, but the output position is not an idle/work destination.

If a person momentarily occupies the output position when work would complete:

production work reaches its completed state;

final output placement waits until the position clears;

no second job begins;

no duplicate output is created.

22. Production job input commitment

When active production work begins:

exactly 1 Metal leaves the workshop input crate;

that Metal becomes committed to the current job.

It is not available to another job.

If work pauses, the committed Metal stays with that paused job.

The Metal is permanently consumed only when the job completes.

23. Started jobs are not silently cancelled

Once active work has begun on a production job:

changing the recipe instruction does not erase the current job;

changing a worker's duty does not erase the current job;

stopping manual work does not erase the current job.

The current job remains paused or continues to completion as appropriate.

Instruction changes govern what happens after the active job completes.

This avoids ambiguous resource cancellation during PV0.

24. Manual workshop work

If valid production work exists, the player may stand at the operator position and hold E.

Progress advances while:

the player remains in position;

E remains held;

the game is not paused.

Releasing E pauses the job.

Progress remains at the workshop.

The player can later resume.

A Workshop Duty worker may also resume that same paused job.

25. Single operator

Only one operator contributes work at a time.

Player and Worker labor do not stack to double production speed.

If a Workshop Duty worker is actively operating the workshop, attempting manual work informs the player:

Workshop already staffed.

26. Workshop Duty

The Tasks tab gains:

Workshop Duty

A person may be:

Unassigned;

Hauling;

Workshop Duty.

These are mutually exclusive current duties.

A person does not perform Hauling and Workshop Duty simultaneously.

27. Workshop Duty information

A Workshop Duty worker may know:

locations of completed workshops;

whether a workshop has a pending/in-progress job;

whether required input is physically present;

whether output space is available;

whether the operator position is reachable;

progress of the workshop job they are operating.

They do not make ordering, military or battlefield decisions.

28. Workshop Duty behavior

A Workshop Duty worker seeks valid production work.

A workshop is ready for operation when:

it has a pending or paused production job;

required Metal has been staged or committed;

its output position can accept the result;

the operator position is reachable;

no other operator is actively working there.

The worker travels physically to the operator position and performs the job.

After completion, the worker may seek another ready workshop.

The worker does not move finished output.

29. Workshop choice

If multiple workshops are ready:

the worker chooses the nearest reachable ready workshop.

Equivalent choices may use any stable tie resolution.

The player-facing requirement is simply that workers do not ignore a closer valid job for an unexplained farther one.

30. Workshop Duty reassignment

If a person is reassigned away from Workshop Duty before beginning work:

they stop seeking workshop jobs.

If reassigned while actively operating a job:

they finish that current active job;

then the new duty takes effect.

This follows the established PV0 rule that active work is not abandoned mid-action by a duty toggle.

31. Workshop worker blocked

If the selected workshop's operator position becomes unreachable before the worker begins:

the worker re-evaluates other ready workshops.

If none is reachable:

status:

Blocked — No Reachable Workshop

If the route later becomes available, the worker automatically re-evaluates.

32. Player/worker handoff

A manually started but paused production job may be completed by a Workshop Duty worker.

A worker-started job that is no longer being actively staffed may later be completed manually.

The job belongs to the workshop, not permanently to the first operator.

33. Build Once

Selecting Build Once creates one pending Rifle Ammunition production job immediately.

If Metal is unavailable:

status:

Waiting for Metal

If output is blocked:

status:

Output Blocked

If no operator is working:

status:

Ready for Work

After one successful completion:

status:

Completed

It does not automatically create another job.

The player may choose Build Once again to create another.

34. Build Once Per Shipment

Selecting Build Once Per Shipment arms the workshop for future incoming shipments.

It is not retroactive.

The current already-arrived shipment does not create a job when the mode is first selected.

A trigger occurs when a future non-empty incoming logistics truck physically arrives at the Deliverables Area.

At that moment:

the workshop gains one pending Rifle Ammunition job if it does not already have a pending/in-progress recurring job.

An empty-order cycle does not trigger production because no shipment arrived.

A truck containing only people still counts as a shipment.

A debug due-now shipment counts if the truck physically performs the normal arrival.

35. No recurring backlog

Build Once Per Shipment does not accumulate multiple hidden jobs.

If another shipment arrives while the previous recurring job is still pending or in progress:

no second job is added;

the workshop reports:

Shipment cycle skipped — previous job incomplete

When the existing job eventually completes, the workshop returns to:

Armed — Waiting for Next Shipment

This is a provisional PV0 scheduling rule.

36. Dispatch Area

The Zones Menu gains:

Dispatch Area

Dispatch represents finished military goods waiting for a future outbound shipment.

For this package:

Dispatch accepts Rifle Ammunition Crates;

it does not accept Wood, Metal or Cloth;

it does not yet load trucks;

it does not yet send personnel.

Each Dispatch tile can hold:

1 finished ammunition crate

Dispatch crates do not merge.

37. Dispatch placement

Dispatch may be drawn as one or more player-created areas.

For this package it does not require road adjacency.

Outbound vehicle-access requirements will be defined by the next PV0 military-export package.

The player therefore may reorganize Dispatch now without silently committing future truck-routing rules.

38. Manual finished-goods handling

The player may take an Ammo Crate from a workshop output position and:

place it into an empty Dispatch tile;

place it on ordinary valid ground.

If placed on ordinary ground it becomes:

Finished Goods — Unstaged

It remains physical.

A Hauler may subsequently move it to Dispatch.

Raw Storage refuses ammunition crates.

Feedback:

Finished goods belong in Dispatch.

39. Hauler finished-output work

A Hauler may physically move:

an Ammo Crate from workshop output;

a loose Unstaged Ammo Crate;

to an available Dispatch tile.

No remote inventory transfer occurs.

If no Dispatch capacity exists, the Hauler does not pick up a finished crate merely to become stuck.

40. Dispatch full

If every Dispatch tile is occupied:

completed output remains at the workshop output position;

the workshop becomes Output Blocked;

another job cannot begin.

Player recovery:

add Dispatch space;

manually move a finished crate elsewhere;

later outbound shipment removes staged crates.

When valid Dispatch space becomes available, Haulers automatically reconsider blocked finished goods.

41. Hauler Decision Graph v1.1

This replaces Hauler Decision Graph v1.0 wherever new workshop/Dispatch work exists.

Assigned to Hauling?

→ NO
 Do not accept hauling work.

→ YES

Currently carrying a crate?

→ YES
 Complete/retarget/recover the physical carried crate according to the existing custody rules before taking another job.

→ NO

Evaluate in this order:

Active incoming truck cargo

if a valid Storage destination exists, unload it.

Delivered raw resources

move Deliverables raw crates into Storage.

Completed workshop output

if Dispatch capacity exists, move Ammo Crate to Dispatch.

Blueprint material request

move required Wood/Metal from Storage to a workshop blueprint.

Workshop input request

move Metal from Storage to a workshop input position.

Loose finished goods

move Unstaged Ammo Crates to Dispatch.

Other loose raw resources

move Wood/Metal/Cloth to Storage.

No valid work

idle according to existing PV0 behavior.

Hauler must not

operate workshops;

construct workshops;

create production instructions;

consume construction resources themselves;

place raw resources into Dispatch;

place finished ammunition into raw Storage;

move unavailable/duplicated resources;

perform invisible transfers.

42. Workshop Duty Decision Graph v1.0

Assigned Workshop Duty?

→ NO
 Do not seek workshop work.

→ YES

Currently actively operating a job?

→ YES
 Continue current active job to completion.
 If reassignment is queued, apply it after completion.

→ NO

Paused active job exists at a reachable workshop?

→ YES
 Resume an eligible nearest paused job.

→ NO

Ready pending workshop exists?

→ YES
 Move physically to nearest reachable operator position.
 If still valid on arrival → work.

→ NO

Determine why no work is valid:

recipe waiting for Metal → do not fetch Metal; idle/wait;

output blocked → do not move output; idle/wait;

operator position blocked → consider another workshop;

no production instruction → idle.

Worker re-evaluates when relevant world state changes.

43. Player-facing workshop statuses

A workshop may visibly report:

No Production Instruction

Armed — Waiting for Next Shipment

Waiting for Metal

Ready for Work

Worker En Route

Working

Paused

Output Blocked

Shipment Cycle Skipped

Completed

The player should not need a debug screen to understand why production is inactive.

44. Player-facing alerts

Required actionable conditions:

Blueprint Missing Materials

At least one placed blueprint is waiting for Wood/Metal.

Blueprint Operator Blocked

A fully supplied blueprint cannot be worked because its operator position is inaccessible.

Workshop Waiting for Metal

A pending recipe has no usable input.

Workshop Output Blocked

Finished output is preventing further production.

Dispatch Full

Finished goods exist but no Dispatch tile can accept them.

Alerts automatically clear when the underlying condition resolves.

45. Construction/production edge cases
Blueprint placed with no materials

It remains waiting indefinitely.

Required material disappears from Storage before pickup

Hauler abandons that candidate and re-evaluates. Blueprint remains missing material.

Player takes material a Hauler was targeting

No duplicate reservation remains.

Blueprint cancelled with staged materials

Exact staged material returns physically as loose raw-resource crates.

Construction paused

Progress persists.

Pause during construction

No progress.

Time acceleration

Construction and production use the same world-time semantics.

Workshop has no recipe

No Worker invents one.

Recipe pending but no Metal

No production occurs.

Metal available but no Hauler

Player may deliver it manually.

Metal input exists but no operator

Job waits.

Worker present but output occupied

Worker does not begin a new job.

Player and Worker attempt same workshop

Only one operates it.

Duty changed during active job

Current job completes before reassignment.

Workshop output removed manually

Workshop immediately becomes eligible for subsequent work if other requirements are met.

Dispatch zone cleared underneath an Ammo Crate

The crate remains physically on the ground as Finished Goods — Unstaged.

No Dispatch Area

Finished output can still exist at workshop output but cannot be automatically staged.

46. Provisional PV0 values

The following are explicit playable-version rules, not final balance claims:

Ammunition Workshop cost: 4 Wood + 2 Metal;

manual construction time: 6 world seconds;

Rifle Ammunition recipe: 1 Metal → Ammo Crate 8;

production work: 4 world seconds;

one workshop input crate;

one workshop output crate;

one Ammo Crate per Dispatch tile;

fixed workshop orientation;

Build Once Per Shipment has no backlog;

construction is player-performed only in this package.

Changing one later requires a recorded design change.

47. Observable Acceptance A — Build the first workshop

Begin from a valid PV0 rear state containing:

stored Wood 12;

stored Metal 3;

one logistics person.

Player:

opens Blueprints;

places an Ammunition Workshop blueprint;

leaves sufficient Storage available;

assigns the person to Hauling.

Expected:

Hauler physically delivers Wood 4 and Metal 2 from Storage to blueprint custody;

excess material remains physical and returns to Storage;

blueprint displays Wood 4/4 and Metal 2/2.

Player moves to operator position and holds E.

After 6 world seconds:

workshop completes;

exactly Wood 4 and Metal 2 have been consumed;

remaining raw stock is exactly Wood 8 and Metal 1.

No invisible resource has been created.

48. Observable Acceptance B — Automated production

Player:

creates at least one Dispatch tile;

inspects completed workshop;

selects Rifle Ammunition — Build Once;

assigns the person to Hauling long enough for Metal 1 to reach workshop input;

reassigns that person to Workshop Duty.

Expected:

active Hauling work is safely completed before reassignment;

worker physically reaches operator position;

one Metal becomes committed to the job;

four world seconds of actual operation occur;

one Ammo Crate containing exactly 8 rounds appears at output;

Metal input is reduced exactly by 1.

Player reassigns the worker to Hauling after the production job completes.

Expected:

worker physically moves the Ammo Crate to Dispatch;

Dispatch contains exactly one Ammo Crate 8.

49. Observable Acceptance C — Manual production

With another pending Build Once job and valid Metal input:

no Workshop Duty worker is operating;

player stands at the operator position;

holds E;

releases E before completion;

observes progress pause;

resumes E.

Expected:

progress resumes rather than resetting;

total active work reaches 4 world seconds;

exactly one additional Ammo Crate 8 is produced;

exactly one Metal is consumed.

Player and Worker methods therefore operate the same production rule.

50. Observable Acceptance D — Dispatch blockage

Arrange Dispatch so no empty tile remains.

Produce or queue another job.

Expected:

existing completed Ammo Crate remains physical;

workshop reports Output Blocked;

no next job begins;

no new ammunition is silently added elsewhere.

Player adds Dispatch space.

Expected:

Hauler automatically re-evaluates;

finished crate can be moved;

workshop becomes eligible for subsequent work.

51. Observable Acceptance E — Build Once Per Shipment

Arm a workshop with:

Build Once Per Shipment

Then receive a future non-empty incoming shipment.

Expected:

that physical arrival creates exactly one pending production job;

no job was created retroactively when the mode was selected;

an empty-order cycle creates no job.

If another non-empty shipment arrives before the recurring job completes:

no second hidden job is added;

workshop reports the skipped cycle.

After the job completes:

workshop returns to Armed;

the next later non-empty shipment may create the next job.

52. Evidence expected from developer

Engineering verification should support, not replace, normal playable behavior.

Return:

normal-session evidence for workshop placement → material delivery → construction → production → Dispatch;

at least one normal manual-work sequence;

at least one normal Workshop Duty sequence;

physical accounting of Wood, Metal and Ammo Crates;

a blocked Dispatch recovery sequence;

Build Once and Build Once Per Shipment behavior;

Hauler Decision Graph v1.1 evidence;

Workshop Duty Decision Graph v1.0 evidence;

pause / accepted time-control consistency;

relevant regression checks protecting accepted Rear Foundation 01 behavior.

Assertion count is not an acceptance metric.

No Dawson mechanical QA is requested.

53. Design history
PV0-R02-D01 — First workshop

Decision: Ammunition Workshop is the first constructed production building.
Reason: It directly connects physical rear resources to the military logistics loop Trencho is intended to create.

PV0-R02-D02 — Construction cost

Decision: 4 Wood + 2 Metal.
Reason: The accepted first shipment can establish one workshop while leaving resources for production and later play.
Status: Provisional balance value.

PV0-R02-D03 — Construction work

Decision: Player performs the first construction labor manually for 6 world seconds.
Reason: Gives blueprint/material/construction gameplay immediately without inventing a separate construction profession before it is needed.

PV0-R02-D04 — Physical input/output

Decision: Workshop input and output remain physical positions rather than invisible workshop inventory.
Reason: Preserve Trencho's physical logistics causality.

PV0-R02-D05 — Role separation

Decision: Haulers move materials; Workshop Duty operates workshops.
Reason: Labor allocation should create understandable opportunity costs rather than one universal worker automatically solving every logistics function.

PV0-R02-D06 — Rifle ammunition recipe

Decision: 1 Metal → one Ammo Crate containing 8 rounds in 4 world seconds.
Reason: Carries forward the accepted representative production conversion while giving the output a physical PV0 package.

PV0-R02-D07 — Recurring recipe

Decision: Build Once Per Shipment triggers on future physical non-empty shipment arrival and does not backlog.
Reason: Keeps the shipment-linked scheduling idea understandable without creating invisible production debt.

PV0-R02-D08 — Dispatch

Decision: Finished ammunition stages physically in Dispatch and does not enter raw Storage.
Reason: Establishes the visible outbound boundary required by the next military-export capability.

54. Future compatibility obligation

Any later feature adding:

additional workshops;

additional recipes;

automated construction;

worker priorities;

storage filters;

outbound trucks;

military procurement;

multiple ammunition/equipment categories;

must explicitly update the affected player rules, Hauler Decision Graph and Workshop Duty Decision Graph.

If engineering encounters a product-behavior case not answered here, route the ambiguity to the Game Designer rather than selecting gameplay semantics independently.

## Scheduling clarification amendment — 24 October 2026

This amendment resolves production-instruction behavior for Sections 23, 33–35.

Production scheduling invariant

A workshop may have:

one active production job; and

at most one unstarted future production job.

There is never a multi-job hidden backlog.

An active job is protected. Changing or clearing the workshop's production instruction does not cancel the active job, return its committed material, reset its progress, or alter its output.

An unstarted future job has not committed production material and may therefore be replaced or cleared by the player's scheduling choice.

Build Once

Selecting Build Once with no active or pending job creates one pending Build Once job.

Selecting Build Once again while that same unstarted Build Once job exists has no additional effect.

If a production job is already active, selecting Build Once schedules exactly one Build Once job to follow the active job.

Repeated Build Once selections while that future Build Once job is already scheduled do not add further jobs.

Build Once Per Shipment

Selecting Build Once Per Shipment arms the workshop for future physical non-empty incoming shipments.

If no job is active, switching to Build Once Per Shipment removes any unstarted Build Once job and leaves the workshop:

Armed — Waiting for Next Shipment

If a job is active, that active job continues unchanged. The new Per Shipment setting governs future scheduling after the current job.

When a qualifying physical shipment arrives while another non-recurring job is active, the workshop may schedule exactly one recurring job behind that active job.

A recurring job is therefore not skipped merely because an unrelated Build Once job is currently active.

Recurring-job duplication

If a recurring shipment-triggered job is already pending or active when another qualifying shipment arrives:

no additional recurring job is created;

the new shipment does not create backlog;

workshop status records:

Shipment Cycle Skipped — Previous Job Incomplete

Once the existing recurring job completes, the workshop returns to its armed state and a later qualifying shipment may create the next recurring job.

Mode changes with unstarted future work

Changing scheduling mode may replace an unstarted future job.

Per Shipment → Build Once

If an unstarted recurring job exists, it is replaced by one pending Build Once job.

Build Once → Per Shipment

If an unstarted Build Once job exists, that job is removed and the workshop becomes armed for future qualifying shipments.

No production material is returned or lost because unstarted future jobs have not yet committed production input.

Clear Production Instruction

Clearing the production instruction with no active job:

removes any unstarted pending job;

disables Per Shipment scheduling;

leaves the workshop at:

No Production Instruction

Clearing while a job is active:

does not affect the active job;

removes any unstarted future job;

disables future recurring scheduling;

causes the workshop to become No Production Instruction after the active job completes.

Shipment qualification remains unchanged

Only a future physical non-empty incoming logistics truck arrival triggers Build Once Per Shipment.

Empty-order cycles do not trigger it.

Selecting Per Shipment is not retroactive.

Debug due-now qualifies only when it still produces the normal physical shipment arrival.

Player-facing requirement

The workshop inspection interface must make the distinction understandable between:

the current active job;

one scheduled next job, when present;

the current scheduling mode.

The player must not be led to believe repeated clicks have created an unseen queue.
