Trencho Playable Version 0
Rear Foundation 03 — Outbound Dispatch, Physical Truck Delivery & HQ Military Intake

Date: 24 October 2026
Status: Design complete for implementation handoff
Authority: Trencho Game Designer under Dawson's direction
Dependencies: Accepted Rear Foundation 01 and Rear Foundation 02
Parent design: GDD v1.1, current Playable Version 0 design history, accepted command/logistics foundations

1. Player outcome

The player can take ammunition that physically exists in Dispatch and people intentionally designated for Military Service, send them on one real outbound logistics truck, watch that truck travel the authored logistics road to the friendly HQ, and see those exact resources and people enter friendly HQ custody.

The playable chain becomes:

incoming resources → physical Storage → workshop → physical ammunition → Dispatch → physical loading → outbound truck → authored road → friendly HQ → HQ military stores

and:

incoming person → Barracks/logistics work → designated Military Service → outbound truck → friendly HQ → awaiting military assignment

No cargo reaches HQ because a number was changed remotely.

No person appears at HQ without physically travelling there.

No ammunition reaches soldiers in this package.

2. Scope

This package adds:

one friendly outbound logistics truck;

one authored rear-to-HQ logistics road;

one rear outbound loading point;

outbound shipment confirmation;

physical loading of Dispatch ammunition;

personnel designation for the next HQ shipment;

physical passenger boarding;

truck transit;

friendly HQ receiving point;

HQ Rifle Ammunition stores;

HQ personnel intake;

truck return;

repeated outbound trips;

relevant player feedback;

Hauler Decision Graph v1.2;

Outbound Personnel Decision Graph v1.0;

Outbound Truck State Graph v1.0;

HQ Intake Decision Graph v1.0.

This package does not perform person-level battlefield resupply.

3. Fixed reference logistics route

The Playable Version reference scenario uses one authored friendly logistics road connecting:

Rear Logistics Area → Friendly HQ

The road and Friendly HQ destination are fixed for this reference scenario.

Procedural generation does not select:

the rear departure point;

the route;

the friendly HQ receiving point.

The outbound truck follows this visible road.

The player does not direct the truck's tactical route.

4. Friendly HQ starting state

The Friendly HQ already exists as the friendly military headquarters.

For this capability it gains:

an identifiable logistics receiving point;

Rifle Ammunition military stores;

a personnel intake/muster state.

PV0 HQ military reserve begins at:

0 Rifle Ammunition rounds

This does not remove or alter the ammunition already carried by soldiers at battle initialization.

Existing individual carried ammunition remains separate from HQ reserve.

5. HQ ammunition representation

Rifle Ammunition reaches HQ in the same physical Ammo Crate 8 packages produced by the rear workshop.

A delivered crate remains a military logistics package in HQ custody.

Friendly HQ inspection displays both:

number of Rifle Ammunition crates;

total Rifle Ammunition rounds represented by those crates.

Example:

2 delivered crates =

2 crates / 16 Rifle Ammunition rounds

No crate is counted twice.

6. PV0 HQ storage capacity

For Rear Foundation 03, Friendly HQ Rifle Ammunition stores have no gameplay capacity limit.

This is an explicit provisional rule.

The purpose of this package is to establish physical rear-to-HQ custody before adding military distribution pressure.

A later HQ/depot-capacity feature must introduce its own capacity and overflow behavior through a recorded design decision.

Engineering must not invent an HQ cap in this task.

7. Outbound truck

PV0 provides one friendly outbound logistics truck.

When available, it is visibly parked at the rear outbound loading point.

The truck has:

4 ammunition cargo positions;

4 personnel seats.

Cargo and personnel capacities are separate.

The truck may therefore carry up to:

four Ammo Crates 8;

four people;

on the same trip.

8. Truck availability

Only one friendly outbound shipment may be active.

The truck may be:

Available at Rear;

Loading;

En Route to HQ;

Unloading at HQ;

Returning;

Available at Rear.

The player cannot create an invisible second truck because the first is away.

9. Dispatch remains the cargo-selection mechanism

Ammunition becomes eligible for outbound shipment by physically occupying Dispatch.

The player does not need a per-crate checkbox.

Putting ammunition into Dispatch means:

This finished military good is available to send to HQ.

Leaving a crate outside Dispatch means it is not selected for shipment.

This keeps selection primarily spatial rather than menu-heavy.

10. Outbound shipment interface

The Logistics Terminal gains a compact Dispatch section/tab.

It displays:

outbound truck status;

number of eligible ammunition crates currently in Dispatch;

total eligible ammunition rounds;

number of people currently designated for the next HQ shipment;

current truck cargo/passenger capacity;

Dispatch to HQ;

concise reason Dispatch is unavailable when applicable.

It is not a military-command screen.

11. Personnel designation

The Tasks interface gains a separate designation:

Send to HQ

This is not a logistics duty.

A person may simultaneously have:

a current rear duty such as Hauling or Workshop Duty;

an uncommitted Send to HQ designation.

Before shipment commitment, the player may freely add or remove that designation.

12. Meaning of Send to HQ

Designating Send to HQ means:

This person is intended to leave rear logistics and enter Military Service on a future outbound shipment.

It does not instantly:

remove the person from rear work;

teleport them to HQ;

assign them to a Squad;

create a second military person.

Until actually committed to a shipment, they remain their existing rear person.

13. Dispatch eligibility

Dispatch to HQ is available only when:

the outbound truck is Available at Rear; and

at least one eligible Ammo Crate is in Dispatch or at least one person is designated Send to HQ.

A completely empty outbound shipment cannot be dispatched.

14. Shipment capacity selection

When the player confirms Dispatch to HQ:

up to 4 eligible Dispatch Ammo Crates are selected;

up to 4 designated people are selected.

If more than capacity is available, the excess remains for a later trip.

Because all current Ammo Crates are behaviorally identical Rifle Ammunition Crate 8 packages, the precise identity chosen among equivalent crates has no gameplay consequence.

For people, earlier Send to HQ designations are committed before later ones.

15. Shipment commitment

Confirmation creates one real outbound shipment.

Selected ammunition becomes:

Committed to HQ Shipment

Selected people become:

Committed to HQ Shipment

Commitment does not immediately move either one.

Their physical custody remains where they currently are until loading/boarding occurs.

16. No normal cancellation after commitment

For PV0, shipment commitment is final.

Once Dispatch to HQ is confirmed:

selected cargo remains committed;

selected people remain committed;

the player cannot cancel the shipment.

This is a provisional simplification.

The UI must make clear that Dispatch is a commitment action.

Future cancellation policy may be designed later.

17. Committed ammunition restrictions

A committed Ammo Crate:

cannot be reassigned to another outbound shipment;

cannot be returned to raw Storage;

cannot be consumed by another workshop or system;

may be physically moved only as part of completing the committed shipment.

The player may manually carry it toward the assigned truck.

A Hauler may load it.

18. Outbound loading point

The outbound truck has one fixed rear loading point connected to the authored logistics road.

Dispatch zones themselves do not need road adjacency.

Dispatch is staging.

The loading point is where staged goods physically become truck cargo.

19. Manual ammunition loading

The player may carry a committed Ammo Crate to the truck loading point.

At the truck, the player performs the normal load interaction for:

1 active world second

When loading completes:

the crate leaves player custody;

one truck cargo position becomes occupied;

the exact Ammo Crate 8 enters truck custody.

Moving away or stopping the interaction pauses loading without duplicating the crate.

20. Hauler ammunition loading

A Hauler treats committed outbound cargo as valid logistics work.

The Hauler physically:

travels to the committed crate;

takes custody;

travels to the outbound truck;

performs 1 active world second of loading;

transfers the crate into truck custody.

A Hauler does not select new shipment contents.

They execute the player's committed shipment.

21. Cargo slot revalidation

A carrier may load only while the assigned truck still has a cargo slot reserved for that committed crate.

Multiple Haulers may participate.

They must not:

load the same crate twice;

create more than four cargo crates;

destroy a crate because another worker reached the truck first.

22. Personnel commitment and current work

When a person becomes committed to the outbound shipment:

they accept no new rear jobs;

they complete any already-active protected work according to existing PV0 rules;

after that safe completion, they report to the outbound truck.

Examples:

A Hauler carrying a crate finishes its safe placement/loading/return before leaving.

A Workshop Duty worker already operating an active production job finishes that active job before leaving.

An idle or travelling-to-unstarted-work person abandons that unstarted job and reports to the truck.

23. Personnel boarding

A committed person physically travels to the outbound loading point.

At the truck they board for:

1 active world second

After boarding:

they leave rear-world pedestrian custody;

they remain the same persistent named person;

one passenger seat is occupied.

They do not become an abstract personnel count.

24. Rear duty after commitment

Once committed to the shipment, the person's rear duty is considered to be ending.

They do not begin additional Hauling or Workshop Duty work while waiting for the truck.

If loading is delayed, they wait at the outbound muster/loading area.

25. Departure condition

The truck departs automatically when every person and Ammo Crate committed to that shipment is physically aboard.

The player does not issue a second departure command.

Examples:

2 committed crates, no people → depart after both crates load.

no crates, 3 people → depart after all three board.

3 crates, 2 people → depart after all five committed entities are aboard.

26. Loading delay is physical

If a committed crate cannot reach the truck:

truck waits.

If a committed person cannot reach the truck:

truck waits.

Nothing teleports aboard to resolve the delay.

27. Missing Hauler

A shipment does not require an NPC Hauler.

If no Hauler is available:

the player may manually load all committed ammunition.

Committed people board themselves.

If the player does nothing, the truck remains Loading.

28. Committed crate moved by player

If the player picks up a committed crate:

it remains committed.

The player may place it:

back in Dispatch; or

into its assigned outbound truck.

The player may not place it into unrelated Storage or workshop input.

If dropped on valid ordinary ground during manual handling, it remains committed and becomes a valid Hauler loading target.

29. Dispatch zoning changed during loading

Clearing Dispatch under an uncommitted Ammo Crate makes it Unstaged according to existing rules.

A tile containing a committed shipment crate cannot have its Dispatch designation cleared until that crate leaves the tile.

Feedback:

Cannot clear: cargo committed to active shipment.

This prevents zoning from silently invalidating shipment custody.

30. Outbound truck road travel

After departure, the truck physically drives the authored road from rear logistics to Friendly HQ.

Normal one-way transit time for the fixed PV0 reference route is:

20 world seconds

Movement is continuous and visible.

This timing is provisional balance/pacing.

The player cannot order the truck to stop, reroute, or divert during this package.

31. Shared time behavior

Outbound truck travel uses the shared world clock.

Pause freezes truck movement.

Accepted accelerated time advances the truck consistently with world time.

Switching between rear and battlefield/HQ views does not stop, restart, or alter the trip.

32. Observation

The truck must be observable through normal game presentation during:

rear departure;

road transit;

HQ arrival.

The acceptance of this capability must not depend on a debug-only route visualization.

33. Current route safety

For PV0 Rear Foundation 03, the authored rear-to-HQ road is not subject to:

enemy interdiction;

mines;

destroyed bridges;

traffic collision;

alternative route selection.

The truck therefore completes valid travel unless the game is paused.

This is an explicit bounded rule, not a statement that Trencho's final logistics routes are always safe.

34. HQ arrival

At Friendly HQ the truck enters the authored logistics receiving point and changes to:

Unloading at HQ

The player does not manually operate the HQ unloading process.

Friendly HQ receives its own shipments automatically.

35. Passenger unloading

Passengers disembark first.

Each passenger requires:

1 world second

to disembark into HQ custody.

Each person remains their same persistent identity.

36. HQ personnel intake

A rear person delivered to HQ becomes:

Awaiting Military Assignment

Their previous rear duty and Send to HQ designation are cleared.

They:

no longer appear as a rear logistics worker;

appear in friendly HQ personnel intake;

are not automatically inserted into an existing Squad;

are not duplicated.

Actual formation assignment is a later military-personnel capability.

37. Ammunition unloading

After passengers disembark, Ammo Crates unload one at a time.

Each crate requires:

1 world second

of automatic HQ unloading.

On completion of each crate:

that exact crate leaves truck custody;

it enters Friendly HQ military-store custody;

HQ Rifle Ammunition increases by exactly 8 rounds.

The stock increase therefore occurs during unloading, not merely because the truck reached HQ.

38. HQ stock example

Truck arrives carrying three Ammo Crates 8.

Before unloading:

HQ reserve = 0

After first unload:

HQ reserve = 8

After second:

HQ reserve = 16

After third:

HQ reserve = 24

The three increments correspond to three actual crates.

39. No person-level resupply yet

HQ ammunition arriving in this task does not automatically refill:

infantry;

Squad Leaders;

Platoon leaders;

Company staging.

The ammunition stops in HQ military stores.

Existing carried battlefield ammunition remains unchanged.

This boundary is required before #15 is reconciled.

40. Friendly HQ inspection

Normal friendly HQ inspection shows exact friendly information:

Rifle Ammunition crates in military stores;

total rounds;

names of people Awaiting Military Assignment;

current friendly logistics truck if present.

This is friendly exact inspection, not enemy information leakage.

41. Rear delivery confirmation

After HQ completes unloading, the rear-facing Dispatch interface may show the shipment as:

Delivered

with:

ammunition crates delivered;

rounds delivered;

personnel delivered.

It does not need to expose unrelated battlefield truth.

42. Truck return

After the last committed entity leaves truck custody:

the truck automatically begins Returning;

it follows the same authored logistics road;

return travel takes 20 world seconds;

it becomes Available at Rear when it physically reaches the loading point.

The truck carries no hidden return cargo in this package.

43. Repeated shipments

The player may continue:

producing ammunition;

staging Ammo Crates in Dispatch;

designating people Send to HQ;

while the truck is away.

They cannot confirm the next outbound shipment until the truck returns.

There is no invisible queue of future outbound shipments.

44. Truck-capacity overflow

If six Ammo Crates are staged when a shipment is confirmed:

four become committed;

two remain ordinary staged Dispatch cargo.

After the truck returns, the remaining two may be included in a later shipment.

The same rule applies to more than four designated people.

45. Mixed shipment capacity

Cargo positions and passenger seats are independent.

Example:

4 Ammo Crates;

4 people;

may all travel on one truck.

Sending people does not reduce the four-crate ammunition capacity in PV0.

This is provisional vehicle capacity behavior.

46. Empty categories are valid

An outbound shipment may be:

ammunition only;

personnel only;

mixed.

It may not contain neither.

47. Person designation beyond capacity

If six people are designated Send to HQ:

the first four committed designations enter the next shipment;

two remain designated but uncommitted;

those two continue existing rear duties until a later shipment commits them.

They must not stop working merely because they are waiting for a later truck.

48. Committed person becomes blocked

If a committed person cannot reach the truck:

status:

Committed — Boarding Blocked

The truck waits.

If their path becomes available, they resume reporting to the truck automatically.

No replacement person is silently selected.

49. Outbound shipment status

Player-readable shipment states are:

Truck Available

Loading

Waiting for Cargo

Waiting for Personnel

En Route to HQ

Unloading at HQ

Returning

Delivered

The interface may show more than one reason while Loading.

50. Required alerts
Outbound Shipment Waiting — Cargo

Committed ammunition has not reached the truck.

Outbound Shipment Waiting — Personnel

At least one committed person has not boarded.

Committed Cargo Blocked

A committed crate cannot currently reach the truck.

Personnel Boarding Blocked

A committed person cannot currently reach the truck.

Alerts clear automatically when resolved.

51. Hauler Decision Graph v1.2

This supersedes v1.1 where outbound loading exists.

Assigned to Hauling?

→ NO
Do not accept Hauling jobs.

→ YES

Committed to outbound personnel shipment?

→ YES
Finish existing protected carried work if any.
Accept no new hauling job.
Report to outbound truck.

→ NO

Currently carrying a crate?

→ YES
Complete, retarget or safely recover that crate according to existing custody rules.

→ NO

Evaluate valid work in this order:

Active incoming truck cargo with valid Storage destination.

Committed outbound Ammo Crate with assigned truck waiting.

Delivered raw resources to Storage.

Completed workshop output to Dispatch.

Blueprint material requests.

Workshop Metal input requests.

Loose finished goods to Dispatch.

Other loose raw resources to Storage.

No valid work → idle.

A Hauler must not decide which ammunition should be shipped.

Shipment commitment is a player decision.

52. Outbound Personnel Decision Graph v1.0

Send to HQ designated?

→ NO
Continue normal rear duty.

→ YES, but not committed
Continue normal rear duty.
Remain eligible for a future shipment.

→ YES and committed

Active protected work underway?

→ YES
Finish current protected work.
Do not begin another job.

→ NO

Path to outbound truck available?

→ YES
Travel to loading point.
Board for 1 world second.
Enter truck passenger custody.

→ NO
Wait with Committed — Boarding Blocked.
Re-evaluate when path changes.

The person never chooses to cancel Military Service designation after commitment.

53. Outbound Truck State Graph v1.0

Available at Rear

Valid player Dispatch confirmation?

→ NO: remain Available.

→ YES: lock selected entities → Loading

Loading

All committed crates aboard AND all committed people aboard?

→ NO: remain Loading.

→ YES: En Route to HQ

En Route to HQ

Physically travel authored road for 20 world seconds.

→ Unloading at HQ

Unloading at HQ

Passengers disembark first, 1 second each.

Then Ammo Crates unload, 1 second each.

Truck empty?

→ YES: Returning

Returning

Physically travel authored road for 20 world seconds.

→ Available at Rear

There is no hidden state that grants HQ inventory before unloading.

54. HQ Intake Decision Graph v1.0

Truck at friendly HQ receiving point?

→ NO
No intake.

→ YES

Passengers remain?

→ YES
Disembark next passenger.
Persistent person enters Awaiting Military Assignment.

→ NO

Ammo Crates remain?

→ YES
Unload next crate.
Add exact crate to HQ custody.
HQ round tally increases by 8.

→ NO
Release empty truck to Return state.

HQ does not automatically distribute ammunition to soldiers.

55. Player interaction boundary

The player controls:

which goods physically reach Dispatch;

who is designated Send to HQ;

when Dispatch to HQ is confirmed;

whether to personally help load ammunition;

rear labor allocation.

The player does not control:

the truck's road route;

the truck's departure after loading is complete;

HQ automatic unloading;

battlefield resupply from HQ;

assignment of a delivered recruit to a Squad in this package.

56. Debug — Send Shipment to HQ Immediately

The existing development/debug requirement is retained as:

Send Shipment to HQ Immediately

For Rear Foundation 03 this control is enabled only after:

a real outbound shipment has been committed;

every committed crate/person has physically loaded/boarded;

the truck is En Route to HQ.

Using it:

bypasses only the remaining road-travel wait;

moves that already-departed truck to the legitimate HQ arrival boundary;

still requires normal passenger disembarkation;

still requires normal crate unloading;

still increments HQ stock only during unloading.

It does not:

create cargo;

choose shipment contents;

load cargo;

board people;

create HQ inventory directly.

At least one normal acceptance trip must use the full physical road transit without this debug action.

57. Important edge cases
Dispatch contains ammunition but truck is away

Goods remain staged.

No future shipment is automatically queued.

Person is designated while truck is away

They remain working until a future shipment actually commits them.

Person designation is removed before commitment

They remain an ordinary rear worker.

Person is committed during active workshop work

They finish that active job, then report to truck.

Hauler is committed while carrying a crate

They complete safe handling of that crate, then report.

Cargo is committed but no Hauler exists

Player may load manually.

Truck otherwise waits.

Committed crate becomes unreachable

No replacement or teleport.

Truck waits until recovered.

More than four crates

Only four committed.

Remainder stays staged and uncommitted.

More than four designated people

Only four committed.

Remainder stays designated and working.

No ammunition, people available

Personnel-only trip is valid.

Ammunition available, no people

Cargo-only trip is valid.

Nothing eligible

Dispatch control is unavailable.

Pause during loading

Active one-second loading/boarding progress pauses.

Pause during travel

Truck stops.

View switch during travel

No state change other than camera/view.

HQ already contains ammunition

New crates add exactly 8 each to existing HQ stock.

58. Explicit exclusions

This package does not define:

HQ ammunition capacity;

battlefield distribution from HQ;

Company collection from HQ;

Company staging replenishment;

person-level soldier resupply;

recruit assignment to military formations;

enemy rear logistics;

enemy outbound trucks;

convoy escorts;

route interdiction;

road destruction;

truck destruction;

alternate routes;

multiple friendly outbound trucks;

final vehicle inventory UI;

HQ defeat consequences;

save/campaign behavior;

final art.

59. Provisional PV0 rules

The following are provisional but authoritative for implementation now:

one friendly outbound truck;

four Ammo Crate cargo positions;

four passenger seats;

20-world-second one-way travel;

1-world-second crate loading interaction;

1-world-second passenger boarding;

passengers unload before ammunition;

1-world-second HQ unloading per passenger/crate;

no HQ ammunition capacity limit;

no normal cancellation after shipment commitment;

safe authored road with no route failure;

no hidden outbound shipment queue.

They may later be changed through recorded design decisions.

60. Observable Acceptance A — Normal mixed shipment

Use the actual normal PV0 entry and existing rear systems.

Produce and stage at least:

2 Rifle Ammunition Crates 8.

Have at least:

1 rear person available.

Player:

designates that person Send to HQ;

confirms Dispatch to HQ.

Expected:

exactly two Ammo Crates become committed;

exactly one person becomes committed;

committed rear person stops accepting new work after any protected current action;

Hauler/player physically loads both crates;

person physically reports and boards;

truck departs only after all three committed entities are aboard;

truck visibly travels the full authored road for 20 world seconds;

truck arrives at Friendly HQ;

person disembarks and becomes Awaiting Military Assignment;

first Ammo Crate unload changes HQ reserve 0 → 8;

second changes HQ reserve 8 → 16;

no soldier inventory changes;

empty truck physically returns;

truck becomes Available at Rear.

61. Observable Acceptance B — Capacity overflow

Stage:

6 Ammo Crates.

Designate:

6 people.

Confirm one shipment.

Expected:

exactly 4 crates and 4 people become committed;

2 crates remain staged;

2 people remain designated but uncommitted and continue rear duties;

first truck carries no more than its capacity;

after truck returns, remaining eligible entities can form a later shipment.

No hidden second shipment exists before player confirmation.

62. Observable Acceptance C — Active worker transition

During an active workshop production job:

designate the Workshop Duty person Send to HQ;

confirm a shipment that commits that person.

Expected:

active production job completes;

worker begins no new Workshop Duty job;

worker then physically reports to truck;

produced output remains governed by normal rear Hauling/Dispatch rules;

no job progress or person identity is lost.

63. Observable Acceptance D — Shared time and views

During a normal road journey demonstrate:

pause freezes the truck;

resume continues from same location;

accepted accelerated time advances the trip consistently;

rear/battlefield view switching does not reset or stop truck state;

cargo/passenger/HQ accounting is identical at equal world time regardless of view history.

64. Observable Acceptance E — Debug boundary

Complete at least one full normal trip first.

On a later real shipment:

commit real cargo/personnel;

physically load/board them;

allow the truck to depart normally;

use Send Shipment to HQ Immediately.

Expected:

only remaining road travel is skipped;

truck reaches legitimate HQ receiving state;

passengers/crates still unload normally;

HQ inventory changes only as crates unload.

This demonstrates that debug timing is distinct from product custody.

65. Evidence expected from developer

Return normal-session evidence covering:

physical Dispatch selection;

physical crate loading;

person designation and boarding;

full normal road transit;

HQ arrival;

incremental HQ ammunition receipt;

persistent personnel intake;

truck return;

capacity overflow;

at least one active-worker-to-passenger transition;

shared-clock/view behavior.

Focused tests may support:

capacity;

commitment exclusivity;

custody conservation;

exact 8-round HQ increments;

no soldier refill;

no hidden second shipment;

debug-boundary behavior;

decision-graph negative cases.

Assertion quantity is not an acceptance criterion.

No Dawson mechanical QA is requested.

66. Design history
PV0-R03-D01 — Fixed logistics road

Decision: PV0 uses one authored rear-to-Friendly-HQ road.

Reason: The reference playable version needs one comprehensible logistics route before procedural geography is relevant.

PV0-R03-D02 — Dispatch is selection

Decision: Physical presence in Dispatch means ammunition is eligible for shipment.

Reason: Prefer world organization over an additional per-item management interface.

PV0-R03-D03 — Shipment commitment

Decision: Player confirmation locks one physical shipment.

Reason: Custody must be unambiguous from rear staging through HQ receipt.

PV0-R03-D04 — Truck capacities

Decision: 4 Ammo Crates and 4 people.

Reason: Gives the physical vehicle meaningful bounded capacity while allowing mixed logistics/personnel transport.

Status: Provisional.

PV0-R03-D05 — Personnel commitment

Decision: Committed workers finish current protected work but accept no new rear work.

Reason: Preserve existing labor semantics while making military transfer physically consequential.

PV0-R03-D06 — HQ store boundary

Decision: Ammo stops in HQ military stores.

Reason: Separates rear delivery from the later military distribution/resupply problem and prevents another invisible handoff.

PV0-R03-D07 — HQ capacity

Decision: No gameplay cap during this package.

Reason: A finite HQ store without an implemented military sink could create an unrecoverable deadlock unrelated to the capability being evaluated.

PV0-R03-D08 — Physical travel timing

Decision: 20 world seconds each direction on the fixed reference road.

Reason: Long enough to observe logistics in motion while keeping PV0 iteration compact.

Status: Provisional pacing.

PV0-R03-D09 — Debug travel bypass

Decision: Debug can skip only remaining road travel after real loading/departure.

Reason: Development convenience must not manufacture cargo or HQ receipt.

67. Future compatibility obligation

Any later feature that introduces:

Company pickup;

military trucks;

HQ store capacity;

recruit assignment;

enemy interception;

truck loss;

route choice;

multiple vehicle types;

multiple ammunition/equipment categories;

must explicitly update the affected:

shipment rules;

custody rules;

Hauler graph;

personnel graph;

truck graph;

HQ intake graph.

Engineering must return any unresolved player/world/AI semantic case to the Game Designer rather than inventing a rule.

## HQ Logistics Receiver Clarification — 24 October 2026

This clarification amends Rear Foundation 03 wherever it assumes that a physical Friendly HQ already exists in the normal PV0 path.

1. Friendly HQ Logistics Receiver

Rear Foundation 03 introduces a provisional world location named:

Friendly HQ Logistics Receiver

It represents the friendly HQ's logistics receiving and personnel-muster function for the Playable Version 0 reference scenario.

It is deliberately not the future combat-capable Friendly HQ entity.

The Logistics Receiver has no:

health;

damage state;

capture state;

destruction behavior;

victory/defeat behavior;

enemy interaction;

defensive AI;

combat geometry requirement.

Those remain outside #24 and under the later HQ/outcome design work.

2. Fixed authored location

The Friendly HQ Logistics Receiver is fixed for the PV0 reference scenario.

It is not positioned by procedural sector generation.

The authored outbound logistics road connects:

Rear outbound loading point → Friendly HQ Logistics Receiver

The route and destination are stable between normal reference-scenario runs.

No legacy proof coordinates or legacy Battle HQ positions are product authority.

3. Relationship to the battlefield

The Logistics Receiver represents the friendly HQ's rear-facing logistics interface.

It does not establish where the eventual combat HQ building/objective must exist inside the battlefield.

For #24:

the existing battlefield continues unchanged;

the existing logical Commander continues unchanged;

the Logistics Receiver does not participate in combat;

the Logistics Receiver cannot be targeted by enemies;

ammunition delivered there does not automatically enter Company, staging, or individual inventories.

Later design may connect or consolidate the logistics representation with a physical combat HQ.

That is not decided by this task.

4. Player-visible physical location

The Logistics Receiver must be a normal-play observable location.

The player must be able to see:

the authored road arriving at it;

the truck approach;

the receiving position;

passengers disembark;

ammunition unload;

the empty truck depart for the rear.

This observation must not require a debug visualization.

The exact camera implementation remains engineering-owned, but the product result must allow ordinary player observation of both the road journey and HQ intake.

5. Player physical access

The rear player character does not travel to or physically operate the Friendly HQ Logistics Receiver in Rear Foundation 03.

Player agency at HQ is observational/inspection only.

The player does not:

manually unload the HQ truck;

move HQ ammunition crates;

assign delivered personnel to formations;

perform HQ labor;

issue battlefield orders from the receiver.

This avoids introducing an additional playable-character travel loop before it is designed.

6. Friendly inspection

Because this is a friendly facility, the player may inspect its exact logistics state.

Normal inspection exposes:

Military Stores

number of Rifle Ammunition Crates received;

total Rifle Ammunition rounds represented by those crates.

Personnel Muster

persistent names of people currently Awaiting Military Assignment.

Current delivery

When a friendly logistics truck is actively unloading:

remaining passengers;

remaining ammunition crates.

This is friendly logistics inspection and does not expose additional battlefield truth.

7. Receiving point

The Logistics Receiver contains one authored truck receiving position.

Only the friendly outbound logistics truck uses it in this package.

When the truck reaches that position:

En Route to HQ → Unloading at HQ

The truck remains physically present until every passenger and ammunition crate in that shipment has been unloaded.

8. Personnel muster area

The Logistics Receiver includes an authored Personnel Muster area.

Passengers unload one at a time according to the existing one-world-second intake rule.

After a passenger finishes disembarking:

the person remains the exact same persistent individual;

rear duty is cleared;

Send to HQ designation is cleared;

status becomes Awaiting Military Assignment;

the person physically reports to/remains in the HQ Personnel Muster.

They do not:

join an existing Squad;

replace a casualty;

become a generic manpower value;

enter battlefield combat;

disappear.

9. Muster capacity

For Rear Foundation 03, Personnel Muster has:

no gameplay capacity limit

This is provisional.

Delivered people must never be refused, deleted, teleported elsewhere, or left trapped inside the truck because a final HQ housing/personnel-capacity system has not yet been designed.

People remain persistent and inspectable at Muster.

A future personnel/facility-capacity design may replace this rule.

10. Ammunition intake

The receiver includes Friendly HQ Military Stores.

Ammo Crates unload after passengers.

Each crate requires the already specified one world second of HQ unloading.

Only after that crate finishes unloading:

truck custody decreases by one Ammo Crate 8;

HQ military-store custody increases by that exact crate;

displayed HQ Rifle Ammunition total increases by exactly 8 rounds.

Arrival at the receiver alone does not credit ammunition.

11. Military Stores capacity

The previously authored provisional rule remains:

no gameplay ammunition capacity limit in Rear Foundation 03

No overflow, depot-capacity, dumping, rejection, or alternate-storage behavior is introduced in #24.

12. No military distribution

Ammunition in Friendly HQ Military Stores remains there.

It does not automatically move to:

Commander;

Company;

Platoon;

Squad;

individual infantry;

existing Company staging.

No demand is fulfilled merely because HQ has stock.

The next military-side design must explicitly define legitimate custody and movement from HQ outward.

13. Truck departure and return

After the final passenger/crate leaves truck custody:

the receiver releases the empty truck;

truck state becomes Returning;

the truck physically follows the authored road back to the rear;

no return cargo exists in this package.

14. Observation boundary

The player may observe and inspect:

friendly route;

friendly truck;

Friendly HQ Logistics Receiver;

friendly HQ ammunition stores;

friendly muster personnel.

This does not reveal:

enemy rear logistics;

enemy HQ state;

enemy personnel;

hidden enemy battlefield state.

15. Edge cases
Personnel-only shipment

Truck arrives, people disembark into Muster, then truck returns.

Ammunition-only shipment

Truck unloads crates into Military Stores, then returns.

Mixed shipment

Passengers unload first, ammunition second, as previously specified.

Existing Muster population

New people join the same persistent Muster population. No capacity failure occurs.

Existing HQ ammunition

Each unloaded crate adds exactly eight rounds to existing stores.

Player viewing another area

Truck travel and unloading continue on the shared world clock.

Pause

Truck and unloading stop.

Combat elsewhere

Combat does not damage, interrupt, capture, or destroy this provisional receiver.

Logical Commander death/change

Does not remove or invalidate the Logistics Receiver under this package.

16. Combat-HQ non-equivalence

For avoidance of doubt:

Friendly HQ Logistics Receiver ≠ final physical combat HQ

Rear Foundation 03 proves:

rear logistics → physical road transport → HQ-side logistics custody

It does not prove:

combat HQ implementation → destruction → WAR-01 defeat

That remains separately designed and accepted later.

Design history
PV0-R03-D10 — Provisional HQ logistics representation

Decision: Introduce a fixed non-combat Friendly HQ Logistics Receiver for the PV0 reference scenario.

Reason: The current normal session has a logical Commander but no physical HQ suitable for rear logistics intake. Rear→HQ logistics must become playable without prematurely defining #19 combat-HQ semantics.

PV0-R03-D11 — Fixed/non-procedural destination

Decision: The receiver and rear-to-HQ road are authored and stable.

Reason: PV0 is intentionally establishing a deterministic reference scenario before procedural geography returns to the critical path.

PV0-R03-D12 — Observation without player operation

Decision: Player can normally observe and inspect the receiver but does not physically operate there.

Reason: HQ intake must be legible without expanding #24 into a second player-character logistics workplace.

PV0-R03-D13 — Unlimited provisional muster

Decision: Personnel Muster has no gameplay capacity limit in #24.

Reason: Personnel persistence must be preserved without inventing final HQ housing/recruit-capacity rules.

PV0-R03-D14 — No relationship inferred to #19

Decision: This receiver establishes no combat-HQ geometry, damage, capture, destruction, or defeat semantics.

Reason: Rear logistics intake and WAR-01 combat-HQ resolution are separate unresolved capabilities.
