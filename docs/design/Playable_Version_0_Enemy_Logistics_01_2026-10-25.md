Trencho Playable Version 0
Enemy Logistics 01 — Autonomous Rear-to-Battlefield Parity

Date: 25 October 2026
Status: Design complete for implementation handoff
Authority: Trencho Game Designer under Dawson's direction
Dependencies: Accepted #15, #17, #21–#24
Reconciles: #18 / T3-OPP-048
Parent design: GDD v1.1, Playable Version Rear Foundations 01–03, Military Logistics 01 including D09–D15

1. Player outcome

The opposing belligerent becomes a genuine logistics participant.

Enemy ammunition that appears on the battlefield must originate from a finite enemy rear resource chain rather than periodic refill, invisible stock creation or direct soldier grants.

The authoritative enemy chain is:

finite enemy Metal
→ physical enemy rear Storage
→ Ammunition Workshop
→ Ammo Crate 8
→ enemy Dispatch
→ enemy rear outbound truck
→ Enemy HQ Military Stores
→ enemy Company demand
→ Enemy HQ allocation
→ enemy military resupply truck
→ enemy Company staging
→ autonomous rendezvous
→ 4 m local handoff
→ individual enemy inventory
→ actual firing

The player does not operate this chain.

2. Parity means shared constraints, not identical player interaction

Enemy logistics obey the same core product rules as the accepted friendly chain:

same Rifle Ammunition category;

same 1 Metal → Ammo Crate 8 recipe;

same physical custody;

same finite raw-resource accounting;

same workshop work time;

same vehicle capacities;

same loading/unloading times;

same rear→HQ transit duration;

same HQ→Company transit duration;

same readiness semantics;

same request/cancellation semantics;

same cycle-freshness semantics;

same 4 m issue locality;

same replenishment-target semantics;

same person-level conservation.

The human player's manual controls are not mirrored.

The enemy rear is automated.

3. Protected enemy rear

Normal PV0 gains one authoritative protected enemy rear.

It is physically distinct from the player rear.

It is not accessible to the player's rear avatar.

For this capability enemy rear combat/interdiction is excluded.

The enemy rear contains:

physical raw-resource Storage;

one completed Ammunition Workshop;

finished-goods Dispatch;

one persistent enemy logistics worker;

one rear outbound logistics truck.

4. Normal enemy rear starting stock

Normal PV0 enemy rear begins with:

4 Metal

in physical Storage.

That represents a maximum of:

4 Ammo Crates 8 / 32 manufactured rounds

unless future systems provide additional raw material.

This is a provisional scenario resource value.

No finished ammunition begins in enemy rear Dispatch or Enemy HQ solely because this capability exists.

Existing battlefield starting ammunition remains separate scenario-start carried stock.

5. Prebuilt enemy infrastructure

Enemy rear infrastructure is already established at scenario start.

The enemy therefore does not use the player's manual workshop-construction interaction in this capability.

This is an initialization asymmetry, not a different production rule.

Once initialized, enemy production uses the same:

physical Metal;

workshop input;

four-world-second production work;

physical Ammo Crate 8 output;

Dispatch;

truck custody.

6. Enemy logistics worker

The enemy rear has:

1 persistent logistics worker

for this package.

That worker performs the rear activities required to satisfy received ammunition requirements.

There is no free invisible second labor source.

The same worker cannot simultaneously:

haul Metal;

operate the workshop;

move finished output;

load the outbound truck.

7. Enemy worker physicality

The worker physically moves between:

Storage;

workshop input;

workshop operator position;

workshop output;

Dispatch;

rear truck loading point.

Crates likewise retain physical custody.

Automation may decide work.

Automation may not teleport work.

8. Enemy HQ Logistics Receiver

Introduce the enemy-side equivalent of the accepted friendly provisional logistics receiver:

Enemy HQ Logistics Receiver

It is:

fixed for the PV0 reference scenario;

non-combat;

outside #19 combat-HQ semantics;

not damageable;

not capturable;

not itself a defeat condition.

It contains unlimited provisional Rifle Ammunition Military Stores.

9. Enemy rear→HQ route

One authored protected logistics route connects:

Enemy Rear → Enemy HQ Logistics Receiver

Normal one-way travel:

20 world seconds

Return:

20 world seconds

The enemy rear outbound truck has:

4 Ammo Crate capacity

and no personnel role in this package.

10. Enemy Company staging

Enemy military distribution ends at an authoritative enemy Company staging point.

The local issue radius is:

4.0 design meters

using the same meaning as the accepted friendly locality.

No legacy proof-coordinate radius is reused.

11. Existing starting soldier ammunition

Enemy scenario-start carried ammunition remains valid initial inventory.

It must be included in ammunition accounting.

It does not count as rear logistics resupply.

No acceptance claim may treat starting soldier inventory as produced or delivered ammunition.

12. Enemy replenishment targets

At battle initialization, each enemy person's authored compatible carried ammunition is snapshotted as that person's replenishment target.

Exactly as on the friendly side:

target is not final carrying capacity;

target 0 personnel are not eligible for this resupply path;

resupply may not raise a person above target.

13. Enemy serviceable readiness

Use the accepted D11 rule.

A serviceable enemy rifle user must be:

living;

active;

enemy-side;

Rifle Ammunition compatible;

positive replenishment target.

Target-0 personnel contribute neither user count nor rounds to Rifle Ammunition readiness.

For at least one serviceable user:

Low Rifle Ammunition = current rounds < 2 × serviceable rifle-user count

Equality is not Low.

Zero serviceable users means ammunition readiness is:

Not Applicable

14. Enemy information ownership

Enemy logistics decisions use enemy-owned information.

There is no cross-side authoritative logistics knowledge.

Enemy Company knows only legitimately received:

subordinate readiness;

enemy Company staging stock;

known enemy inbound military supply.

Enemy HQ knows:

received Company requests;

enemy HQ stores;

committed military stock;

military-truck state.

Enemy protected rear knows:

its own physical Metal;

worker/workshop state;

rear Dispatch stock;

rear-truck state;

received enemy rear logistics requirements.

15. Player information boundary

The player does not receive:

exact enemy raw stock;

enemy workshop status;

enemy production queue;

enemy HQ stock;

enemy request state;

enemy staging quantity;

enemy individual ammunition merely because the logistics system knows it.

Development/debug evidence may expose exact truth.

Normal gameplay does not.

16. Observable enemy world objects

Enemy logistics objects remain ordinary world objects where normal presentation legitimately exposes them.

If an enemy military resupply truck is physically visible in a currently observable battlefield area, the player may see the truck.

This does not reveal:

exact cargo;

request status;

hidden destination logic;

protected-rear inventory.

No special omniscient enemy logistics UI is added.

17. Enemy Company demand

Enemy Company uses the accepted friendly Company Resupply Decision Graph v2.1 semantics under enemy ownership.

Only newly received readiness/logistics information may change enemy demand.

No hidden individual-inventory scan creates a request.

18. Enemy request gap

With no active enemy Rifle Ammunition cycle:

request gap = latest received serviceable deficit - known staging - known pre-existing inbound

Positive gap may create:

min(4, ceil(gap / 8)) crates

as the requested amount.

There is one active enemy Rifle Ammunition resupply cycle at a time.

19. Enemy cycle freshness

The accepted D13/D14 boundary applies.

Transport request closure does not terminate the whole enemy resupply cycle.

Another request may form only after:

the previous cycle reaches a terminal distribution/cancellation state; and

Enemy Company receives readiness whose source timestamp is later than that terminal time.

20. Enemy Company→Commander request

Enemy Company sends a legitimate Rifle Ammunition request upward through its accepted hierarchy.

Existing accepted adjacent-echelon communication timing/provenance remains authoritative.

Enemy Commander/HQ does not act before receipt.

21. Enemy HQ allocation

On receiving a valid Company request:

Compatible enemy HQ stock exists

Allocate:

min(requested crates, available crates, 4)

specific physical Ammo Crates.

Enemy HQ stock is zero

Request becomes:

Waiting for HQ Stock

and Enemy HQ generates a protected-rear logistics requirement.

22. No hidden backorder after partial HQ allocation

If Enemy HQ has some but fewer crates than requested:

allocate the available crates;

proceed with that partial military shipment;

do not maintain a hidden remainder against the same Company request.

Later post-cycle readiness may produce a distinct request.

This preserves friendly-side partial-allocation semantics.

23. Enemy Rear Logistics Requirement

Enemy HQ sends a side-owned logistics requirement to protected rear only when:

a valid Company request is Waiting for HQ Stock because compatible HQ stock is zero.

Requirement quantity equals the waiting request's crate quantity, maximum 4.

The requirement identifies:

ammunition category;

requested crate count;

source Company request;

sent time;

received time.

24. Rear-message timing

For PV0, Enemy HQ ↔ protected rear logistics requirement/cancellation messages use:

1 world second reliable one-way delivery

This is provisional.

No communications failure/expiry system is introduced here.

25. Rear requirement is not ammunition

Receiving a rear requirement creates no stock.

It authorizes enemy rear automation to use existing physical resources and labor toward that requirement.

No Metal, Ammo Crate or truck cargo is created by the message itself.

26. Existing finished rear stock first

When a rear requirement is received:

enemy automation first considers compatible uncommitted Ammo Crates already physically present in rear Dispatch.

Those crates satisfy the requirement before new production is started.

27. Production requirement

If required crates remain after existing finished stock:

one production job is created at a time;

each job requires physical Metal 1;

each job requires four active world seconds;

each successful job creates one Ammo Crate 8.

The automation produces no more crates than the current rear requirement requires.

28. Finite Metal

If insufficient Metal exists:

produce only what physical Metal allows.

When no further required crate can be produced:

rear requirement becomes:

Raw Material Exhausted

Any successfully produced crates remain real physical stock.

No raw resource is invented.

29. Rear requirement fulfillment point

The rear requirement becomes ready for shipment when either:

its requested crate count exists physically in rear Dispatch; or

raw Metal is exhausted and at least one required crate has been produced.

Only then are those finished crates committed to one rear→HQ shipment.

This prevents an invisible rolling truck allocation while production is still unresolved.

30. Enemy rear worker priority

The worker uses the following priority while not already carrying/operating an active protected action:

complete committed outbound truck loading;

move required finished workshop output to Dispatch;

deliver Metal needed by current requirement to workshop input;

operate a ready required production job;

recover/store carried excess or loose raw resources;

idle.

An already-active workshop job is completed before unrelated reassignment.

An already-carried physical crate is safely completed/recovered before unrelated work.

31. Why loading outranks new production

Once a rear→HQ shipment is committed, the logistics requirement has reached a physically shippable state.

The sole worker therefore finishes that shipment before beginning unrelated production.

This preserves the explicit finite-labor tradeoff.

32. Rear requirement cancellation before active production

If Enemy HQ legitimately cancels the rear requirement before any required production job has begun:

remove unstarted requirement work;

leave all physical stock unchanged.

33. Cancellation during active production

If requirement cancellation is received while the worker is actively operating a production job:

the current job completes;

its committed Metal is consumed normally;

the resulting Ammo Crate becomes uncommitted rear finished stock;

no additional requirement jobs begin.

Active work is not erased.

34. Rear-shipment cancellation

After finished crates are committed to a rear→HQ shipment:

Before first crate begins rear-truck loading

A legitimate received cancellation may:

cancel the shipment;

release those crates back to uncommitted enemy rear Dispatch stock.

Once first crate begins loading

The shipment is irreversible.

It completes to Enemy HQ.

This mirrors the accepted physical-movement boundary.

35. Rear outbound loading

The one enemy logistics worker physically loads the committed Ammo Crates.

Each requires:

1 active world second

Truck departure occurs only after all crates committed to that rear shipment are aboard.

36. Enemy rear truck travel

After loading:

truck physically travels 20 world seconds to Enemy HQ;

arrival alone grants no HQ stock.

Crates unload automatically at HQ:

1 world second per crate

Only completed unloading transfers custody into Enemy HQ Military Stores.

37. Enemy rear truck return

After all cargo unloads:

truck physically returns for 20 world seconds;

becomes available at enemy rear.

No hidden second rear shipment queue exists.

38. Waiting Company request after HQ replenishment

If the original enemy Company request remains legitimately:

Waiting for HQ Stock

when new compatible crates enter Enemy HQ Military Stores:

Enemy HQ re-evaluates that waiting request;

available physical crates may be allocated under the normal HQ allocation rule.

No new Company request is required merely because the stock arrived later.

39. Resolved Company need before rear supply

If newer legitimate Company readiness resolves the need before military loading:

apply the accepted cancellation semantics;

cancel the waiting/authorized Company request;

if applicable send cancellation to the enemy rear requirement.

Physical ammunition already produced remains physical enemy stock.

It is never deleted because the need disappeared.

40. Enemy military resupply truck

Enemy HQ has:

1 military Rifle Ammunition resupply truck

Capacity:

4 Ammo Crates

It is separate from the enemy rear→HQ truck.

41. Military loading and cancellation

Use accepted friendly D09 semantics.

Before first current-request crate begins military loading:

independent updated need may legitimately cancel the request.

The request's own allocation does not self-cancel.

After first military loading begins:

shipment becomes irreversible;

already authorized cargo completes to enemy Company staging.

42. Enemy HQ→Company route

One authored enemy military logistics corridor connects:

Enemy HQ Logistics Receiver → Enemy Company staging

One-way travel:

15 world seconds

Return:

15 world seconds

Current PV0 route is safe from interdiction/destruction.

43. Company unloading

At enemy Company staging:

unload one physical Ammo Crate at a time;

each requires 1 world second;

each completion adds exactly 8 rounds to enemy Company staging custody.

Arrival alone adds nothing.

44. Enemy staging knowledge

Enemy Company may initiate rendezvous only after legitimately receiving the staging-stock status.

Physical staging stock and Company knowledge remain distinct.

45. Enemy rendezvous

Once Enemy Company legitimately knows:

positive compatible staging stock; and

received positive serviceable deficit;

use the same accepted autonomous responsibility split:

Company selects eligible Platoon;

Platoon selects greatest-deficit eligible Squad;

embodied Squad leadership performs local movement authority;

infantry physically execute.

No player selection exists.

46. Embodied leadership

Enemy logistics does not bypass enemy command embodiment.

If required enemy leadership is unavailable:

Delayed — Leadership Unavailable

with:

stock preserved;

no fake order;

no teleport;

no handoff.

47. Enemy local handoff

Within 4 m, eligible enemy recipients must be:

living;

active;

enemy-side;

selected-Squad member;

compatible;

positive target;

below target.

Choose before every issue:

greatest current deficit;

stable person ID.

Each issue takes:

1 active world second

and revalidates locality/eligibility at completion.

48. Enemy combat remains live during issue

Accepted D15 semantics apply.

No ceasefire exists at enemy staging.

A recipient may:

receive ammunition;

fire it normally;

become deficient again;

legitimately receive again in the same rendezvous if greatest current deficit.

There is no once-per-person fairness rule.

49. Enemy handoff conservation

At successful completion:

transfer = min(person target - person current, enemy staging rounds)

and exactly:

staging decrease = person increase

No person exceeds target.

50. Enemy cycle terminal states

Enemy Rifle Ammunition cycle terminal states are:

Resupplied;

Stock Exhausted;

No Eligible Recipient;

Cancelled — Need Resolved.

Leadership delay remains nonterminal while staging+need continue.

The next cycle requires readiness sourced after terminal.

51. Protected rear automation knowledge

The enemy rear automation may know:

received rear requirement;

its physical Metal;

its worker state;

workshop input/job/output;

Dispatch finished goods;

rear-truck state.

It may not know:

hidden instantaneous battlefield inventories;

future Company demand;

player rear inventory;

friendly-side command knowledge.

52. Enemy logistics automation must not

It must not:

create Metal;

create Ammo Crates without production;

produce without an active rear requirement;

operate the workshop without the logistics worker;

move multiple crates simultaneously through one worker;

create a free loading worker;

inject HQ stock;

inject staging stock;

refill soldiers remotely;

select recipients globally;

create requests from hidden battlefield truth.

53. Player-facing presentation

There is no enemy logistics management screen.

Normal player understanding comes from legitimate consequences:

enemy fire may persist because enemy supply exists;

an enemy military truck may be visually observable if exposed in normal battlefield presentation;

enemy ammunition endurance differs when its logistics chain functions.

Exact enemy logistics state stays hidden.

54. Normal scenario boundary

Normal PV0 retains its existing battlefield force composition and starting soldier ammunition unless separately amended later.

Enemy rear starts with the four-Metal protected-rear reserve defined here.

Normal play is not required to exhaust enough enemy ammunition to demonstrate the complete chain before battle ends.

Focused acceptance provides the deterministic full-chain proof.

55. Focused enemy-parity acceptance scenario

For internal deterministic acceptance only, use a mirrored ammunition-constrained scenario authored before battle initialization.

Enemy

Representative enemy Squad E1-A:

four ordinary compatible rifle infantry;

2 rounds each;

replenishment target 2 each.

All other enemy compatible rifle personnel:

0 rounds;

target 0.

Enemy protected rear:

one logistics worker;

completed infrastructure;

2 physical Metal;

no finished Ammo Crates;

Enemy HQ stock 0;

enemy Company staging 0.

Opposing friendly force

32 ordinary friendly rifle infantry;

0 compatible rifle ammunition;

ordinary existing combat statistics/AI.

This is an acceptance-only setup.

Normal default initialization remains unchanged.

56. Why two Metal

Two Metal provides exactly:

2 physical Ammo Crates 8

for the successful focused chain.

This permits:

Cycle A;

actual expenditure;

Cycle B;

later expenditure;

while making a subsequent shortage expose finite raw exhaustion.

No reserve is hidden.

57. Focused scenario restrictions

After initialization, do not:

grant Metal;

grant ammunition;

create finished crates;

inject HQ/staging stock;

force requests;

force movement;

force contact;

force handoffs;

force shots;

add targets;

alter targets;

protect actors through hidden invulnerability.

All chain behavior must arise normally.

58. Supplied focused acceptance

Require two complete enemy cycles:

Cycle A

actual enemy firing
→ fresh readiness deficit
→ Enemy Company Request A
→ Enemy HQ waiting stock
→ rear requirement A
→ real Metal production A
→ rear truck A
→ HQ receipt
→ military allocation/truck A
→ Company staging A
→ rendezvous/handoff A
→ actual expenditure of A-issued ammunition
→ Cycle A terminal

Cycle B

After fresh post-terminal readiness:

Request B
→ rear requirement B
→ second Metal consumed
→ distinct Ammo Crate B
→ rear→HQ shipment
→ military shipment
→ distinct handoff
→ at least one B-issued round later fired

59. Supplied/control endurance comparison

Run equal-time deterministic cases.

Supplied

Enemy rear begins with the exact 2 Metal.

Control

Identical combat initialization, worker and infrastructure, but:

enemy rear Metal = 0

Expected control:

legitimate request may form;

Enemy HQ waits for stock;

rear requirement reaches Raw Material Exhausted;

no ammunition is manufactured;

no staging refill/handoff occurs.

The supplied enemy must demonstrate materially greater legitimate rifle expenditure than the control.

No different player battlefield orders are permitted.

60. Finite-resource exhaustion acceptance

After Cycle B expenditure creates a later fresh shortage:

enemy rear has:

0 Metal

If Enemy HQ is also empty:

new requirement may form;

rear reports Raw Material Exhausted;

no third Ammo Crate appears.

This is required evidence that enemy logistics is finite rather than a refill timer.

61. Shared time

Enemy:

rear work;

rear trucks;

HQ intake;

military trucks;

rendezvous;

handoff;

firing

use the same world clock.

Pause freezes them.

Accepted acceleration advances them consistently.

View history does not change equal-world-time state.

62. Edge cases
No enemy Metal

Requirement waits/exhausts; no production.

Worker unavailable

Production/material movement/loading stop. No free substitute worker.

Workshop lacks input

Worker must physically provide Metal.

Workshop output occupied

No new completed output may appear invisibly.

Rear Dispatch full

Output waits physically; no rear shipment created from nonexistent capacity.

Rear truck away

Finished requirement cargo waits.

Company need resolves during production

Unstarted production cancels; active job finishes; produced crate remains rear stock.

Need resolves before rear-truck loading

Committed rear cargo may be released after legitimate cancellation reaches rear.

Need resolves after rear loading starts

Rear shipment continues to HQ.

HQ receives stock after Company cancellation

Stock remains Available at Enemy HQ.

Military request cancels before loading

Crates remain/revert Available HQ.

Need changes after military loading begins

Shipment completes.

Leader unavailable

Staging stock waits; no fake rendezvous.

Recipient dies/leaves 4 m during issue

No transfer completes to that person.

Staging exhausts

Cycle terminates Stock Exhausted.

Finished staging stock remains

May service later legitimate rendezvous.

Target-0 rifle user

Receives nothing and does not create false Low readiness.

63. Enemy Rear Automation Decision Graph v1.0

Rear logistics requirement received?

→ NO
Do not manufacture ammunition. Maintain existing physical stock.

→ YES

Existing uncommitted Ammo Crates sufficient?

→ YES
Prepare requirement for rear shipment.

→ NO

Physical Metal available for missing crate?

→ NO
Requirement = Raw Material Exhausted.
Ship any legitimately completed partial quantity if greater than zero.

→ YES

Use sole logistics worker to:

Metal to workshop → operate 4 world seconds → Ammo Crate 8 → Dispatch

Repeat only until requirement quantity is physically satisfied or Metal exhausts.

Then commit resulting requirement cargo.

Cancellation received before rear loading begins?

→ YES
Release committed crates to ordinary rear stock.

→ NO / first loading begun
Complete rear shipment.

64. Enemy Logistics Worker Decision Graph v1.0

Currently carrying physical crate?

→ YES: safely complete/recover it.

Currently operating active workshop job?

→ YES: complete active job.

Otherwise priority:

committed rear outbound loading;

required workshop output → Dispatch;

required Metal → workshop input;

operate ready required workshop job;

physical recovery/storage;

idle.

One worker performs only one active labor action at a time.

65. Enemy HQ Logistics Decision Graph v1.0

Enemy Company request received?

→ NO: no military allocation.

→ YES

Available compatible HQ stock > 0?

→ YES
Allocate exact crates up to request/capacity and follow accepted military-request semantics.

→ NO
Request = Waiting for HQ Stock.

Active rear requirement already exists for this waiting request?

→ YES: do not duplicate.

→ NO: send one rear requirement.

When compatible physical HQ stock later arrives:

re-evaluate still-valid waiting request.

Need-resolved cancellation follows accepted D09 semantics.

66. Enemy Company Resupply Decision Graph v1.0

Use friendly v2.1 behavior under enemy ownership:

New legitimate readiness/logistics information?

→ NO: no hidden-truth decision.

→ YES

Enemy Rifle Ammunition cycle active?

→ YES: update knowledge, create no duplicate request.

→ NO

If previous cycle exists:

latest readiness source time > previous cycle terminal?

→ NO: no request from stale/pre-terminal readiness.

→ YES: evaluate gap.

Positive request gap creates one request, maximum 4 crates.

67. Enemy Military Distribution Decision Graph v1.0

After HQ authorization:

first military loading started?

→ NO
Need may still legitimately cancel under D09.

→ YES
Shipment irreversible.

Load one crate per world second.

Travel HQ→Company 15 world seconds.

Unload one crate per world second.

Company acts only after legitimate staging receipt.

Then:

received staging > 0 and received deficit > 0?

→ NO: no rendezvous.

→ YES

Use accepted Company→Platoon→Squad embodied rendezvous.

At 4 m issue locality:

greatest current deficit;

stable ID ties;

1 second issue;

revalidate;

exact conservation.

Terminate Resupplied / Stock Exhausted / No Eligible Recipient.

Next cycle requires post-terminal readiness.

68. Observable Acceptance A — Complete enemy provenance

From focused supplied scenario demonstrate one crate's exact identity through:

Metal
→ Workshop
→ Ammo Crate
→ rear Dispatch
→ rear truck
→ Enemy HQ
→ military truck
→ enemy Company staging
→ enemy person inventory
→ spent ammunition

No step may be inferred from aggregate-only inventory changes.

69. Observable Acceptance B — Labor constraint

Show that the one enemy logistics worker:

physically supplies/operates production;

cannot simultaneously load outbound cargo;

finishes protected/current work before switching;

introduces no second hidden labor source.

70. Observable Acceptance C — Two cycles

Demonstrate distinct Cycle A and Cycle B with:

distinct requests;

distinct Metal consumption;

distinct Ammo Crate identities;

distinct physical rear/HQ/military movement;

post-terminal readiness freshness;

real local handoffs;

actual firing after each cycle.

71. Observable Acceptance D — Supplied/control

At equal world time:

supplied enemy has real 2-Metal rear chain;

control has identical world/combat setup but 0 Metal.

Demonstrate materially greater legitimate enemy ammunition expenditure in supplied case.

72. Observable Acceptance E — Resource exhaustion

After both physical Metal units are consumed and later legitimate need exists:

no third manufactured Ammo Crate appears;

rear requirement truthfully reports Raw Material Exhausted;

military chain cannot replenish from nothing.

73. Observable Acceptance F — Information boundary

Normal player presentation must not reveal enemy:

raw Metal count;

production state;

HQ inventory;

requests;

staging ammunition;

individual exact ammo through enemy logistics UI.

Debug/evidence may show those values.

74. Evidence expected from developer

Return evidence sufficient to inspect:

enemy raw Metal conservation;

sole-worker activities;

production timing;

exact Ammo Crate IDs;

rear requirement provenance;

rear shipment custody;

Enemy HQ receipt;

Company request and HQ allocation;

military shipment;

staging knowledge latency;

rendezvous hierarchy;

4 m recipient positions;

target/current/deficit;

exact handoff;

later firing;

two-cycle freshness;

finite exhaustion;

equal-time supplied/control outcome;

pause/1x/accepted acceleration/view-history equivalence;

normal player information boundary.

Normal/focused evidence remains distinct from isolated guard fixtures.

Assertion quantity is not acceptance.

No Dawson mechanical QA is requested.

75. Design history
PV0-EL01-D01 — Same physical ammunition contract

Decision: Enemy ammunition uses the accepted player/friendly Ammo Crate 8 production/custody rules.

Reason: Enemy logistics must be a belligerent implementation of Trencho, not a second simulation.

PV0-EL01-D02 — Prebuilt protected rear

Decision: Enemy begins with established rear infrastructure rather than AI construction.

Reason: Autonomous construction/base-layout strategy is not required to prove logistics parity and would substantially broaden this capability.

PV0-EL01-D03 — One logistics worker

Decision: Enemy rear has one persistent worker for production/material movement/loading.

Reason: Automation must still pay the labor constraint the old #18 intended.

PV0-EL01-D04 — Four normal-start Metal

Decision: Normal enemy protected rear has 4 finite Metal.

Reason: Supplies a bounded reserve without creating indefinite replenishment.

Status: Provisional scenario balance.

PV0-EL01-D05 — Demand-driven production

Decision: Enemy rear manufactures ammunition only after a legitimate HQ rear requirement.

Reason: Demonstrates actual battlefield shortage driving the logistics economy rather than an independent refill timer.

PV0-EL01-D06 — Separate rear and military trucks

Decision: Enemy rear→HQ and HQ→Company custody use distinct vehicles, matching the established friendly physical boundaries.

PV0-EL01-D07 — Player-hidden logistics truth

Decision: Exact enemy rear/HQ/staging state remains hidden.

Reason: Simulation parity does not imply information parity.

PV0-EL01-D08 — Two-Metal focused scenario

Decision: Acceptance-focused enemy rear begins with exactly 2 Metal.

Reason: Enables two real resupply cycles and then exposes finite exhaustion.

PV0-EL01-D09 — Cancellation preserves produced goods

Decision: Resolving demand may cancel unstarted work/shipment but never deletes already produced physical ammunition.

Reason: Need state and physical ownership are separate.

76. Explicit exclusions

Do not add:

enemy raw-resource replenishment;

enemy personnel recruitment;

enemy workshop construction;

additional enemy workshop types;

enemy player-like UI;

convoy interception;

truck destruction;

road destruction;

final communications failures;

enemy combat-HQ destruction;

victory/defeat resolution;

final campaign economy;

final art.

77. Future compatibility obligation

Future features adding:

multiple Companies;

multiple workshops/workers;

enemy raw-resource acquisition;

convoy attack;

combat HQs;

multiple ammunition/equipment types;

route selection;

captured supply;

must explicitly update the relevant enemy:

rear automation graph;

HQ logistics graph;

request graph;

transport graph;

rendezvous/handoff graph;

player information boundary.

Engineering returns unresolved gameplay semantics to the Game Designer.
