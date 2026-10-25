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
