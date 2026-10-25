Trencho Playable Version 0
Rear Foundation 01 — Incoming Delivery, Storage & Hauling

Date: 24 October 2026
Status: Design complete for implementation handoff
Authority: Trencho Game Designer under Dawson's direction
Primary source: Dawson's Playable Logistics Scenario and system_examples.zip
Parent design: GDD v1.1 and current connected-slice addenda

1. Purpose

This capability establishes the beginning of the actual playable rear game.

The player starts with an empty logistics field and a logistics terminal, establishes the minimum receiving infrastructure, configures an incoming shipment, watches a truck physically arrive, receives people and physical resources, and either personally handles those resources or assigns a person to haul them into player-created storage.

The capability is complete when the following loop works coherently in the normal playable rear:

configure order → truck arrives → people disembark → resources remain physical → player/Hauler unloads → resources enter storage → storage capacity/stacking affects subsequent hauling

This is not a proof scene.

This is not a generalized final logistics system.

It is the first playable version of the rear logistics operation.

2. Starting state

The playable rear begins with:

one player character;

one logistics terminal;

otherwise empty buildable logistics ground;

the authored incoming road/access edge required by logistics trucks.

There is no prebuilt:

Deliverables Area;

Storage Area;

Barracks;

workshop;

Dispatch Area;

assigned logistics worker.

The player establishes those capabilities through play.

This package implements only:

Deliverables Area;

Storage Area;

Barracks;

incoming orders;

incoming shipment trucks;

resource crates;

manual crate handling;

Hauling assignment;

automatic hauling into Storage.

Workshop production and outgoing dispatch are subsequent capabilities.

3. Placement grid

The logistics area uses the existing design concept of an invisible placement grid.

For this playable version:

zones occupy whole grid tiles;

zone drawing snaps to those tiles;

the grid is shown while the player is drawing or clearing a zone;

the grid is otherwise hidden unless another interaction requires it.

A grid tile may belong to only one persistent zone type at a time.

Drawing the same zone type across already matching tiles simply extends or preserves that zone.

Drawing one zone type across tiles belonging to another zone type does not silently replace the existing zone.

Those tiles are shown as conflicting and remain unchanged.

The player uses Clear Zone first if they want to repurpose existing zoned ground.

This preserves the purpose of the explicit Clear Zone tool and prevents accidental destruction of a working logistics layout.

4. Zones Menu

The Zones Menu exposes only zone types currently usable by the playable version.

For this capability it contains:

Deliverables Area

Storage Area

Barracks

Clear Zone

Dispatch Area is added when outgoing military dispatch becomes playable.

The player selects a zone type and draws an area across the ground.

During drawing:

valid prospective tiles are visibly distinguished;

invalid/conflicting tiles are visibly distinguished;

releasing the drawing input applies the zone to valid tiles;

invalid tiles are left unchanged.

The player should not need a separate confirmation dialog for ordinary zone painting.

5. Deliverables Area
5.1 Purpose

The Deliverables Area is the physical receiving location for incoming logistics shipments.

There is exactly one active logical Deliverables Area in the playable rear.

The area may contain multiple contiguous grid tiles.

The player may enlarge or reduce it through zone drawing and Clear Zone.

5.2 Road access

At least one Deliverables tile must touch the authored incoming logistics access edge/road.

A disconnected Deliverables Area cannot receive a truck and is not considered valid.

The player receives clear placement feedback when attempting to create a Deliverables Area that cannot be served by the incoming road.

5.3 Capacity

Each Deliverables tile can hold at most:

1 resource crate

People do not consume crate-storage slots merely by walking through or disembarking.

Deliverables is temporary receiving space, not long-term storage.

A crate sitting in Deliverables remains:

Delivered / Unstored

until it is moved into Storage.

5.4 Active shipment protection

While a truck is physically servicing the Deliverables Area, the player cannot clear the tiles currently required for that active delivery.

Attempting to do so produces:

Cannot clear: active delivery in progress.

Other unused Deliverables tiles may still be changed.

6. Storage Area

Storage Areas are player-created zones.

The player may create multiple separate Storage Areas.

Each Storage tile can contain at most:

1 physical crate

For this capability, Storage accepts:

Wood

Metal

Cloth

No resource filters or storage priorities exist yet.

Those are later design features if Trencho needs them.

7. Resource crates

Wood, Metal, and Cloth are physical resources.

Each resource crate contains only one resource type.

A crate may contain:

1–10 units

A crate never contains mixed resource types.

Shipment quantities are packaged into crates of up to 10.

Examples:

4 Metal → one Metal crate containing 4.

10 Wood → one Wood crate containing 10.

17 Wood → one Wood crate containing 10 and one containing 7.

The crate visibly communicates:

resource type;

current quantity.

Moving or stacking resources changes that displayed quantity.

Resources never disappear merely because they are not stored.

8. Storage stacking rule

Maximum stack size:

10 units per crate

When a resource is stored, compatible partially filled crates are used before empty Storage tiles.

Example:

Storage contains:

Wood 7

An incoming carried crate contains:

Wood 6

The result is:

existing stored crate becomes Wood 10;

carried crate now contains Wood 3;

the remaining Wood 3 must then seek another valid destination.

If an empty Storage tile exists, the remaining 3 are placed there.

Result:

Storage tile A: Wood 10

Storage tile B: Wood 3

There is no resource loss and no temporary invisible quantity.

9. Multiple partial stacks

If more than one compatible partial stack has room, the carrier uses a suitable reachable partial stack before consuming an empty tile.

When several destinations are behaviorally equivalent, their exact tie resolution has no gameplay significance; all must obey the same capacity and custody rules.

The important player-facing rule is:

existing stack space is used before new Storage space.

10. Full Storage behavior

Storage being full is a normal logistics condition, not an error state that destroys or teleports goods.

Storage is considered unable to accept a resource when:

no compatible partial stack has remaining capacity; and

no empty Storage tile is available.

When that occurs:

A crate still on the truck

The crate remains physically on the truck.

The truck waits.

A crate already in Deliverables

The crate remains physically in Deliverables.

A Hauler who has not yet picked the crate up

The Hauler does not start a haul that currently has no valid destination.

A Hauler already carrying a crate when the destination becomes unavailable

The Hauler seeks another valid Storage destination.

If none exists, the Hauler attempts to return the crate to its original valid pickup location.

If that location is no longer available, the Hauler remains holding the crate and reports:

Blocked — No Storage Space

The resource remains physically in that person's custody.

Player response

The player can resolve the blockage by:

creating additional Storage tiles;

clearing other stored material through future systems;

manually rearranging crates.

Once valid Storage becomes available, blocked Haulers automatically reconsider the job.

The player does not need to reassign Hauling.

11. Loose resources

A physical crate may temporarily exist outside Storage.

Examples include:

a crate in Deliverables;

a crate the player has set down;

a crate whose Storage zone was cleared underneath it.

Such a crate is:

Unstored

It continues to exist physically and retains its exact contents.

A Hauler may move an eligible loose resource into available Storage.

12. Clearing Storage underneath a crate

Clear Zone removes the Storage designation.

It does not delete the crate.

Example:

Storage tile contains Metal 8.

Player clears that Storage tile.

The tile becomes ordinary ground.

Metal 8 remains physically where it was.

It is now Unstored.

A Hauler may move it to another Storage Area when space exists.

This makes zone editing reversible without destroying resources.

13. Manual player handling

The player may carry one resource crate at a time.

The player can:

take a crate from the incoming truck;

take a crate from Deliverables;

take a loose crate;

take a stored crate;

carry it physically;

place it onto valid ground or Storage.

13.1 Placing onto an empty Storage tile

The carried crate becomes stored on that tile.

13.2 Placing onto a compatible partial stack

As much of the carried resource as fits is transferred into the stored crate.

If material remains, the player continues carrying the remainder.

Example:

stored Metal 8;

player carries Metal 5.

After placing:

stored crate = Metal 10;

player still carries Metal 3.

13.3 Incompatible occupied Storage tile

A Wood crate cannot be placed onto a tile already occupied by Metal.

Nothing changes.

The player receives concise feedback:

Storage tile occupied by Metal.

13.4 Full compatible stack

Attempting to place Wood onto Wood 10 does nothing.

Feedback:

Wood stack full.

13.5 Ordinary ground

The player may set a crate onto a free walkable ground tile.

It becomes an Unstored loose crate.

This allows physical recovery rather than forcing the player to keep carrying a crate indefinitely.

14. Incoming shipment budget

Each shipment cycle supplies a base budget of:

20 points

Current costs:

Item	Cost
Wood	1
Metal	1
Cloth	2
Person	5

Quantities are whole numbers and cannot be negative.

The Orders interface continuously displays:

available points;

current order cost;

remaining points.

The player cannot confirm an over-budget order.

15. Carried shipment points

The next shipment's available points are:

20 base points + carried points

When an order is confirmed:

unspent points ÷ 2, rounded down

becomes the carryover for the next shipment.

Only that calculated carryover moves forward.

Example:

Available: 20
Spent: 15
Unspent: 5
Carryover: floor(5 ÷ 2) = 2

Next shipment:

22 available points

This does not permanently increase the 20-point base.

16. Zero-content orders

The player may intentionally confirm an order containing nothing.

This represents declining the current shipment while preserving part of the unused allocation.

No empty truck is sent.

The carryover rule still applies.

For example:

available 20;

spent 0;

carryover = 10.

The shipment cycle resolves and the next shipment receives:

30 available points

This is an intentional strategic option, not an error.

17. Orders interface

The Logistics Terminal Orders tab contains:

Wood quantity

Metal quantity

Cloth quantity

People quantity

Available Points

Current Cost

Remaining Points

Order Last Shipment

Confirm Order

Clear Order

The interface should remain compact.

It is not intended to become a general omniscient logistics dashboard.

Order Last Shipment

Copies the previous confirmed quantities into the current draft.

It does not confirm them.

If that copied order now exceeds available points, the quantities remain visible but Confirm Order is unavailable until the player reduces the order.

Clear Order

Sets all current draft quantities to zero.

It does not change a previously confirmed shipment.

Confirm Order

Locks the current draft.

The player cannot edit a confirmed order.

Changes apply to the following shipment instead.

18. First shipment

The recurring shipment clock does not begin until the player confirms the first order.

A non-empty first order also requires a valid road-accessible Deliverables Area.

If no valid Deliverables Area exists:

Confirm Order is unavailable.

Player feedback:

Create a road-accessible Deliverables Area before receiving this shipment.

When the first order is confirmed:

the order is locked;

the shipment becomes immediately eligible for delivery;

its truck physically enters through the normal incoming logistics access;

the five-minute recurring shipment clock begins.

"Immediate" means the player does not wait five minutes for eligibility.

It does not mean resources teleport into the logistics area.

The truck still physically arrives.

19. Recurring shipment cycle

Standard interval:

5 world minutes

The shipment timer uses the same world clock as the rest of the game.

Pause pauses it.

Any accepted time acceleration advances it consistently with world time.

The player may prepare and confirm the next order while the timer counts down.

Timer reaches zero with a confirmed order

The shipment becomes due.

If the incoming access is free, the truck enters.

If access is occupied by the previous shipment, the order becomes:

Queued — Delivery Access Blocked

It is not lost.

Timer reaches zero without a confirmed order

The cycle becomes:

Ready — Awaiting Order

No shipment is lost.

When the player eventually confirms an order, it becomes immediately due.

The next five-minute interval is based on that resolved shipment cycle rather than silently skipping the player's allocation.

One unresolved incoming shipment

For Playable Version 0, only one due/queued incoming shipment is maintained at a time.

The game does not accumulate an invisible queue of multiple trucks while the receiving area is blocked.

This is a provisional simplification.

20. Incoming truck behavior

A non-empty shipment physically arrives by truck.

The truck carries:

physical resource crates;

arriving people.

The truck stops at the active Deliverables Area.

People and resources behave differently.

The truck remains until:

every arriving person has disembarked; and

every resource crate has physically left truck custody.

Crates may leave the truck through:

manual player unloading;

Hauler unloading.

Once empty, the truck departs.

No delivered resource is credited merely because the truck reached the map.

21. Deliverables full while truck is present

If all usable Deliverables crate positions are occupied and no Storage destination currently permits direct hauling:

additional crates remain on the truck;

the truck remains;

the player sees:

Delivery waiting — receiving/storage space required.

Nothing is discarded.

A later shipment cannot enter until the active truck clears.

This creates a visible logistics consequence for insufficient receiving/storage space.

22. People arriving

People unload themselves automatically.

The player never manually carries or unloads a person.

After disembarking, an unassigned person seeks available Barracks space.

People are persistent individuals.

They do not become abstract labor points.

23. Barracks behavior for this capability

Barracks is a player-created zone representing the waiting/muster location for unassigned logistics personnel.

For this first playable version:

1 Barracks tile supports 1 unassigned waiting person.

This is a provisional waiting-space rule, not a final housing/bed system.

A person with valid Barracks space moves there after arrival.

No Barracks

A shipment containing people is still allowed even if the player has not created Barracks.

After disembarking, those people remain near the Deliverables/muster area with status:

Unassigned — No Barracks

They do not disappear and do not block the resource quantities on the truck.

When Barracks space later becomes available, they move there automatically.

Barracks full

Additional unassigned people wait with:

Unassigned — Barracks Full

When a tile frees, a waiting person claims available space and moves there.

Barracks cleared underneath a person

The person remains physically present.

They seek another valid Barracks tile.

If none exists, their status becomes:

Unassigned — No Barracks

24. Tasks interface for this capability

The Logistics Terminal Tasks tab displays every current logistics person with:

name;

current duty;

current activity/status.

For this capability, available duties are:

Unassigned

Hauling

Workshop Duty becomes available with the workshop-production capability.

Send to HQ becomes active with the outgoing-personnel capability.

Do not clutter the current interface with controls that have no playable effect yet.

25. Hauling duty

Hauling is a persistent duty assignment.

Assigning a person to Hauling means they autonomously perform valid material-movement work while such work exists.

The player does not select each individual crate for the worker.

The player controls labor allocation.

The worker controls execution.

For this capability, valid Hauling work includes:

removing resource crates from an incoming truck;

moving delivered crates into Storage;

moving other loose raw-resource crates into Storage.

Completed workshop-output hauling is added later.

26. Hauler information

A Hauler may use information appropriate to visible logistics work in the protected rear:

location of incoming shipment;

physical loose resource crates;

resource type/quantity;

existing Storage zones;

stored crate type/quantity;

free Storage tiles;

whether a destination is reachable.

This is not hidden battlefield information.

Haulers do not know or act on military truth.

27. Hauler priority

When available, a Hauler resolves work in this order:

Priority 1 — Free an active incoming truck

If an incoming truck still carries a resource crate and a valid Storage destination exists, the Hauler prioritizes unloading that cargo.

This prevents a truck from occupying the receiving point unnecessarily.

Priority 2 — Clear Deliverables

If no truck cargo can currently be moved, the Hauler moves Unstored resource crates from Deliverables into Storage.

Priority 3 — Other loose raw resources

If the truck and Deliverables are clear, the Hauler may move other eligible loose Wood, Metal, or Cloth crates into Storage.

A Hauler does not invent work when none exists.

They remain idle/available.

28. Hauler destination preference

For the carried resource:

use reachable compatible partial stack space;

then use reachable empty Storage space.

The Hauler does not place goods into a different resource's occupied tile.

The Hauler does not exceed 10 units in a crate.

The Hauler does not create invisible overflow.

29. Hauler physical behavior

A Hauler must physically:

travel to the resource;

acquire the crate;

travel to the destination;

place/merge the resource.

Hauling is not an instantaneous inventory transfer.

For this capability, one Hauler carries one crate at a time.

If a carried crate is partially merged and material remains, the Hauler continues seeking Storage for the physical remainder.

30. Assignment changes while hauling

If the player changes a Hauler to Unassigned while that person is carrying a crate:

the person completes the current safe placement/return of that crate;

then stops accepting new hauling work.

They do not drop or delete the resource merely because their duty changed.

This same principle should be reused when later duties compete for a person's labor.

31. Blocked hauling

A Hauler must never teleport a crate to overcome a problem.

Possible blocked states include:

No Storage Space

No Reachable Storage

Incoming Cargo Waiting

Path Blocked

When the blocking condition changes, the Hauler re-evaluates automatically.

The player should not have to repeatedly toggle the worker's duty to wake them up.

32. Player interference with Hauler work

If the player takes a crate that a Hauler intended to move:

the Hauler does not duplicate or reserve an invisible copy;

that planned haul is abandoned;

the Hauler chooses another valid job.

If the player changes Storage while a Hauler is travelling:

the Hauler uses another valid destination if possible;

otherwise follows the blocked-carry behavior defined above.

33. Hauler idle behavior

A Hauler with no valid work does not pace randomly around the logistics area.

For this playable version:

if valid Barracks space is available, an idle Hauler may return to Barracks/muster;

otherwise they remain near their last completed logistics activity without blocking active work.

Idle behavior is presentation, not a new task-generation system.

34. Hauler Decision Graph v1.0

This graph is authoritative for the behavior defined in this package.

Assigned to Hauling?

→ NO
 Do not accept hauling jobs.

→ YES
 Currently carrying a crate?

 → YES
  Valid destination still exists?

  → YES
   Physically deliver/merge crate.

  → NO
   Another valid Storage destination exists?

   → YES
    Physically redirect to that destination.

   → NO
    Original pickup position can accept crate?

    → YES
     Return crate there.

    → NO
     Hold crate physically.
     Status: Blocked — No Storage Space.
     Re-evaluate when world state changes.

 → NO
  Active truck has movable cargo AND a valid Storage destination exists?

  → YES
   Unload truck cargo.

  → NO
   Deliverables contains movable Unstored resources AND valid Storage exists?

   → YES
    Move Deliverables resource.

   → NO
    Other loose raw resource has valid Storage?

    → YES
     Move loose resource.

    → NO
     Idle/available.

Explicit negative cases

A Hauler does not:

pick up cargo merely to discover there is nowhere to put it;

destroy excess material;

overfill a stack;

remotely move inventory;

move incompatible resources into occupied Storage;

create Storage themselves;

decide what resources the player should order;

interfere with military logistics.

35. Decision-impact matrix
Changed condition	Required Hauler reaction	Player-visible consequence
New truck arrives	Truck cargo becomes highest-priority valid haul work	Workers begin unloading if Storage exists
Storage gains empty tile	Previously blocked compatible haul becomes valid	Blocked worker/truck resumes
Storage becomes full	Do not begin impossible haul	Crates wait physically
Partial compatible stack appears	Use available stack capacity before empty tile	Storage consolidates
Player removes Storage destination	Retarget or recover carried crate	No disappearance/teleport
Player takes targeted crate	Abandon that job	No duplicate resource
Path becomes unavailable	Do not teleport	Blocked status until another path/destination exists
Hauling assignment removed	Finish current safe crate handling, then stop	No dropped/deleted cargo
New compatible loose crate appears	Becomes eligible work after higher priorities	Worker eventually stores it
No work exists	Idle	Worker remains available

Any future design adding:

storage filters;

priorities;

vehicles;

workshop outputs;

dispatch staging;

construction materials;

must explicitly update this matrix where those additions alter Hauler decisions.

36. Player-facing alerts

Alerts should identify actionable logistics problems without creating an elaborate management dashboard.

Required conditions:

Delivery Waiting

A truck cannot finish unloading because receiving/storage space is unavailable.

No Storage Space

Delivered/loose resources exist but no compatible Storage capacity exists.

No Barracks

At least one unassigned person lacks valid Barracks space.

Hauling Blocked

An assigned Hauler has work but no reachable valid destination.

Alerts disappear automatically when the condition stops being true.

Selecting an alert should bring the relevant world location or relevant terminal context into view when that interaction becomes available; the alert does not need a separate complex management screen.

37. Debug shipment control

The existing planned debug action:

Receive Raw Resources Shipment Immediately

may bypass the five-minute wait.

It must not bypass the actual world behavior being tested.

Using the debug action causes the current confirmed shipment to become due immediately.

The truck still physically arrives and resources still require real unloading and storage.

Debug truth must remain distinguishable from normal player-facing behavior.

The separate Send Shipment to HQ Immediately debug function belongs to the outgoing military-dispatch capability and is not part of this package.

38. Important edge cases
No Deliverables Area before ordering

Non-empty order cannot be confirmed.

Nothing is charged or lost.

Deliverables removed after order is confirmed but before arrival

Truck waits at incoming access.

Alert:

Delivery Waiting — Restore Deliverables Area

Restoring a valid Deliverables Area permits arrival.

Deliverables too small

Truck unloads only what can physically leave truck custody.

Remaining crates stay on truck.

No Storage

Resources may still be manually unloaded into available Deliverables space.

Once receiving space is full, remaining cargo stays on truck.

Storage fills while several Haulers work

Only material for which valid physical capacity still exists may be deposited.

Others retarget or block according to the carrying rule.

No two workers may cause the same storage capacity to be consumed twice.

Partial stack + oversized remainder

Fill the partial stack to 10.

Remainder stays physical and seeks further Storage.

Storage removed beneath crate

Crate becomes Unstored; resource quantity unchanged.

Different resource occupies target tile

No merge.

Person shipment but no Barracks

Person still disembarks and remains unassigned, visibly waiting.

Barracks fills

Additional people wait; no person disappears.

Player never assigns a Hauler

Player can still operate the physical resource loop manually.

The game is slower but not deadlocked solely because no worker has been assigned.

Player does nothing with truck cargo

Truck continues waiting.

It does not automatically convert cargo into inventory.

Empty order

No truck is spawned. Carryover and shipment timing proceed according to the explicit empty-order rule.

Order Last Shipment exceeds current budget

Draft is copied.

Confirmation remains unavailable until edited into budget.

39. UI boundaries

The UI should remain deliberately simple.

World does the explanatory work where possible

The player should be able to see:

truck present;

crates on truck;

crates in Deliverables;

Hauler physically moving;

crate type;

crate quantity;

Storage occupancy;

people waiting in Barracks.

Terminal handles management decisions

Orders tab:

what comes in.

Tasks tab:

who performs logistics labor.

Zones Menu handles spatial organization

It should not be necessary to open a general logistics spreadsheet to understand why a crate is not being moved.

If a Hauler is blocked, the world state plus a short status should explain why.

40. Provisional rules

The following are intentionally provisional for Playable Version 0:

base shipment interval: 5 world minutes;

base shipment allocation: 20 points;

current item point costs;

one unresolved queued incoming shipment maximum;

10 units per resource crate;

one crate per Storage tile;

one waiting unassigned person per Barracks tile;

broad Storage accepts all three current raw resources;

Hauler priority described above.

Provisional means:

implement this exact behavior now;

it is valid design for the playable version;

it may later be replaced through a recorded design change.

It does not mean the developer chooses different behavior.

41. Explicit exclusions

This package does not define:

workshop construction;

workshop recipes;

Workshop Duty;

Dispatch Area behavior;

outbound military trucks;

sending personnel to HQ;

final worker skill systems;

storage filters/priorities;

resource markets;

additional raw resources;

final names/content pool;

enemy rear logistics;

battlefield resupply;

final housing/needs;

save/load.

Those systems must respect the physical resources and people established here when they are added.

42. Observable acceptance scenario

Acceptance is based on the actual normal playable rear, not an isolated proof scene.

Scenario A — Establish first logistics operation

Start the scenario.

Verify the world initially contains only:

player;

logistics terminal;

empty usable logistics field;

incoming logistics access.

Player:

creates a valid Deliverables Area;

creates at least three Storage tiles;

creates Barracks;

opens the terminal;

orders:

12 Wood;

3 Metal;

1 Person.

Cost:

12 Wood = 12 points

3 Metal = 3 points

1 Person = 5 points

total = 20

Player confirms.

Expected:

first shipment becomes immediately eligible;

truck physically arrives;

person disembarks;

person travels to Barracks if space exists;

resource cargo remains physical;

Wood is represented as Wood 10 + Wood 2;

Metal is Metal 3.

Player may unload at least one crate manually.

Player assigns the arriving person to Hauling.

Expected Hauler behavior:

physically unload remaining truck cargo;

use compatible partial stacks before empty Storage;

truck departs only after cargo has physically left it.

Final resources must equal exactly:

Wood 12

Metal 3

distributed between physical stored crates according to stack rules.

No resource is created or lost.

43. Observable full-storage recovery

Before a subsequent Wood delivery, arrange Storage so that:

existing Wood partial stack has limited free capacity;

no empty Storage tile remains after that capacity is consumed.

Receive another Wood shipment.

Expected:

Hauler fills the compatible partial stack up to 10.

Remaining Wood stays physically outside Storage.

Worker/truck reports the relevant blocked condition.

No Wood disappears.

Player adds an empty Storage tile.

Blocked work resumes automatically.

remaining Wood enters the new Storage tile.

This is the required acceptance for the previously undefined partial-stack overflow/no-room case.

44. Shipment-cycle acceptance

Demonstrate:

first shipment does not wait five minutes;

next shipment uses five world minutes;

pause freezes the timer;

accepted acceleration advances world time consistently;

unconfirmed due shipment waits for confirmation rather than being lost;

carried points are computed exactly;

Order Last Shipment copies but does not confirm;

an over-budget copied order cannot be confirmed;

empty order resolves without spawning an empty truck.

45. AI acceptance

A Hauler must visibly demonstrate:

idle → valid truck job → physical pickup → travel → partial/full storage decision → physical deposit → next job/idle

Also demonstrate:

valid haul → storage becomes unavailable → no teleport/loss → blocked/retargeted behavior → player creates capacity → autonomous recovery

Acceptance is behavioral.

Tests may support these observations, but passing internal assertions does not replace the normal-session demonstration.

46. Evidence expected from developer

Engineering should mechanically verify the capability.

Useful evidence includes:

one normal-session recording covering Scenario A;

one normal-session recording or continuation covering full-storage recovery;

resource accounting before/after each physical transfer;

point/carryover examples;

pause/time-control behavior;

a focused automated check for:

stack capacity;

partial overflow;

no-space preservation;

no duplication;

shipment budget;

Hauler recovery.

The quantity of assertions is not an acceptance criterion.

The observable playable behavior is.

No Dawson playtest is requested at this capability boundary.

47. Design history
PV0-R01-D01 — Storage overflow

Decision: Fill existing compatible stack to 10; remainder remains physical and seeks additional Storage.

Reason: Prevents resource loss while making Storage capacity meaningful.

Source gap resolved: Dawson's original scenario explicitly left partial-stack overflow unspecified.

PV0-R01-D02 — No Storage space

Decision: Cargo waits physically; Haulers block rather than deleting, teleporting, or inventing storage.

Reason: Trencho treats resources as physical objects and logistics bottlenecks should be legible.

PV0-R01-D03 — Incoming truck persistence

Decision: Truck remains until its physical cargo has been removed.

Reason: Delivery capacity should have a visible consequence.

PV0-R01-D04 — Hauler job priority

Decision: Active incoming truck → Deliverables → other loose raw resources.

Reason: Frees constrained delivery access first and produces understandable worker behavior.

PV0-R01-D05 — Empty shipment

Decision: A zero-content order resolves without an empty truck and still uses the defined carryover rule.

Reason: Preserves the point-budget choice without meaningless vehicle traffic.

PV0-R01-D06 — Barracks shortage

Decision: People still disembark and physically wait; they are never discarded because housing/muster capacity is missing.

Reason: People are persistent physical entities.

PV0-R01-D07 — Provisional values

Decision: Existing shipment/stack values remain authoritative for PV0 until deliberately revised.

Reason: Playable known behavior is preferable to leaving implementation gaps.

48. Future compatibility obligation

Any later feature that changes:

what can be stored;

how a Hauler chooses work;

where delivery cargo may go;

how people are assigned;

how production outputs are moved;

must explicitly state how this package's behavior changes.

Do not silently append a new job type to Hauling without updating its written behavior and decision matrix.

If the developer encounters a player-facing or AI-behavior case not settled here, they should route the ambiguity back to the Game Designer rather than selecting a product rule themselves.
