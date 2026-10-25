Trencho Playable Version 0
Military Logistics 01 — HQ-to-Company Resupply, Local Handoff & Combat Endurance

Date: 24 October 2026
Status: Design complete for implementation handoff
Authority: Trencho Game Designer under Dawson's direction
Dependencies: Accepted #17, #21, #22, #23 and #24
Reconciles: #15 / T3-LOG-044
Parent design: GDD v1.1, Connected Slice locality amendments, Playable Version 0 Rear Foundations 01–03

1. Player outcome

This capability completes the first end-to-end ammunition consequence in the playable version.

The player:

acquires physical raw material;

produces physical Rifle Ammunition;

stages it in Dispatch;

sends it by physical rear truck;

watches it enter Friendly HQ Military Stores.

From that point onward, the military acts autonomously.

When legitimate battlefield reporting establishes an ammunition shortage:

Company requests supply;

the Commander/HQ logistics function responds according to actual HQ stock;

physical Ammo Crates leave HQ;

a military resupply truck carries them to Company staging;

Company legitimately learns the stock has arrived;

the accepted command hierarchy orders a depleted Squad to rendezvous;

eligible infantry physically enter the accepted 4 m issue locality;

ammunition is handed to those people;

the Squad resumes its preserved mission;

the delivered ammunition is later expended by actual autonomous firing.

The player never chooses the recipient, Squad, route or firing action.

2. Authoritative ammunition chain

For PV0, the authoritative friendly Rifle Ammunition chain is:

raw resource
→ rear Storage
→ Ammunition Workshop
→ Ammo Crate 8
→ Dispatch
→ rear outbound truck
→ Friendly HQ Military Stores
→ military supply request
→ HQ allocation
→ military resupply truck
→ Company staging
→ autonomous Squad rendezvous
→ local individual handoff
→ individual carried ammunition
→ actual firing

Every transfer changes physical custody exactly once.

3. Superseded prototype path

The earlier bounded prototype path that sent ammunition directly from the old rear supply model to Company staging is no longer the playable-version source of ammunition.

It remains historical implementation/design evidence.

PV0 acceptance must begin from ammunition that actually exists in Friendly HQ Military Stores through the accepted Rear Foundations 01–03 chain.

Do not grant Company staging stock from the retired prototype rear.

4. Rules preserved without change

The following accepted rules remain authoritative:

Company staging issue locality: 4.0 design meters.

That 4 m locality is a PV0/connected-slice rule, not a conversion of the legacy 70-pixel proof radius.

Each person's scenario-start carried compatible ammunition is snapshotted as their replenishment target.

Replenishment target is not final carrying capacity.

A person authored with zero starting ammunition has target 0.

Dead, inactive, enemy, incompatible, zero-target, full-target and non-local people cannot receive ammunition.

Company decides which subordinate Platoon should rendezvous.

Platoon selects the eligible Squad with greatest aggregate serviceable deficit.

Deterministic stable-ID tie resolution applies.

Squad Leader uses the accepted sector-native movement authority.

Infantry physically execute.

Prior operational intent is suspended and later resumed.

No player tactical command is introduced.

5. Serviceable ammunition deficit

A person's serviceable Rifle Ammunition deficit is:

max(0, replenishment target - current compatible carried ammunition)

but only while that person is:

living;

active;

friendly;

compatible;

positive-target.

A Squad's serviceable deficit is the sum of those individual deficits.

A Platoon's serviceable deficit is the sum of its eligible Squads.

Company serviceable deficit is the sum of the latest legitimately received subordinate readiness values.

Dead, zero-target or incompatible people do not contribute.

6. Readiness information

Subordinate readiness reporting must derive its ammunition condition from actual individual inventories.

The report available upward includes enough information to establish:

reporting formation identity;

active eligible rifle personnel count;

aggregate compatible rounds currently carried;

aggregate serviceable deficit;

report world timestamp.

The Company acts on the latest received report.

It does not inspect hidden future/current subordinate truth between reports.

7. Company staging information

Company may act only on staging stock information it has legitimately received through the accepted side-owned logistics-status path.

Physical arrival at staging and Company knowledge of that arrival remain separate events.

Company knowledge includes:

compatible rounds physically staged;

rounds currently known inbound under an active request;

status timestamp;

issue-point identity.

8. When Company may form a request

Company evaluates supply need when it receives relevant new information, including:

subordinate readiness;

staging-stock status;

inbound-request status.

It does not perform an omniscient every-frame inventory scan.

Define:

known supply gap = received serviceable deficit - known staging rounds - known inbound rounds

If:

known supply gap > 0; and

there is no active Rifle Ammunition request;

Company creates one Rifle Ammunition resupply request.

9. Request quantity

Ammo Crates contain 8 rounds.

Company requests:

ceil(known supply gap / 8) crates

with a maximum of:

4 crates per request

Therefore a single request represents between:

8 and 32 rounds

This is a provisional PV0 batching rule.

If deficit remains after the delivery/distribution cycle, later received readiness may justify another distinct request.

10. One active Company request

Company may have only:

one active Rifle Ammunition resupply request

at a time.

Additional readiness reports update Company knowledge but do not create duplicate parallel requests.

A later request requires the previous request to reach a terminal state.

11. Request context

A request contains player-relevant behavioral context:

friendly side;

requesting Company;

ammunition category;

requested crate count;

rounds represented;

received readiness/report timestamp that caused the request;

request world timestamp.

The request does not select an individual recipient.

It does not select a Squad.

12. Request route

Company sends the request upward through the accepted command/information hierarchy.

For PV0:

Company → Commander

uses the accepted adjacent-echelon message behavior.

Send time and receive time remain distinct.

The HQ logistics decision cannot occur before the request is received.

13. HQ stock knowledge

The Commander/HQ logistics function knows Friendly HQ Military Stores only through friendly HQ logistics status.

HQ stock is classified as:

Available

Committed to Military Resupply

Loading / Truck

no longer at HQ after physical departure.

Committed stock is not available for a second request.

14. Commander/HQ allocation rule

PV0 has one friendly Company, so there is no multi-Company prioritization problem yet.

When a valid Company request is received:

If no compatible Ammo Crate is available

Request becomes:

Waiting for HQ Stock

No military truck cargo is created.

If one or more compatible crates are available

Allocate:

min(requested crates, available HQ crates, 4)

specific physical Ammo Crates.

Those exact crates become:

Committed to Military Resupply

Partial fulfillment is permitted.

There is no invisible backorder for the unallocated portion.

If the Company still needs ammunition after the resulting cycle, later readiness may create another request.

15. HQ stock arriving while a request waits

A request in Waiting for HQ Stock remains active.

When new compatible ammunition physically enters HQ Military Stores and that changed stock becomes available to the HQ logistics decision:

the waiting request is reconsidered automatically;

available physical crates may be committed according to the same allocation rule.

The player does not need to re-submit anything.

16. Pre-loading request cancellation

Before any committed request cargo begins physical loading onto the military resupply truck, Company may cancel its request if newly received readiness/status establishes:

known supply gap <= 0

Cancellation:

releases committed crates back to Available HQ stock;

closes that request as Cancelled — Need Resolved.

This prevents unnecessary shipment when the need disappears before physical movement begins.

17. No cancellation after loading starts

Once the first committed crate begins loading onto the military resupply truck:

the shipment completes;

casualties, new readiness or changing demand do not teleport that cargo back to HQ.

If the original recipients no longer need it, the ammunition still reaches Company staging and remains legitimate future Company stock.

18. Military resupply truck

Friendly HQ has one autonomous military resupply truck for HQ→Company movement.

It is separate from the rear→HQ outbound truck.

PV0 capacity:

4 Ammo Crates

No personnel ride this military supply vehicle in this capability.

19. Military truck loading

HQ loading is automatic.

Each committed Ammo Crate requires:

1 active world second

to load.

At completion of each crate's load:

its custody leaves HQ Military Stores;

it enters military resupply truck custody.

The physical crate identity remains unchanged.

20. Truck unavailable

If the military resupply truck is away or returning:

committed HQ crates remain physically at HQ;

they remain unavailable for other requests;

request status becomes Awaiting Military Truck.

When the truck returns, loading begins automatically if the request remains valid and uncancelled.

21. Fixed PV0 military supply corridor

PV0 uses one authored friendly military logistics connection:

Friendly HQ Logistics Receiver → Company staging

The endpoint is the authoritative Company staging/issue point already used by the accepted rendezvous behavior.

This corridor is stable for the PV0 reference scenario.

It does not use legacy proof coordinates.

It does not establish final procedural logistics rules.

22. Military supply travel

Normal one-way HQ→Company staging transit:

15 world seconds

Return trip:

15 world seconds

This is provisional PV0 pacing.

The truck is normally observable travelling the friendly logistics corridor.

23. Current military route safety

For this capability the HQ→Company route is not subject to:

enemy interdiction;

mines;

road destruction;

truck destruction;

alternate-route selection;

convoy combat.

Those are future logistics/combat systems.

A valid departed truck therefore reaches Company staging unless simulation is paused.

24. Shared clock

Military loading, truck travel, unloading, handoff and combat use the same world clock.

Pause freezes all.

Accepted acceleration advances all consistently.

View switching does not reset, stop or accelerate logistics separately.

25. Company staging arrival

At Company staging, the military truck automatically unloads its committed Ammo Crates.

Each crate requires:

1 world second

to unload.

Only when an unload completes:

truck custody decreases by that exact crate;

Company staging custody gains exactly 8 rounds represented by that crate.

Truck arrival by itself grants no staging ammunition.

26. Staging status publication

Each material change to Company staging publishes an updated friendly logistics status through the accepted information path.

Company may not initiate the resupply rendezvous merely because the physical truck arrived.

It must receive legitimate staging-stock knowledge.

27. Request completion

A Company request reaches:

Delivered to Staging

when its authorized physical cargo has completed unloading.

It reaches:

Closed

when Company receives the corresponding staging receipt/status.

Only then may Company create another active request.

The military truck may already be physically returning while Company processes the received status.

28. Military truck return

After unloading all allocated crates:

truck returns automatically to HQ;

it carries no return cargo;

it becomes available for another request after physically reaching HQ.

29. Rendezvous trigger

After Company legitimately knows:

at least one compatible round is at staging; and

received subordinate readiness still contains a serviceable deficit;

the accepted #21 autonomous rendezvous behavior becomes eligible.

The player does not trigger it.

30. Company rendezvous selection

Company selects one subordinate Platoon with a currently received positive serviceable deficit.

If multiple are equivalent, use stable formation ID tie resolution.

The Company does not select an individual soldier.

31. Platoon Squad selection

The selected Platoon chooses the eligible active Squad with the:

greatest aggregate serviceable ammunition deficit

Stable Squad ID resolves ties.

This preserves the accepted #21 responsibility split.

32. Embodied leadership requirement

A living/available embodied Platoon/Squad leadership path remains required for the tactical rendezvous behavior already accepted.

If the necessary physical leader cannot perform their role:

staging stock remains physical;

no fake Squad order is emitted;

no person teleports;

no handoff occurs.

Company/rendezvous status becomes:

Rendezvous Delayed — Leadership Unavailable

The shortage may still have legitimately caused an HQ shipment.

That does not authorize a dead leader to perform tactical movement.

33. Default-scenario consequence

If the existing default reference battle still kills the relevant Platoon Leader before the rendezvous order can be embodied:

that is a valid default outcome.

The correct result is:

ammunition may reach Company staging;

rendezvous remains delayed;

no local transfer is fabricated.

This task does not claim the default combat state naturally completes the full resupply loop.

34. Suspended operational intent

When a Squad is legitimately selected for resupply:

its current operational intent is preserved;

the resupply movement temporarily suspends execution of that intent;

the accepted rendezvous state progresses through:

ORDERED → EN_ROUTE → AT_STAGING / WAITING

Only the selected Squad changes intent for this resupply event.

Other Squads continue existing behavior unless separately changed through legitimate command decisions.

35. Physical locality

Local ammunition handoff may occur only while an eligible recipient's authoritative position is:

within 4.0 design meters

of the Company staging issue point.

No 4 m requirement is waived because the recipient needs ammunition.

No remote refill exists.

36. Recipient eligibility

A recipient must be:

living;

active;

friendly;

part of the selected resupply Squad;

compatible with Rifle Ammunition;

positive replenishment target;

below that target;

physically inside 4 m.

Otherwise they receive nothing.

37. Individual issue priority

Within the selected Squad, local eligible recipients are served in this order:

greatest positive individual serviceable deficit;

stable person ID for ties.

This rule is re-evaluated before each individual handoff.

38. Handoff time

Each individual ammunition issue requires:

1 active world second

of uninterrupted local handoff.

The person must remain eligible and inside the 4 m locality for that second.

If eligibility or locality is lost before completion:

no ammunition transfers;

staging quantity remains unchanged;

the next valid local recipient may be considered.

39. Handoff quantity

At successful completion:

transfer = min(individual deficit, staging rounds)

Exactly that quantity:

leaves Company staging;

enters that person's compatible carried ammunition.

No transfer may exceed the scenario-start replenishment target.

40. Physical conservation

For every handoff:

staging decrease = recipient increase

There is no intermediate duplicate ammunition.

Spent rounds remain represented through the existing firing expenditure/accounting behavior.

41. Local negative cases

No ammunition is transferred to:

dead personnel;

inactive personnel;

enemies;

incompatible weapons;

zero-target leaders/personnel;

people already at or above target;

people beyond 4 m;

people in another Squad merely because they are closer.

42. Squad arrives but has no valid recipients

If the selected Squad reaches staging but no member remains locally eligible:

no handoff occurs;

staging stock remains;

rendezvous closes as No Eligible Recipient;

the Squad resumes its preserved intent through the normal hierarchy.

Fresh later readiness may cause another legitimate selection.

43. Staging stock exhausted mid-rendezvous

If staging reaches zero while the selected Squad still has serviceable deficit:

no further transfer occurs;

event closes as Stock Exhausted;

Squad resumes preserved intent;

later received readiness may justify another HQ request.

The Squad does not wait indefinitely for stock that does not exist.

44. Squad replenished with stock remaining

If the selected Squad no longer has a positive serviceable deficit but staging still contains ammunition:

current rendezvous completes successfully;

remaining staging ammunition stays in Company custody;

Squad resumes its preserved intent.

Company may later initiate another rendezvous for a different legitimately known shortage without requiring a new HQ shipment.

45. Resupply completion

A successful current rendezvous completes when:

selected Squad has no positive serviceable deficit that can be serviced by the current event; or

current event reaches a defined terminal state such as Stock Exhausted / No Eligible Recipient.

Completion releases the selected Squad back to its preserved operational intent through the accepted command/execution path.

46. Continued combat

After resupply completion:

the Squad receives no special firing command;

it resumes normal autonomous behavior;

delivered rounds become ordinary carried ammunition;

actual existing combat behavior determines whether and when they are fired.

The resupply system may not manufacture shots merely to prove consequence.

47. Subsequent readiness

Actual later firing changes individual ammunition.

Those changes flow upward through normal readiness reporting.

Company therefore learns later shortages only when reports arrive.

It does not remember an old deficit as though it were current truth.

48. New request after an incomplete deficit

If a completed HQ delivery/local distribution leaves a remaining serviceable deficit:

a new received readiness report may justify a new distinct Company request after the prior request has closed.

No stale request automatically regenerates itself.

49. Repeated-cycle acceptance rule

In addition to ordinary behavior, deterministic acceptance must demonstrate at least:

two complete distinct resupply cycles in which actual firing occurs between the cycles.

Required acceptance sequence:

Cycle 1

actual firing
→ received readiness shortage
→ Company request A
→ Commander/HQ allocation A
→ physical military truck A
→ Company staging receipt A
→ autonomous rendezvous A
→ local handoff A
→ Squad resumes
→ actual expenditure of delivered ammunition

Cycle 2

After Cycle 1 is closed:

later actual firing
→ new received readiness shortage
→ new Company request B
→ new allocation/cargo identity B
→ new physical supply movement
→ new staging receipt
→ new rendezvous/handoff
→ later actual expenditure

Request B may not be a stale continuation of request A.

50. Supply-enabled A/B acceptance

Use the same deterministic combat conditions and equal world time.

Supply-enabled case

Compatible ammunition is genuinely:

produced → dispatched → delivered to HQ → requested → physically moved to staging → handed off → fired

Control case

The same combat begins without compatible ammunition available in Friendly HQ Military Stores for the request.

Expected:

Company may legitimately request supply;

request waits Waiting for HQ Stock;

no military cargo is manufactured;

no staging refill occurs;

no person-level handoff occurs.

The supplied case must demonstrate materially greater legitimate ammunition endurance, such as additional shots after the control force has exhausted corresponding carried supply.

The two cases may differ in logistics availability.

They may not differ through player battlefield commands.

51. No direct player military resupply control

The player may influence military ammunition by:

acquiring resources;

producing ammunition;

staging it;

dispatching it to HQ.

After HQ receipt, the player does not select:

whether Company should request;

request quantity;

military supply truck departure;

Platoon;

Squad;

individual recipient;

resupply route;

firing action.

This preserves logistics authority without battlefield puppetry.

52. Player-visible friendly logistics information

The player may inspect friendly logistics states sufficient to understand causality.

HQ inspection

May show:

Available Rifle Ammunition crates/rounds;

Committed to Military Resupply crates/rounds;

current military supply request status;

military resupply truck state.

Company/staging friendly inspection

May show:

received request/status;

staged Rifle Ammunition;

last received staging update time;

rendezvous status.

Combat observation

Individual exact friendly inspection privilege remains as already designed.

No enemy inventory or rear logistics becomes visible.

53. Request statuses

Player-readable friendly request states:

Requested

In Transit to Commander

Waiting for HQ Stock

Authorized

Awaiting Military Truck

Loading at HQ

In Transit to Company

Unloading at Company

Delivered to Staging

Closed

Cancelled — Need Resolved

This status display communicates the chain without granting control over it.

54. Military truck statuses

Available at HQ

Loading

En Route to Company

Unloading

Returning

Available at HQ

55. Rendezvous statuses

Preserve accepted states and add terminal clarity:

Ordered

En Route

At Staging / Waiting

Issuing Ammunition

Resupplied

Stock Exhausted

No Eligible Recipient

Delayed — Leadership Unavailable

Resumed Prior Intent

56. Company Resupply Decision Graph v2.0

New readiness/logistics information received?

→ NO
Do not alter supply demand from hidden truth.

→ YES

Calculate received serviceable deficit, known staging and known inbound.

known supply gap > 0?

→ NO

if an active request has not started physical loading, cancel it as Need Resolved;

otherwise create no new request.

→ YES

Active request exists?

→ YES
Do not duplicate.

→ NO

Create request for:

min(4, ceil(gap / 8)) crates

Send to Commander.

After request closes:

received deficit still exceeds known staging/inbound on a later report?

→ YES
A new distinct request may form.

→ NO
No request.

57. Commander / HQ Logistics Decision Graph v1.0

Company request received?

→ NO
No allocation decision.

→ YES

Compatible Available HQ stock > 0?

→ NO
Request = Waiting for HQ Stock.

On later HQ stock update, reconsider.

→ YES

Allocate up to:

min(requested, available, 4 crates)

Commit exact crate identities.

Need resolved before loading starts?

→ YES
Release crates. Close Cancelled — Need Resolved.

→ NO

Military truck available?

→ YES
Load exact committed crates.

→ NO
Await Military Truck.

After first loading begins:

no cancellation;

shipment completes to Company staging.

58. Military Resupply Truck Decision Graph v1.0

Available at HQ

Authorized committed cargo exists?

→ NO: remain available.

→ YES: Loading

Loading

Load exact committed crates one at a time, 1 world second each.

All allocated crates aboard?

→ YES: En Route to Company

En Route

Travel authored corridor for 15 world seconds.

→ Unloading

Unloading

Unload exact crates one at a time, 1 world second each.

Truck empty?

→ YES: Returning

Returning

Travel 15 world seconds.

→ Available at HQ

No state grants staging stock before physical unloading.

59. Rendezvous & Handoff Decision Graph v2.0

Company has received positive staging stock AND received serviceable deficit?

→ NO
No rendezvous.

→ YES

Company selects eligible Platoon.

Required embodied leadership available?

→ NO
Delayed — Leadership Unavailable. Stock waits.

→ YES

Platoon selects greatest-deficit eligible Squad.

Save prior intent.

Send accepted hierarchical rendezvous intent.

Squad physically travels.

At least one eligible member reaches within 4 m?

→ NO
Continue legitimate movement/waiting; no transfer.

→ YES

Choose greatest individual deficit, stable ID tie.

Perform 1 world second local issue.

Revalidate.

Recipient still eligible/local?

→ NO: no transfer; choose next/re-evaluate.

→ YES: transfer min(deficit, staging).

Repeat until:

selected Squad serviceable deficit = 0 → Resupplied; or

staging = 0 → Stock Exhausted; or

no eligible local recipients → No Eligible Recipient.

Then resume preserved intent.

60. Leadership and focused acceptance setup

The existing normal default can legitimately prevent the rendezvous because the embodied Platoon Leader is killed before the order can be executed.

That is not repaired by bypassing leadership.

For deterministic full-chain acceptance, a focused representative setup is permitted under the same boundary previously accepted for #21.

It may alter opposing initial combat pressure before battle initialization to keep the relevant leadership path alive.

It must not:

inject HQ ammunition;

inject Company staging stock;

teleport the Squad;

grant ammunition;

skip requests;

skip the military truck;

bypass the command hierarchy;

directly set recipient inventory.

The supplied and control A/B cases must use the same focused combat setup.

61. Required default evidence

In addition to the focused full-chain proof, demonstrate that the original/default leadership-loss case still behaves correctly.

If the embodied leader is unavailable:

supply can still legitimately reach staging;

rendezvous delays;

stock remains staged;

no dead-person tactical action occurs;

no fake arrival or handoff occurs.

No claim of default full-loop completion is required.

62. Edge cases
Company deficit but HQ stock zero

Request waits. No truck departs.

HQ receives stock later

Waiting request re-evaluates automatically.

HQ has fewer crates than requested

Available crates are partially allocated. No hidden backorder.

Need resolves before physical loading

Request cancels and committed crates become available again.

Need changes after loading begins

Truck still completes delivery.

Military truck away

Authorized crates wait at HQ.

Staging already has enough known stock

Company does not create redundant request.

New readiness arrives while request active

Company updates knowledge but does not create a duplicate request.

Staging stock remains after one Squad resupplies

Stock remains for later legitimate rendezvous.

Selected Squad dies before arrival

No handoff. Company later responds to fresh readiness.

Recipient dies during one-second issue

No transfer completes to that recipient.

Recipient leaves 4 m during issue

No transfer completes.

Recipient reaches target during prior transfer

They are skipped on re-evaluation.

Staging empties during distribution

Event ends Stock Exhausted.

Zero-target armed leader is local

Receives nothing.

Compatible enemy enters locality

Receives nothing.

Pause during truck, rendezvous or handoff

All corresponding world-time activity freezes.

View switching

Does not alter logistics or combat outcome at equal world time.

63. Provisional PV0 choices

Authoritative for this capability:

maximum four Ammo Crates per Company request;

one active request at a time;

one military resupply truck;

four-crate military truck capacity;

15 world seconds HQ→Company;

15 world seconds Company→HQ return;

one second per HQ load;

one second per Company unload;

one second per individual local handoff;

safe military logistics corridor;

one Company, so no inter-Company allocation priority.

These are intentionally provisional and may later be replaced through recorded decisions.

64. Explicit exclusions

Do not add:

final carrying capacity;

magazines/reload redesign;

multiple Companies competing for stock;

multiple military supply vehicles;

convoy combat/interdiction;

alternate routes;

truck destruction;

player battlefield logistics commands;

enemy rear logistics;

enemy military resupply;

recruit formation assignment;

combat HQ destruction/defeat;

final comms failures;

final UI/art;

campaign/save expansion.

65. Observable Acceptance A — HQ-origin request and physical staging

Populate Friendly HQ Military Stores through the accepted normal PV0 rear chain.

Cause actual friendly firing to create a legitimate received serviceable deficit.

Demonstrate:

readiness report
→ Company request
→ Commander receives
→ physical HQ crates committed
→ military truck physically loads
→ 15-world-second normal travel
→ Company physical unload
→ staging stock increases only on unload
→ Company receives staging status

No prototype rear→staging grant may participate.

66. Observable Acceptance B — Rendezvous and handoff

Using an allowed focused representative combat setup if required:

Company legitimately knows staged stock and deficit;

accepted hierarchy selects the rendezvous;

one real Squad physically reaches staging;

at least one eligible depleted positive-target infantry member enters the 4 m locality;

one-second handoff occurs;

staging decreases exactly as person inventory increases;

no person exceeds replenishment target;

Squad resumes preserved intent.

67. Observable Acceptance C — Actual combat consequence

After handoff:

no player battlefield order is introduced;

resupplied individuals later legitimately fire delivered rounds.

Demonstrate the delivered rounds entering normal combat expenditure.

68. Observable Acceptance D — Two distinct cycles

Complete two fully accountable demand/resupply cycles.

The second must follow later actual ammunition expenditure after the first cycle has closed.

Require:

distinct request identities;

distinct allocation/cargo identities;

no stale Delivered/Closed state suppressing the second;

no duplicated stock;

actual expenditure between cycles.

69. Observable Acceptance E — Equal-time A/B endurance

Run equal-time deterministic supplied/control cases.

Supply-enabled:

real PV0 ammunition reaches HQ;

request, truck, staging, rendezvous and handoff occur.

Control:

no compatible HQ ammunition is available;

Company request waits legitimately.

Demonstrate a materially different firing/endurance result attributable to delivered ammunition.

No differing player battlefield commands.

70. Observable Acceptance F — Default leadership limitation

Run the unmodified/default relevant combat condition.

If the accepted default still kills the embodied Platoon Leader:

demonstrate:

request/delivery may occur;

staging stock remains;

rendezvous delays;

no dead-person agency;

no handoff;

no false claim of default loop completion.

71. Evidence expected from developer

Return normal/focused evidence sufficient to inspect:

actual PV0 HQ stock provenance;

readiness causality;

Company request;

Commander receipt;

exact HQ crate commitment;

military truck custody;

staging receipt;

staging knowledge provenance;

rendezvous hierarchy;

physical positions in design meters;

individual target/current/deficit;

exact handoff accounting;

resumed intent;

later shot expenditure;

two-cycle lifecycle;

supplied/control endurance difference;

default leadership-unavailable behavior;

pause/1x/accepted acceleration/view equivalence.

Automated checks support these behaviors but assertion quantity is not acceptance.

No Dawson mechanical QA is requested.

72. Design history
PV0-ML01-D01 — HQ becomes the sole PV0 military source

Decision: Company staging can no longer be filled directly from the prototype rear.

Reason: Rear Foundation 03 establishes real Friendly HQ custody; the playable chain must use it.

PV0-ML01-D02 — Autonomous Company demand

Decision: Actual received serviceable deficit, staging stock and inbound stock determine Company request behavior.

Reason: Logistics must react to legitimate command knowledge rather than hidden global truth.

PV0-ML01-D03 — Four-crate request cap

Decision: One request may allocate at most four Ammo Crates.

Reason: Provides bounded physical shipments without defining the final military transport scale.

PV0-ML01-D04 — Commander/HQ automatic allocation

Decision: With one Company, available compatible HQ stock is allocated automatically to the valid request.

Reason: There is no meaningful multi-formation prioritization choice yet and the player must not become battlefield quartermaster.

PV0-ML01-D05 — Physical military supply truck

Decision: HQ stock reaches Company staging through a distinct observable military vehicle.

Reason: HQ availability is not equivalent to Company custody.

PV0-ML01-D06 — One-second local issue

Decision: Recipient handoff requires one active world second inside the accepted 4 m locality.

Reason: Makes the final custody transfer physical and interruptible instead of an instantaneous radius refill.

PV0-ML01-D07 — Default leadership failure remains legitimate

Decision: Stock may reach staging while a dead/unavailable embodied leader prevents rendezvous execution.

Reason: Logistics availability must not override the accepted command embodiment rules.

PV0-ML01-D08 — Focused full-chain setup remains allowed

Decision: Deterministic combat pressure may be bounded before initialization to keep the required command actors alive.

Reason: Full-chain verification must not manufacture tactical agency or logistics stock merely because the current default encounter kills a required leader early.

73. Future compatibility obligation

Any later design adding:

additional Companies;

HQ capacity;

military truck loss;

road interdiction;

multiple ammunition categories;

alternate staging sites;

final carrying capacities;

communication failure;

must explicitly update the relevant request, allocation, transport, rendezvous and handoff decision graphs.

Engineering must return unresolved game-behavior ambiguity to the Game Designer rather than selecting product semantics.

## Active Request Cancellation Clarification — 24 October 2026

This amendment clarifies Sections 8, 16 and 56 of Playable Version 0 — Military Logistics 01: HQ-to-Company Resupply, Local Handoff & Combat Endurance.

1. Two distinct gap calculations
Request-formation gap

When no active Rifle Ammunition request exists:

request gap = latest received serviceable deficit - known staging rounds - known pre-existing inbound rounds

If:

request gap > 0

Company may create a request according to the existing crate-count rule.

At this point there is no current-request allocation yet.

Pre-loading cancellation gap

After a request has been created and HQ has authorized some or all of its cargo, cancellation uses:

cancellation gap = latest received serviceable deficit - known staging rounds - known other inbound rounds

Known other inbound rounds explicitly excludes every crate allocated to the current active request.

The current request's own authorized cargo must never mathematically cancel the request that caused that cargo to be authorized.

2. Cancellation rule

Before physical loading of the current request begins:

If

cancellation gap <= 0

then the need has been resolved independently of the current request.

The request is cancelled as:

Cancelled — Need Resolved

and every crate allocated to that request is released back to Available HQ stock.

If

cancellation gap > 0

the request remains valid.

Its own allocated cargo is not subtracted again for cancellation purposes.

3. What counts as "other inbound"

For this rule, other inbound means compatible ammunition that:

is not part of the current active request;

is legitimately known to be destined for this Company;

has not yet entered the Company's known staging stock.

Examples may include separately committed compatible supply from an earlier or independent legitimate supply movement if such a source exists.

The active request's own:

Authorized cargo;

Awaiting Military Truck cargo;

Loading-at-HQ cargo before the loading cutoff;

does not count as other inbound.

4. Partial allocation

Example:

Received serviceable deficit:

24 rounds

Known staging:

0

Known other inbound:

0

Company requests:

3 crates / 24 rounds

HQ currently has only:

2 crates / 16 rounds

HQ partially authorizes those two crates.

Cancellation calculation remains:

24 - 0 - 0 = 24

not:

24 - 0 - 16 = 8

and certainly not zero because of the current request's own cargo.

The two allocated crates therefore remain authorized.

The missing third crate is not maintained as a hidden backorder under the existing partial-fulfillment rule.

After this shipment/distribution cycle, later legitimate readiness may create a new request if need remains.

5. Other supply resolves the need

Example:

Received serviceable deficit:

16

Current request has already been authorized for:

2 crates / 16 rounds

but loading has not begun.

Company then legitimately receives knowledge that:

8 rounds are already at staging; and

a separate 8 compatible rounds are legitimately inbound.

Cancellation gap:

16 - 8 - 8 = 0

The current request is cancelled.

Its own allocated two crates are released to Available HQ stock.

They are not included in the cancellation calculation.

6. Updated readiness resolves the need

Example:

Current request is authorized but not yet loading.

A newer legitimately received readiness report establishes:

serviceable deficit = 0

Cancellation gap is therefore zero regardless of the current request's own allocation.

Cancel the request and release its committed crates.

This allows casualties, other replenishment, or other legitimate state changes to resolve the need before physical shipment begins.

7. Updated readiness reduces but does not eliminate need

If a newer received readiness report reduces the cancellation gap but leaves:

cancellation gap > 0

the current request remains authorized.

For PV0, its already authorized crate count is not dynamically resized downward.

Example:

Request authorized for 3 crates.

New legitimate information reduces unresolved need to 9 rounds.

Loading has not begun.

Because the independent need remains positive:

do not cancel;

keep the existing 3-crate authorization.

Any resulting excess that reaches Company staging remains legitimate Company stock.

Dynamic request resizing is not part of this capability.

8. Increased need after authorization

If a newer readiness report increases the deficit before loading:

do not automatically enlarge the current authorization;

preserve the already authorized cargo.

After the existing request completes and closes, later received readiness may justify another distinct request.

This preserves the one-active-request and no-hidden-backorder rules.

9. Stale information

Cancellation may use only the Company's currently accepted legitimate knowledge.

A later-received report/status whose source timestamp is older than the newer authoritative information already held for that same information stream must not roll Company knowledge backward for cancellation purposes.

Therefore an older readiness report must not:

resurrect a resolved deficit;

cancel a request based on obsolete staging state;

undo newer legitimate logistics knowledge.

This is an information-semantic requirement, not an instruction for technical implementation.

10. Loading-start cutoff

The cancellation window closes when:

the first crate belonging to the current request begins physical loading onto the military resupply truck.

Before that moment:

cancellation may occur under the rule above.

At or after that moment:

the request may no longer be cancelled;

all cargo already authorized for that request completes the shipment;

later readiness/staging/other-supply changes do not return cargo to HQ.

This cutoff applies even if the new information would otherwise make the cancellation gap zero or negative.

11. Loading-start boundary example

Request authorized for 2 crates.

Before loading:

cancellation gap = 8

Request remains valid.

First crate begins physical loading.

Immediately afterward, Company receives a new readiness report showing:

serviceable deficit = 0

Result:

do not cancel;

complete the authorized 2-crate shipment;

delivered ammunition becomes legitimate Company staging stock;

later demand calculations account for that stock normally.

No cargo reverses direction because battlefield need changed after physical loading began.

12. Authoritative Company cancellation decision

Replace the relevant branch in Company Resupply Decision Graph v2.0 with:

Active request exists and physical loading has NOT begun?

→ YES

Calculate:

cancellation gap = latest received serviceable deficit - known staging - known OTHER inbound

where OTHER inbound excludes this active request's own allocated cargo.

cancellation gap <= 0?

→ YES
Cancel request as Need Resolved.
Release all current-request allocated crates to Available HQ stock.

→ NO
Keep the current authorization unchanged.

Physical loading has begun?

→ YES
Cancellation is no longer permitted.
Complete the authorized shipment.

Design-history entry
PV0-ML01-D09 — Own allocation does not self-cancel

Decision: Cargo allocated to the current active request is excluded from that request's pre-loading cancellation calculation.

Reason: Authorization is the response to the identified supply need. Counting that same authorized cargo as an independent resolution of the need would allow a valid request to cancel itself before physical shipment begins.

Additional rule: Pre-loading cancellation occurs only when newer legitimate readiness, staging stock or other independent compatible inbound supply resolves the need.

Status: Authoritative PV0 behavior.

## Deterministic Two-Cycle Acceptance Scenario Amendment — 24 October 2026

This amendment replaces the focused-acceptance scenario boundary in Section 60 of Playable Version 0 — Military Logistics 01: HQ-to-Company Resupply, Local Handoff & Combat Endurance.

It does not change the normal/default playable battle.

1. Purpose

The previously accepted focused condition with enemy rifle ammunition authored to zero successfully preserved embodied friendly leadership, but it does not contain enough combat endurance demand.

Observed fact:

friendly forces fire approximately 45 actual shots;

all nine hostile targets are dead by world time 300;

normal friendly riflemen begin with substantially more ammunition than is required to finish that encounter.

That setup cannot demonstrate:

meaningful exhaustion caused by lack of supply;

two distinct later resupply cycles;

firing of ammunition delivered during both cycles;

materially greater supplied endurance than an unsupplied control.

A different deterministic acceptance scenario is therefore authorized.

2. Default scenario remains unchanged

Normal/default F5 combat initialization remains unchanged.

This amendment does not change its:

authored friendly starting ammunition;

enemy starting ammunition;

formation sizes;

objectives;

weapons;

damage;

movement;

suppression;

command behavior;

encounter outcome.

The focused scenario exists only for deterministic internal acceptance of the complete resupply chain.

Default behavior must still be separately checked for the accepted leadership-unavailable outcome.

3. Focused scenario — friendly authored ammunition

Before representative battle initialization and before replenishment-target snapshots are taken:

Selected Squad

Use the already accepted representative Squad:

P1-A

Its four ordinary compatible rifle infantry begin with:

2 Rifle Ammunition rounds each

Total selected-Squad starting ammunition:

8 rounds

All other friendly rifle users

Every other friendly person who would otherwise possess compatible Rifle Ammunition begins this focused scenario with:

0 compatible Rifle Ammunition rounds

This includes rifle personnel outside P1-A.

Existing leaders whose authored compatible starting load is already zero remain zero.

No compatible ammunition is granted to any friendly person after initialization except through the actual designed resupply chain.

4. Replenishment-target interaction

The existing replenishment-target rule is preserved exactly.

Targets are snapshotted from the focused scenario's authored starting loads.

Therefore:

P1-A ordinary rifle infantry

Each of the four selected infantry receives focused-scenario replenishment target:

2 rounds

Other friendly rifle personnel authored with zero

Their focused-scenario replenishment target is:

0 rounds

They are consequently ineligible for this resupply path.

This is intentional.

The focused scenario does not temporarily treat their normal 12-round load as a hidden capacity or target.

A P1-A rifleman may therefore be replenished only up to:

2 carried rounds

during any one rendezvous.

The normal/default scenario continues to snapshot its normal authored starting loads instead.

5. Why the low target is intentional

A lower target is desirable in this acceptance scenario.

The four selected infantry have a maximum aggregate serviceable deficit of:

8 rounds

when empty.

That produces a clean request requirement of:

1 Ammo Crate 8

rather than allowing the first Company-wide shortage to authorize a large shipment that could leave enough staging stock to suppress the second demand cycle.

The acceptance scenario therefore tests the existing target semantics rather than bypassing them.

6. Focused opposing force

Before battle initialization, the focused scenario contains:

32 ordinary hostile rifle infantry

using normal existing hostile combat behavior, movement, weapons, health, damage, suppression and targeting rules.

Their authored compatible rifle ammunition is:

0 rounds

They therefore provide persistent legitimate hostile targets without creating the enemy fire that previously killed the embodied friendly leadership required for the rendezvous.

Existing hostile command/objective behavior remains in place.

No hostile unit is:

invulnerable;

damage-modified;

accuracy-modified;

artificially immobilized;

spawned after initialization.

They are ordinary initialized combatants with zero starting rifle ammunition.

7. Friendly combat statistics remain normal

Except for the explicitly authored starting ammunition described above, the focused friendly force uses normal accepted gameplay values.

Do not change:

health;

weapon damage;

fire rate;

accuracy;

movement speed;

suppression;

AI decision rules;

command latency;

formation behavior;

target selection.

The acceptance scenario creates ammunition scarcity through initial load, not through altered weapon performance.

8. Positions, objectives and command hierarchy

The focused scenario preserves:

accepted friendly command hierarchy;

embodied Commander/Company/Platoon/Squad leadership;

accepted P1-A identity;

normal formation movement;

normal operational objective;

accepted rendezvous command path;

accepted Company staging point;

accepted 4.0 design-meter issue locality.

No actor may be moved into rendezvous position by scenario setup after initialization.

No resupply order is pre-created.

9. No post-initialization scenario assistance

After initialization, the focused scenario may not:

grant ammunition;

alter replenishment targets;

spawn replacement hostile targets;

inject requests;

mark requests fulfilled;

move the Squad;

move individual recipients;

move the military truck;

create staging stock;

change HQ stock;

force shots;

force hits;

force kills;

prevent legitimate AI movement;

prevent legitimate casualties through hidden protection.

All such behavior must arise from the real playable systems.

10. Supplied-case logistics

The supplied A/B case must use real Playable Version logistics.

At least:

2 physical Rifle Ammunition Crates 8

must reach Friendly HQ Military Stores through:

raw resources
→ rear production
→ Dispatch
→ rear outbound truck
→ physical HQ unloading

They may arrive after the first Company request has already entered Waiting for HQ Stock.

No acceptance advantage is obtained by injecting those crates at HQ.

11. Cycle 1 required sequence

P1-A begins with:

4 people × 2 rounds = 8 rounds

Those rounds must be expended through actual autonomous firing.

This creates an aggregate selected-Squad serviceable deficit of:

8 rounds

after legitimate reporting.

With no known Company staging/inbound stock, the corresponding request is:

1 Ammo Crate 8

The first distinct cycle must then demonstrate:

actual initial firing
→ received shortage
→ Request A
→ HQ allocation of one actual Ammo Crate 8
→ physical military truck
→ Company staging
→ accepted rendezvous
→ four-person local handoff up to target 2
→ P1-A resumes prior intent

When all four are empty and eligible, successful full service results in:

staging decrease: 8

aggregate P1-A inventory increase: 8

each person: 0 → 2

subject to actual eligibility at handoff time.

12. Firing between cycles

After Cycle 1 handoff, P1-A must actually expend the delivered ammunition through normal combat.

For deterministic acceptance, require that the Cycle 1 delivered rounds are exhausted sufficiently to re-establish:

8 rounds aggregate serviceable deficit

before Request B forms.

The intent is to produce a clean second one-crate shortage, not a partially overlapping stale demand.

No shot is forced.

The hostile force exists specifically so valid combat targets remain available.

13. Cycle 2 required sequence

After Cycle 1 request/rendezvous state has closed and later firing creates the new received 8-round deficit:

create a distinct:

Request B — 1 Ammo Crate 8

Request B must have:

a new request identity;

a distinct physical cargo identity;

its own allocation;

its own truck/staging accounting;

its own rendezvous/handoff event.

The second physical Ammo Crate may be the second crate already legitimately present in HQ Military Stores.

After the Cycle 2 handoff:

at least one round delivered by Cycle 2 must subsequently be fired through ordinary autonomous combat.

This proves that the second cycle is not merely inventory movement.

14. Required supplied-case endurance

The supplied case must therefore demonstrate at minimum:

8 initial P1-A rifle shots worth of available ammunition;

8 rounds received during Cycle 1 and later expended sufficiently to create Cycle 2;

at least one Cycle 2 delivered round later expended.

Thus the supplied Squad demonstrates legitimate combat activity beyond the ammunition that existed at initialization.

The acceptance metric should use actual compatible P1-A ammunition expenditure/shots, not hostile casualties alone.

15. Unsupplied control

The deterministic control uses the exact same focused combat initialization:

same seed;

same friendly starting loads;

same replenishment targets;

same 32 hostile infantry;

same hostile zero ammunition;

same positions;

same command hierarchy;

same objectives;

same gameplay statistics.

The difference is logistical availability:

no compatible Rifle Ammunition becomes Available in Friendly HQ Military Stores for the request.

When P1-A exhausts its eight initial rounds:

the legitimate shortage may be reported;

Company may create the request;

the request remains Waiting for HQ Stock;

no military resupply cargo is manufactured;

no Company staging increase occurs;

no local handoff occurs.

P1-A therefore cannot gain additional compatible ammunition through this resupply system.

16. A/B endurance comparison

The primary endurance comparison is:

actual P1-A compatible rifle ammunition expended / legitimate rifle shots over equal world time

not number of enemy deaths.

The supplied case must show materially greater legitimate firing because real delivered ammunition entered individual inventories.

The control case must remain limited by its eight authored starting rounds.

The supplied case must demonstrate ammunition expenditure from both Cycle 1 and Cycle 2.

No different player battlefield orders are permitted between cases.

17. Target persistence requirement

The 32 zero-ammunition hostile infantry are included so that the deterministic combat encounter still contains legitimate hostile targets while the two resupply cycles occur.

Acceptance requires:

at least one living hostile target remains available when the first Cycle 2-delivered round is fired.

If that condition does not occur, the focused scenario has failed its authored acceptance purpose and must be returned to the Game Designer rather than adding post-initialization targets or altering weapon statistics.

Do not silently modify the scenario during implementation.

18. Default leadership case remains separate

The focused two-cycle scenario does not replace the required default evidence.

The unmodified/default relevant battle condition must still demonstrate the established behavior when the embodied Platoon Leader dies before rendezvous execution:

supply may reach Company staging;

rendezvous remains delayed;

staged ammunition remains physical;

no dead-person command action occurs;

no fake movement or handoff occurs.

The focused scenario demonstrates the successful branch.

The default scenario demonstrates the legitimate leadership-blocked branch.

Both are required.

19. Allowed focused modifications — exhaustive list

For this deterministic acceptance scenario, the only combat-start modifications newly authorized are:

P1-A's four ordinary compatible rifle infantry start with 2 rounds each.

All other friendly compatible rifle personnel start with 0 rounds.

The hostile force contains 32 ordinary rifle infantry.

Those hostile rifle infantry start with 0 compatible rounds.

All four values are authored before battle initialization and before replenishment-target snapshotting.

No other gameplay-stat or post-initialization modification is authorized by this amendment.

Design-history entry
PV0-ML01-D10 — Ammunition-constrained deterministic acceptance scenario

Decision: Use one four-rifle Squad with 2 authored rounds per person, all other friendly rifle users at 0, against 32 ordinary hostile rifle infantry with 0 rifle ammunition.

Status: Acceptance-only focused scenario.

Reason: The prior zero-enemy-ammunition focused setup preserved leadership but ended after approximately 45 friendly shots, while normal friendly starting ammunition exceeded the encounter's total need. It could not demonstrate two distinct supply cycles or supplied-vs-control endurance.

Why not only lower all friendly loads: A Company-wide shortage could authorize enough ammunition in the first shipment to leave residual staging stock and suppress the required second request.

Why P1-A only has a positive target: It bounds each clean deficit at 8 rounds, producing one-crate requests and preserving the accepted target rule.

Why opposing force is enlarged: Legitimate targets must remain through firing after the second resupply cycle.

Preserved rules: 4 m locality, target snapshot semantics, embodied command, physical movement, real requests, physical cargo, local handoff and ordinary autonomous firing.

## Target-Aware Ammunition Readiness Amendment — 24 October 2026

This amendment resolves the deterministic-scenario HOLD deadlock discovered under the exact D10 focused scenario.

It refines the provisional CMD047 low-ammunition readiness rule for PV0.

It does not change command hierarchy, objectives, movement, firing, replenishment targets, locality, or the default encounter setup.

1. Problem resolved

The prior provisional Commander low-ammunition rule treated ammunition as low when:

compatible rounds <= 2 × active personnel

Under the focused D10 scenario:

P1-A has four positive-target rifle infantry carrying 2 rounds each;

every other friendly rifle user has a zero replenishment target;

hostile rifle personnel also begin with zero authored ammunition/zero target.

Counting all active personnel and treating equality as low causes global HOLD before opposing forces establish contact.

As a result:

no firing occurs;

no actual deficit develops;

no demand develops;

the focused scenario cannot exercise the intended supply loop.

This is not the desired meaning of ammunition readiness.

2. Serviceable rifle personnel for command readiness

For the PV0 Rifle Ammunition readiness channel, a person counts as a:

serviceable rifle user

only while all of the following are true:

living;

active;

friendly to the formation being reported;

compatible with Rifle Ammunition;

scenario-start replenishment target is greater than zero.

Personnel with replenishment target:

0

do not contribute either:

ammunition rounds; or

personnel count

to the Rifle Ammunition low-readiness calculation.

They are not interpreted as infinitely ammunition-starved rifle users.

3. Low-ammunition threshold

For a formation with at least one serviceable rifle user:

low-ammunition threshold = 2 rounds × number of serviceable rifle users

The formation is considered:

Low Rifle Ammunition

only when:

current compatible rounds carried by those serviceable rifle users < low-ammunition threshold

The comparison is strictly less than, not less-than-or-equal.

4. Exact threshold is not low

Example:

Four serviceable P1-A riflemen.

Each carries:

2 rounds

Aggregate:

8 rounds

Threshold:

2 × 4 = 8

Because:

8 < 8 is false,

P1-A is not Low Rifle Ammunition.

Its normal operational advance is therefore not held merely because it starts exactly at the provisional two-round-per-rifleman boundary.

After legitimate firing reduces aggregate ammunition below 8, later readiness may report Low Rifle Ammunition.

5. Formation with zero serviceable rifle users

If a formation currently has:

0 serviceable rifle users

the Rifle Ammunition low-readiness condition is:

Not Applicable

not:

Low Rifle Ammunition

Zero-target personnel therefore do not cause an ammunition-based HOLD.

This rule applies equally to friendly and enemy formations.

A force intentionally authored with zero replenishment-target rifle personnel may still:

execute its operational intent;

move;

observe;

react according to other valid AI conditions.

It simply has no serviceable Rifle Ammunition requirement represented by this readiness channel.

6. Effect on the focused D10 scenario

The D10 scenario remains exactly:

Friendly

P1-A:

four ordinary compatible rifle infantry;

2 authored Rifle Ammunition rounds each;

target 2 each.

All other friendly compatible rifle personnel:

0 authored Rifle Ammunition;

target 0.

Enemy

32 ordinary hostile rifle infantry;

0 authored Rifle Ammunition;

target 0.

No initial position, objective or AI change is authorized.

Expected initial command consequence:

P1-A begins at its exact non-low boundary;

zero-target friendly formations do not create false ammunition-low readiness;

zero-target hostile formations do not create false ammunition-low readiness;

both sides remain free to execute their ordinary operational intent until some other legitimate condition changes it;

ordinary movement therefore remains capable of establishing actual contact.

7. Low-ammunition HOLD after contact

A Commander decision to HOLD because of Low Rifle Ammunition means:

do not continue the ammunition-risking operational advance

It does not mean:

cease legitimate local combat against already observed/engageable enemies.

Once contact exists, subordinate tactical behavior may continue to:

observe;

hold position;

return fire;

engage valid known targets;

according to existing combat behavior.

No extra shots are granted and no target engagement is forced.

This distinction is authoritative.

8. Supply recovery and command intent

When newer legitimately received readiness establishes that the relevant formation is no longer Low Rifle Ammunition:

the ammunition-low HOLD reason clears.

If the previous operational intent remains otherwise valid:

normal hierarchy behavior may maintain/resume that intent.

Resupply does not automatically force an ADVANCE.

Other legitimate reasons to HOLD, adapt or delay remain authoritative.

9. Relationship to serviceable deficit

Two related but different concepts now exist.

Command low-ammunition readiness

Determines whether ammunition scarcity justifies higher-echelon caution:

current rounds < 2 × serviceable rifle users

Serviceable resupply deficit

Determines how many rounds may legitimately be restored:

replenishment target - current carried rounds

These must not be conflated.

Example:

A P1-A rifleman with target 2 and current 1:

contributes 1 round of serviceable deficit;

contributes to a Low Rifle Ammunition formation because aggregate ammunition is below the two-per-user readiness threshold.

After restoration to target 2:

their serviceable deficit is 0;

the focused Squad may clear the ammunition-low condition.

10. Normal/default gameplay

The normal/default scenario is not reauthored.

Its:

starting ammunition;

replenishment targets;

objectives;

positions;

enemy ammunition;

formation composition

remain unchanged.

This amendment changes only the semantics of the provisional ammunition-readiness calculation:

target-zero personnel are excluded;

equality with the two-round-per-serviceable-user threshold is not Low.

No default successful rendezvous is inferred.

The separately required default leadership-loss evidence remains unchanged.

11. Focused acceptance remains natural after initialization

After the focused scenario initializes:

no system may:

grant contact;

move forces into contact;

force ADVANCE;

suppress a legitimate HOLD;

force firing;

add targets;

change ammunition targets;

grant ammunition;

create demand;

create reports;

create requests;

move rendezvous participants.

The normal hierarchy, movement, perception and combat systems must produce those events.

If the amended exact scenario still cannot establish legitimate contact and satisfy the two-cycle acceptance purpose, return the factual blocker to the Game Designer.

Do not add another silent scenario exception.

Decision-graph amendment — Commander ammunition readiness

For received readiness pertaining to Rifle Ammunition:

serviceable rifle-user count > 0?

→ NO
Rifle-ammunition readiness = Not Applicable.
Do not issue or maintain ammunition-low HOLD for this reason.

→ YES

Calculate:

threshold = 2 × serviceable rifle-user count

and:

current = compatible rounds carried by those serviceable rifle users

current < threshold?

→ YES
Low Rifle Ammunition.
Commander may maintain/delay/adapt subordinate operational intent according to the accepted command decision behavior.

→ NO
Not Low Rifle Ammunition.
Do not maintain an ammunition-low HOLD for this reason.

When ammunition-low HOLD already exists and newer received readiness changes the answer to NO:

clear this HOLD reason and re-evaluate existing operational intent normally.

Design-history entry
PV0-ML01-D11 — Target-aware command ammunition readiness

Decision: The provisional two-round-per-person readiness rule counts only living, active, compatible personnel with positive scenario-start replenishment targets, and Low applies only below—not at—the two-round-per-serviceable-user threshold.

Reason: Zero-target personnel have no serviceable Rifle Ammunition requirement and must not force a global shortage state. A focused Squad authored exactly at two rounds per eligible rifleman must be able to execute normal intent long enough for real combat to create the shortage being tested.

Related clarification: Ammunition-low HOLD constrains continued operational advance but does not forbid ordinary local engagement of already observed valid enemies.

Effect on accepted CMD047: This deliberately refines only its explicitly provisional ammunition threshold. Echelon responsibilities, delayed information flow, report provenance and received-report-driven decisions remain unchanged.

Status: Authoritative PV0 behavior.

## Default Cancellation and Leadership Evidence Amendment — 24 October 2026

This amendment replaces the previous requirement that the unmodified default battle must necessarily demonstrate staged ammunition waiting behind an unavailable embodied leader.

1. Default acceptance follows legitimate causality

The unmodified default scenario must be accepted according to the actual sequence produced by the designed systems.

If:

actual combat creates a serviceable ammunition need;

Company legitimately requests ammunition;

the relevant depleted personnel subsequently die or otherwise cease contributing serviceable deficit;

newer legitimately received readiness reduces the independent cancellation gap to zero;

physical loading of that request has not begun;

then the correct result is:

Cancelled — Need Resolved

Any crates that have reached or later reach Friendly HQ remain or return:

Available in Friendly HQ Military Stores

They do not continue toward Company solely to create a resupply demonstration.

2. Correct default outcome for the observed case

For the reported unmodified default case:

normal friendly starting state remains unchanged;

the P1 Platoon Leader dies naturally;

depleted main-force personnel subsequently die;

latest legitimately received serviceable need resolves before normal rear-produced ammunition becomes available for military loading;

the request legitimately cancels under the authored pre-loading cancellation rule;

real Ammo Crates remain available at Friendly HQ;

Company staging remains 0;

no rendezvous begins;

no handoff occurs.

This is a successful default negative-path result.

It demonstrates that the logistics system does not ship ammunition merely because an old shortage once existed.

3. Do not count dead-person need

Dead/inactive personnel do not preserve a serviceable deficit simply to keep a request alive.

Do not:

retain their old deficit;

prevent legitimate cancellation;

accelerate HQ delivery;

fabricate staging stock;

force a rendezvous.

Latest legitimately received readiness governs Company knowledge.

4. No requirement for default Leadership Unavailable status

The default scenario is no longer required to reach:

Rendezvous Delayed — Leadership Unavailable

unless the actual prerequisites for a rendezvous legitimately coexist.

Specifically, that branch requires Company to legitimately know both:

positive compatible Company staging stock; and

a still-current serviceable subordinate deficit requiring rendezvous.

If the shortage resolves before those prerequisites exist, cancellation correctly prevents the leadership branch from being reached.

A branch not reached because its legitimate prerequisites disappeared is not a failure.

5. Leadership-unavailable behavior remains authoritative

The product rule itself remains unchanged:

If Company legitimately has:

received positive compatible staging stock;

received positive serviceable deficit;

but the embodied leadership required to execute the selected rendezvous is unavailable, then:

no fake subordinate order occurs;

no dead person exercises tactical agency;

no movement is fabricated;

no local handoff occurs;

staging ammunition remains physically present;

rendezvous state is:

Delayed — Leadership Unavailable

This remains a required negative branch.

6. Separate leadership branch guard

Because the unmodified default scenario may legitimately cancel before reaching this branch, #15 may verify Leadership Unavailable through a separate deterministic branch guard.

For this guard only, it is permissible to begin at the rendezvous decision boundary with the following explicit accepted preconditions already established:

Company has legitimately received knowledge of positive compatible staging stock;

Company has legitimately received a positive serviceable deficit;

the required embodied leader for the selected rendezvous is unavailable;

no valid rendezvous order has yet been executed.

The guard then verifies only the behavior from that decision boundary forward.

Expected result:

Delayed — Leadership Unavailable

with:

staging stock unchanged;

recipient inventories unchanged;

no fabricated movement;

no handoff;

no dead-person agency.

7. Fixture limitation

The branch guard above is deliberately not end-to-end logistics evidence.

It may not be cited as proof that:

ammunition was produced at the rear;

ammunition travelled rear→HQ;

HQ allocated it;

a military truck transported it;

Company staging received it physically.

Those claims must come from the full focused/end-to-end acceptance evidence.

The guard exists solely to prove the already accepted rendezvous negative branch when its preconditions are present.

Its staged-stock precondition is therefore an explicitly authorized branch fixture, not permission to inject staging stock into the normal/default or supplied two-cycle acceptance runs.

8. Full focused acceptance remains unchanged

The D10/D11 deterministic supplied/control scenario still must independently demonstrate:

real PV0 rear production;

real rear→HQ delivery;

real Company request;

real HQ allocation;

real military transport;

real Company staging;

autonomous rendezvous;

4 m local handoff;

actual later firing;

two distinct completed resupply cycles;

actual firing between cycles;

Cycle-B-delivered ammunition later fired;

equal-time supplied/control endurance difference.

No fixture staging, injected inventory or forced movement is permitted in that full-chain proof.

9. Evidence separation

#15 acceptance now has three explicitly different evidence classes.

A. Default normal scenario

Purpose:

prove truthful default negative-path behavior

Acceptable observed result:

need → request → need resolves before loading → cancellation → HQ stock retained → no staging/rendezvous/handoff

B. Focused D10/D11 end-to-end scenario

Purpose:

prove the complete successful two-cycle causal chain and supplied endurance consequence

No shortcut fixtures.

C. Leadership-unavailable branch guard

Purpose:

prove embodied leadership still gates rendezvous once valid staging+need prerequisites actually exist

May begin at the defined decision boundary.

Must not be represented as end-to-end logistics evidence.

Design-history entry
PV0-ML01-D12 — Default cancellation supersedes forced leadership demonstration

Decision: A legitimate pre-loading Need Resolved cancellation with ammunition retained at HQ satisfies the unmodified default negative-path requirement when serviceable demand disappears before military shipment.

Reason: Forcing cargo to Company after the need has legitimately resolved would contradict the accepted cancellation design merely to exercise a later branch.

Decision: Leadership Unavailable remains mandatory branch behavior but may be proven separately at its decision boundary.

Reason: The leadership rule is semantically independent of whether the current default encounter naturally preserves a live shortage long enough for stock and leadership failure to coexist.

Status: Authoritative PV0 acceptance boundary.

## Resupply Cycle Freshness and Concurrent Combat Amendment — 24 October 2026

This amendment resolves the observed overlap between:

request closure at Company staging;

an ongoing local rendezvous/handoff;

normal combat expenditure occurring during that handoff;

creation of the next distinct Rifle Ammunition demand cycle.

It supersedes any acceptance wording that requires Cycle B to arise merely because Request A has reached Closed.

1. Request lifecycle and resupply-cycle lifecycle are distinct

A Company Rifle Ammunition request and a Company Rifle Ammunition resupply cycle are not the same lifecycle.

The request may reach:

Closed

after its authorized cargo has physically arrived at staging and Company has received the corresponding staging status.

The broader resupply cycle remains active while that delivered ammunition is still being handled through its associated rendezvous.

For the same ammunition category, the cycle begins when Company creates the request and remains active until its associated distribution attempt reaches a defined terminal state.

2. One active Rifle Ammunition resupply cycle

Company may have only:

one active Rifle Ammunition resupply cycle

at a time.

This is stronger than merely having one active transport request.

While the cycle remains active:

Company may receive newer readiness reports;

Company may receive staging updates;

people may fire;

local handoffs may occur;

the military truck may already be returning;

but Company does not create another Rifle Ammunition request.

This prevents the same unresolved shortage from being divided into overlapping request identities merely because the transport portion closed before local distribution finished.

3. Cycle terminal states

A Rifle Ammunition resupply cycle becomes terminal when its current distribution attempt reaches one of:

Resupplied

Stock Exhausted

No Eligible Recipient

Cancelled — Need Resolved

Delivered to Staging and transport-request Closed are not cycle-terminal states.

Delayed — Leadership Unavailable is also not terminal while a legitimate deficit and staged stock remain.

4. Freshness requirement for the next cycle

After Cycle A becomes terminal, Cycle B may form only from a new legitimately received readiness report whose source timestamp is strictly later than Cycle A's terminal world time.

Therefore:

readiness source time <= previous cycle terminal time

cannot create the next same-category request.

The report may still update historical/display information, but it is not sufficiently fresh to establish a distinct post-cycle demand.

5. Observed premature Request B is not valid Cycle B

In the reported deterministic run:

readiness source time = 186.65;

Cycle A handoffs begin at 190.50;

Request B attempts to form at 191.50;

Cycle A becomes Stock Exhausted at approximately 193.57.

That 186.65 readiness sample predates Cycle A's local distribution.

It therefore describes the original shortage state.

Under this amendment it cannot create Request B.

Company must wait until Cycle A reaches its terminal state and then receive a readiness sample sourced after that terminal time.

6. Combat continues during handoff

The local resupply rendezvous does not impose a ceasefire.

If valid enemies are already engageable while infantry are inside the 4 m issue locality, ordinary combat behavior continues.

An eligible person may:

receive ammunition;

fire some or all of it through normal autonomous combat;

become deficient again before the current rendezvous has finished servicing other people.

This is legitimate.

No handoff rule suppresses normal firing merely to make accounting visually tidy.

7. Expenditure sufficient for a later cycle may occur during Cycle A

The phrase actual expenditure between cycles is clarified.

For Cycle B acceptance, ammunition delivered by Cycle A must have been legitimately expended after its local issue and before Request B is created.

That expenditure is allowed to occur while Cycle A's rendezvous is still active.

It does not have to occur after the exact terminal timestamp of Cycle A.

What must occur after Cycle A becomes terminal is the fresh readiness observation used to establish Cycle B.

Therefore the required causal ordering is:

Cycle A local handoff
→ actual firing of Cycle-A-delivered ammunition
→ Cycle A terminal state
→ new readiness sample sourced after that terminal state
→ Company receives that fresh readiness
→ Request B

This cleanly distinguishes a new demand cycle without imposing an artificial ceasefire.

8. Recipient selection remains dynamic

The existing individual issue rule remains authoritative:

Before each individual handoff, re-evaluate currently eligible local recipients and select:

greatest current positive serviceable deficit;

stable person ID for ties.

There is no once-per-person-per-rendezvous rule.

9. The same person may receive more than once

A person who has already received ammunition during the current rendezvous may become eligible again if normal combat subsequently reduces their carried ammunition below target.

If they again have the greatest current serviceable deficit, they may be selected again.

Example:

Person 1 receives 2 rounds: 0 → 2.

Person 1 legitimately fires those 2 rounds.

Person 1 is now 0 / target 2.

Before a later handoff, Person 1 again has the greatest deficit.

They may legitimately receive again.

No ammunition is duplicated because the earlier ammunition was actually expended.

10. No fairness rotation

The handoff system does not guarantee that every eligible Squad member receives once before anybody receives twice.

Do not introduce:

round-robin issue;

previously-served exclusion;

per-cycle fairness flags;

firing suppression;

reserved individual shares.

The authored greatest-current-deficit rule remains authoritative.

Thus an observed sequence such as:

Person 1 → Person 2 → Person 1 → Person 2

is valid if each selection is correct when that handoff begins.

11. Target and conservation remain unchanged

Every successful handoff still obeys:

transfer = min(current individual deficit, staging rounds)

and:

staging decrease = recipient increase

No recipient exceeds their replenishment target at the instant of transfer.

Later firing may immediately reduce their carried ammunition again.

12. Stock Exhausted with continuing deficit

If normal concurrent firing causes staging to reach zero while positive serviceable deficit remains:

current cycle terminates:

Stock Exhausted

The selected Squad resumes its preserved intent according to the existing rules.

Company does not immediately create Request B from an older readiness sample.

It waits for a new report sourced after the Stock Exhausted terminal time.

13. Fresh post-terminal report

The first valid report capable of creating the next cycle must represent subordinate ammunition state sampled after the prior cycle ended.

Example:

Cycle A terminal:

193.57

Valid Cycle B readiness source:

> 193.57

If that fresh report establishes:

positive serviceable deficit;

insufficient known staging;

insufficient known other inbound;

no active cycle;

Company may form Request B.

Its request identity and cargo must be distinct from Cycle A.

14. No artificial report injection

The acceptance scenario may not force a readiness report at the cycle boundary.

The normal accepted readiness/report cadence must produce the post-terminal sample and deliver it through the ordinary information path.

The acceptance evidence should record:

cycle terminal timestamp;

next readiness source timestamp;

readiness receive timestamp;

Request B creation timestamp.

15. Two-cycle acceptance definition

A valid pair of distinct cycles now requires:

Cycle A

fresh shortage
→ Request A
→ physical supply A
→ staging A
→ rendezvous/issue A
→ some A-issued ammunition actually fired
→ Cycle A terminal

Cycle B

readiness sampled after Cycle A terminal
→ fresh deficit still/newly present
→ Request B
→ distinct physical supply B
→ staging B
→ rendezvous/issue B
→ at least one B-issued round later fired

The cycles may be temporally close.

They may not overlap at the Company request-cycle level.

16. A/B endurance remains unchanged

The equal-time supplied/control comparison remains authoritative.

The supplied case may naturally fire during local issue.

The control case must not receive ammunition.

Acceptance continues to compare actual legitimate P1-A ammunition expenditure/shots at equal world time.

No firing suppression or artificial pacing is authorized.

17. Company Resupply Decision Graph v2.1

Replace the same-category repeat-demand portion of Company Resupply Decision Graph v2.0 with:

New readiness/logistics information received?

→ NO
No demand decision from hidden truth.

→ YES

Update legitimate Company knowledge.

Rifle Ammunition resupply cycle active?

→ YES
Do not create another Rifle Ammunition request.
Continue the current cycle.
Preserve the newer information for normal knowledge/status purposes.

→ NO

Was there a previous Rifle Ammunition cycle?

→ YES

Latest readiness source timestamp > previous cycle terminal timestamp?

→ NO
Do not create a new request from stale/pre-terminal readiness.

→ YES
Continue demand evaluation.

→ NO previous cycle
Continue demand evaluation.

Calculate request gap under the existing rules.

request gap > 0?

→ NO
No request.

→ YES

Create one request according to the existing crate-count rule.

That request opens a new Rifle Ammunition resupply cycle.

18. Rendezvous cycle closure

When the rendezvous reaches:

Resupplied;

Stock Exhausted;

No Eligible Recipient;

record that world time as the cycle terminal time.

If the cycle instead cancels before physical loading as Need Resolved, the cancellation time is its terminal time.

Only a later readiness sample may establish a subsequent cycle.

Design-history entry
PV0-ML01-D13 — Resupply cycle freshness boundary

Decision: Same-category request closure at staging does not end the resupply cycle. The cycle remains active through local distribution and must reach a terminal rendezvous/cancellation state before another request may form.

Reason: Transport completion can occur well before physical distribution. Allowing new requests from pre-distribution readiness causes one underlying shortage to fragment into overlapping request identities.

PV0-ML01-D14 — Post-terminal readiness required

Decision: A subsequent Rifle Ammunition request requires a readiness sample sourced strictly after the previous cycle's terminal time.

Reason: The new request must represent the post-cycle state rather than stale information describing the shortage Cycle A was already servicing.

PV0-ML01-D15 — Concurrent combat during issue

Decision: Combat remains live during handoff. Previously served recipients may become eligible and receive again under the existing greatest-current-deficit rule.

Reason: Resupply locality is not a ceasefire zone, and introducing fairness rotation or firing suppression would alter accepted tactical behavior solely for test convenience.

Status: Authoritative PV0 behavior.
