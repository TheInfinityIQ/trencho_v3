Trencho Playable Version 0
Combat Outcome 01 — Sector-Native Combat HQs & Battle Termination

Date: 25 October 2026
Status: Design complete for implementation handoff
Authority: Trencho Game Designer under Dawson's direction
Dependencies: Accepted #15, #17, #18, #21–#24
Reconciles: #19 / T3-OUT-050
Parent design: GDD v1.1, accepted bilateral command/logistics designs

1. Player outcome

The representative sector now has a real military objective.

Each primary belligerent has one physical battlefield Combat HQ.

Destroying the opposing Combat HQ immediately defeats that belligerent.

The player still does not issue tactical battlefield orders.

The player's strategic influence continues to come through logistics and production while the military hierarchy prosecutes the battle autonomously.

2. WAR-01 remains authoritative

For a two-primary-belligerent PV0 battle:

destruction of a primary belligerent's Combat HQ defeats that belligerent.

The following do not independently produce victory:

Commander death;

ammunition exhaustion;

depletion of HQ military stores;

destruction/exhaustion of logistics trucks;

loss of the protected rear;

Company staging reaching zero;

elimination of a subordinate formation.

3. Combat HQ is not the Logistics Receiver

The existing:

Friendly HQ Logistics Receiver;

Enemy HQ Logistics Receiver;

remain rear-facing logistics facilities.

The new:

Combat HQ

is a separate battlefield entity.

Therefore:

Combat HQ ≠ HQ Logistics Receiver

The logistics receiver remains non-combat and outside the sector outcome rule.

4. Logistics Receiver continuity

Destroying a Combat HQ does not retroactively mean that its Logistics Receiver was physically destroyed.

Likewise, the Logistics Receiver cannot be attacked to obtain victory in this package.

The distinction remains explicit until a later campaign/theater design deliberately connects those facilities.

5. One Combat HQ per side

PV0 has exactly:

one Friendly Combat HQ;

one Enemy Combat HQ.

Each belongs to exactly one primary belligerent.

No neutral, secondary or replacement HQ exists in this package.

6. Sector-native geography

Both Combat HQs exist inside the actual representative combat sector.

They do not use:

legacy Battle coordinates;

legacy auto-artillery geometry;

proof-only fixed coordinate assumptions outside the sector simulation.

For the PV0 reference scenario, their locations are authored and stable.

7. Geographic relationship

The two HQ positions are mirrored across the representative sector.

Each HQ:

occupies its own side's rear portion of the combat sector;

begins behind that side's frontline formations;

is reachable through ordinary sector movement;

does not overlap Company staging;

does not overlap the provisional Logistics Receiver;

does not block the existing military logistics corridor.

Exact scene authoring remains implementation-owned.

8. Physical presence

A Combat HQ is a visible stationary military structure.

For PV0 it occupies approximately:

6 × 6 design meters

of battlefield space.

It:

does not move;

cannot be carried;

cannot be rebuilt during battle;

cannot be repaired during battle.

9. Combat HQ integrity

PV0 Combat HQ maximum integrity:

12 Integrity

This value is provisional.

At battle initialization:

Integrity = 12 / 12

for each side.

10. Valid HQ damage

For the current rifle-only combat slice, a Combat HQ is damaged only by a legitimate hostile rifle hit.

A valid hit requires the existing ordinary combat conditions for a rifle attack, including applicable:

hostile relationship;

range;

line of sight;

firing eligibility;

ammunition expenditure;

hit resolution.

No remote objective damage exists.

11. Rifle structural damage

Each legitimate ordinary Rifle hit against a Combat HQ removes:

1 Integrity

and consumes the firing person's ammunition normally.

No separate free "HQ attack" resource exists.

12. Invalid damage

A Combat HQ receives no damage from:

friendly-side fire;

ammunition merely being allocated or moved;

proximity;

Commander death;

reports/orders;

supply shortage;

elapsed time.

13. Damage persistence

Combat HQ damage persists for the remainder of the battle.

There is:

no regeneration;

no repair worker;

no repair resource;

no reset on view switch.

14. HQ damage states

Player-readable structural states are:

Intact: 9–12 Integrity

Damaged: 5–8 Integrity

Critical: 1–4 Integrity

Destroyed: 0 Integrity

These states are presentation/communication bands around the authoritative integrity value.

15. Friendly HQ information

Friendly exact inspection may show:

Combat HQ identity;

exact Integrity;

structural state;

whether battle is active or terminal.

This follows the existing friendly exact-inspection privilege.

16. Enemy HQ information

The player knows the Enemy Combat HQ as the primary military objective and may know its authored location.

Normal UI does not reveal exact enemy Integrity globally.

When the enemy HQ is legitimately observable, the player may perceive its coarse structural state:

Intact;

Damaged;

Critical;

Destroyed.

Exact enemy Integrity remains debug/evidence truth.

17. Objective knowledge

For this PV0 reference battle, both Commanders know the opposing Combat HQ's objective location from scenario start.

This is scenario objective knowledge.

It is not derived from omniscient knowledge of enemy personnel or logistics.

18. Primary operational objective

At battle initialization, each Commander receives the primary operational objective:

Destroy Enemy Combat HQ

This intent enters the existing command hierarchy.

It does not jump directly to infantry.

19. Existing hierarchy remains authoritative

Objective execution remains:

Commander → Company → Platoon → Squad Leader → infantry

Each echelon retains its accepted responsibility.

Combat Outcome 01 does not collapse those decisions into a global HQ-seeking movement command.

20. Commander objective behavior

While battle state is Active and the enemy Combat HQ survives, the Commander maintains Destroy Enemy Combat HQ as the primary objective unless legitimate received readiness or existing command conditions cause a temporary:

hold;

delay;

adaptation.

When the temporary reason clears, the existing hierarchy may resume the preserved objective.

21. Ammunition readiness remains consequential

Low Rifle Ammunition may delay or hold an advance under the accepted D11 semantics.

Adding Combat HQs does not make armies ignore logistics merely to reach the objective.

Resupply may restore the ability to continue the existing HQ objective.

22. Company behavior

Company translates the received HQ objective into subordinate operational commitments using the existing accepted hierarchy.

At least one subordinate Platoon may be committed toward the enemy objective when legitimate readiness permits.

No player Platoon selection is introduced.

23. Platoon behavior

Platoons coordinate their subordinate Squads under the received operational intent.

Existing:

readiness;

rendezvous;

local movement;

engagement

remain meaningful.

The HQ objective does not bypass the Platoon echelon.

24. Squad Leader behavior

A Squad assigned toward the enemy HQ:

physically routes through the sector;

reacts to legitimate local combat;

approaches the objective using ordinary movement;

may engage the Combat HQ when ordinary firing conditions are met.

No teleport or objective-radius damage is allowed.

25. Local threat versus HQ objective

When executing a Destroy Enemy HQ intent, Squad-level combat priority is:

immediate legitimate hostile-person threat handled by existing local combat behavior;

enemy Combat HQ when it is a valid visible/in-range combat target;

otherwise continue legitimate movement toward the HQ objective.

The HQ therefore matters as the operational destination without making nearby enemy soldiers cease to matter.

26. Combat remains live near HQ

An HQ assault does not create:

a ceasefire;

an invulnerability zone;

a special duel state.

Defending and attacking infantry continue ordinary combat behavior.

27. HQ does not itself attack

For PV0 the Combat HQ has:

no weapon;

no artillery;

no automatic fire;

no suppression attack.

Do not resurrect legacy HQ artillery behavior.

28. HQ does not issue tactical actions by itself

The physical Combat HQ is not an additional battlefield commander.

Orders remain generated through the accepted command hierarchy.

29. Commander and Combat HQ are distinct

The Commander role/person and Combat HQ structure are distinct state.

Commander death:

does not reduce Combat HQ Integrity;

does not automatically defeat the side.

Combat HQ destruction:

does not require Commander death first.

30. Commander death

Existing command/succession semantics remain authoritative.

A dead Commander is not a substitute victory condition.

If valid command behavior can continue through accepted role/succession rules, the battle continues until an HQ outcome occurs.

31. Ammunition exhaustion

A side with no available Rifle Ammunition is:

not defeated solely for that reason.

Its inability to fire may make HQ destruction practically likely or impossible, but the battle result does not trigger from ammunition count.

32. Personnel annihilation

Elimination of all current combat personnel does not itself invoke WAR-01.

If an HQ remains intact:

no HQ-destruction victory has yet occurred.

This may create a tactically resolved but formally unterminated state in this bounded package.

No surrender rule is introduced.

33. Combat HQ destruction

When Combat HQ Integrity reaches:

0

that HQ becomes:

Destroyed

at that exact shared-world time.

It may receive no further meaningful damage after destruction.

34. Immediate defeat

Destruction of one side's Combat HQ immediately defeats that primary belligerent.

If only Enemy HQ is destroyed:

Friendly Victory

If only Friendly HQ is destroyed:

Friendly Defeat

35. Mutual destruction

The historical simultaneous-HQ ambiguity is now resolved.

If both Combat HQs reach 0 Integrity at the same authoritative shared-world timestamp before a single-sided terminal result can be established:

result:

Draw — Mutual HQ Destruction

Both primary belligerents are defeated by WAR-01 at that timestamp.

36. Non-simultaneous ordering

If one HQ reaches 0 at an earlier authoritative world time:

the battle terminates at that time.

A later otherwise-pending hit cannot subsequently convert that result into mutual destruction.

37. Terminal battle states

Battle state is exactly one of:

Active

Friendly Victory — Enemy HQ Destroyed

Friendly Defeat — Friendly HQ Destroyed

Draw — Mutual HQ Destruction

No other terminal result is added here.

38. Battle-result record

Terminal result records:

result;

defeated side or both sides;

destroyed Combat HQ identity;

terminal world timestamp.

Debug/evidence may additionally record exact causal shot/person information.

39. Terminal simulation behavior

When battle state becomes terminal:

world-time advancement stops for this playable session.

All world-time-driven activity freezes at the terminal timestamp, including:

infantry;

command orders/reports;

firing;

rendezvous;

military trucks;

rear trucks;

workshop work;

hauling;

production;

loading/unloading.

No post-result logistics transfer finishes afterward.

40. Post-result inspection

After battle termination the player may still switch normal views and inspect the frozen final state.

View switching does not resume simulation.

There is no Continue Battle control.

Restart/new scenario behavior remains outside this design.

41. Held player actions at termination

If the player is:

constructing;

producing;

carrying;

loading;

when the battle ends, that state freezes exactly at the terminal timestamp.

No completion is granted after termination.

42. In-transit supply at termination

Any physical shipment in transit when the battle ends remains in its exact terminal custody/location.

It does not automatically:

arrive;

return;

unload;

disappear.

43. Pending request at termination

Open requests, reports and cycles freeze as historical terminal state.

They do not generate post-battle supply.

44. HQ under attack and command knowledge

Combat HQ damage is legitimate friendly-side information.

When a Combat HQ takes its first hit or changes structural state, its side generates an:

HQ Under Attack / HQ Damage

status report.

The status contains:

own HQ identity;

structural state;

event timestamp.

45. HQ damage-report latency

For PV0, own-HQ status reaches the side's Commander after:

1 world second

of reliable local command notification.

This is provisional.

Exact damage truth does not jump backward in time.

46. No new strategic recall planner

Receiving HQ damage information does not create a new global recall/teleport behavior in #19.

The Commander may legitimately maintain, hold or adapt existing subordinate intent through the accepted hierarchy.

A new generalized HQ-defense deployment planner is outside this capability.

47. Local defenders

Friendly personnel already in the HQ area continue normal local combat and may fight attackers.

No special defender spawn occurs.

48. Logistics receivers remain protected

Neither Combat HQ damage nor destruction causes physical damage to:

Friendly HQ Logistics Receiver;

Enemy HQ Logistics Receiver;

their stored crates.

Battle termination freezes those facilities before any later activity occurs.

49. Combat HQ and Company staging

Combat HQ and Company staging remain physically distinct locations.

Destroying the HQ does not require destroying staging.

Staging stock does not add HQ Integrity.

50. Combat HQ and protected rear

The protected rear is not the victory objective.

Enemy defeat cannot be achieved by:

exhausting enemy Metal;

blocking production;

emptying HQ Military Stores.

Those actions influence the war through military capability, not through a substitute win trigger.

51. Player agency boundary

The player may:

operate the rear;

choose production;

stage goods;

dispatch friendly rear shipments;

observe the battlefield and HQ result.

The player does not:

order a Squad to attack the HQ;

choose which Platoon assaults;

target rifle shots;

trigger HQ damage manually;

press a "win battle" control.

52. Objective feedback

Normal player presentation should make clear:

Primary objective: Enemy Combat HQ

The player should be able to identify:

own Combat HQ;

enemy Combat HQ objective;

current battle result.

This does not require a final HUD/art treatment.

53. Friendly HQ damaged feedback

Friendly Combat HQ structural-state change may be surfaced to the player as friendly information.

Example:

Friendly Combat HQ — Critical

This is informational, not a tactical command prompt.

54. Enemy HQ damage feedback

Enemy HQ coarse structural state may be shown only when legitimately observable or through an existing legitimate friendly report.

No exact enemy integrity meter is required in normal play.

55. Combat HQ Damage Decision Graph v1.0

Valid hostile rifle hit resolves against Combat HQ?

→ NO
No Integrity change.

→ YES

Consume firing ammunition normally.

Reduce HQ Integrity by 1.

Integrity > 0?

→ YES
Update structural state if threshold crossed.
Battle remains Active.

→ NO
Mark HQ Destroyed at current authoritative world time.
Submit that destruction to Battle Outcome resolution.

56. Battle Outcome Decision Graph v1.0

Battle already terminal?

→ YES
Ignore later outcome events.

→ NO

At current authoritative world timestamp:

Friendly HQ destroyed?

Enemy HQ destroyed?

Neither

Remain Active.

Enemy only

Friendly Victory — Enemy HQ Destroyed

Friendly only

Friendly Defeat — Friendly HQ Destroyed

Both

Draw — Mutual HQ Destruction

On terminal result:

record result/timestamp;

freeze world-time progression.

57. HQ Objective Decision Graph v1.0

Battle Active?

→ NO
No new military decision.

→ YES

Enemy HQ destroyed?

→ YES
Outcome system terminates battle.

→ NO

Current legitimate readiness/command condition permits objective prosecution?

→ NO
Maintain/delay/adapt according to existing accepted hierarchy.

→ YES
Maintain Destroy Enemy Combat HQ as primary objective through the hierarchy.

No direct infantry order is created outside the hierarchy.

58. Squad HQ Assault Decision Graph v1.0

Assigned operational intent ultimately serves Destroy Enemy HQ?

→ NO
Continue existing assigned behavior.

→ YES

Immediate valid local hostile-person engagement?

→ YES
Use existing local combat behavior.

→ NO

Enemy Combat HQ visible, within legitimate rifle range and otherwise valid target?

→ YES
HQ may be selected as combat target.
Fire only through normal rifle behavior.

→ NO
Continue legitimate route toward objective.

59. Shared time

HQ:

damage;

reports;

outcome;

battle termination

use the same authoritative world clock as:

logistics;

command;

movement;

firing.

Pause before battle termination freezes all normally.

Accepted acceleration preserves equivalent outcome at equal world time.

60. View independence

Switching:

rear;

battlefield;

HQ/logistics observation views

must not:

change HQ Integrity;

recreate HQs;

reset damage;

change objective state;

change result timing.

61. Save/load

New campaign/save persistence is excluded.

Historical compatibility checks may remain, but Combat Outcome 01 does not expand save design.

62. Normal F5 requirement

Normal F5 now contains:

Friendly Combat HQ;

Enemy Combat HQ;

both existing command hierarchies;

both physical logistics chains;

primary Destroy Enemy Combat HQ objectives.

Normal entry must not depend on a test-only Battle scene.

63. Focused friendly-victory acceptance

A deterministic focused sector scenario may be authored before initialization to make a legitimate Friendly HQ assault reachable in bounded evidence.

It may:

preserve normal HQ Integrity 12;

preserve normal rifle behavior;

preserve the real hierarchy;

use ordinary ammunition;

use an unobstructed legitimate sector route;

reduce opposing combat pressure through pre-initialization ammunition choice if needed.

It may not:

directly damage HQ;

place HQ already destroyed;

inject shots;

teleport attackers;

bypass hierarchy;

force target selection after initialization.

Require:

Commander objective
→ Company
→ Platoon
→ Squad Leader
→ physical approach
→ ordinary rifle expenditure
→ 12 legitimate HQ hits
→ Enemy HQ 12→0
→ Friendly Victory

64. Focused enemy-victory acceptance

Mirror the same requirement for the enemy side.

Require actual enemy hierarchy and rifle fire to destroy Friendly Combat HQ.

This proves outcome ownership is side-neutral.

65. Commander-death negative acceptance

Demonstrate a state where a Commander dies while their Combat HQ remains above 0.

Expected:

no battle terminal result caused by the Commander death;

HQ remains valid;

existing accepted command/personnel behavior proceeds as applicable.

66. Ammunition-exhaustion negative acceptance

Demonstrate a side with no remaining immediately usable Rifle Ammunition while its Combat HQ survives.

Expected:

no automatic defeat;

battle remains Active unless an HQ is destroyed.

67. Logistics-exhaustion negative acceptance

Demonstrate raw Metal/HQ stock exhaustion with intact Combat HQ.

Expected:

no victory/defeat trigger.

68. Mutual-destruction branch acceptance

A focused branch guard may establish both HQs at:

1 Integrity

with two legitimate already-resolving hostile HQ hits assigned the same authoritative world timestamp.

Expected:

Draw — Mutual HQ Destruction

This guard is only outcome-boundary evidence.

It is not evidence of full autonomous HQ assault behavior.

69. Terminal freeze acceptance

At least one focused victory run must have active non-outcome activity at the terminal moment, such as:

truck travel;

production;

infantry movement;

pending report.

After the result:

world time does not advance;

that activity does not complete;

repeated view switching leaves terminal state unchanged.

70. Evidence expected

Return evidence sufficient to inspect:

both sector-native HQ identities and positions;

initial Integrity 12;

objective propagation through actual hierarchy;

physical movement toward objective;

valid rifle LOS/range;

exact ammunition expenditure for HQ shots;

exact Integrity changes;

terminal timestamp;

result;

terminal freeze;

no Commander-death victory;

no ammunition/logistics-exhaustion victory;

mirrored enemy victory;

mutual-destruction branch;

pause/1x/accepted acceleration/view-history equivalence;

regression of bilateral logistics.

Assertions alone are not acceptance.

No Dawson mechanical QA is requested.

71. Explicit exclusions

Do not add:

HQ repair;

HQ construction;

HQ relocation;

artillery;

fortifications;

capture instead of destruction;

surrender;

retreat victory;

all-personnel-dead victory;

protected-rear destruction;

logistics-receiver destruction;

convoy combat;

campaign transition;

final victory screen art;

final fog-of-war system.

72. Provisional values

Authoritative for PV0 now:

Combat HQ Integrity: 12;

ordinary valid Rifle hit: 1 HQ Integrity damage;

HQ footprint: approximately 6 × 6 design meters;

HQ status-report latency: 1 world second;

no repair;

known enemy objective location;

mutual destruction = draw.

These may later change through recorded design decisions.

73. Design history
PV0-CO01-D01 — Separate Combat HQ and Logistics Receiver

Decision: The battlefield victory objective is a separate sector-native Combat HQ.

Reason: Rear Foundation 03 deliberately introduced a non-combat receiver without deciding battlefield HQ geometry or defeat semantics.

PV0-CO01-D02 — Fixed PV0 sector HQ locations

Decision: Both Combat HQs use authored stable reference-sector locations.

Reason: Outcome must be testable before procedural geography becomes authoritative.

PV0-CO01-D03 — 12 Integrity / rifle structural damage

Decision: Combat HQ has 12 Integrity and each legitimate Rifle hit deals 1.

Reason: Provides a readable bounded structure objective using the existing combat interaction without importing legacy Battle artillery.

Status: Provisional balance.

PV0-CO01-D04 — HQ objective known at scenario start

Decision: Both Commanders know the opposing HQ objective location.

Reason: Primary objective knowledge is authored mission information, not hidden battlefield observation.

PV0-CO01-D05 — No special HQ ceasefire or assault mode

Decision: Existing local combat remains live while forces prosecute the HQ objective.

Reason: HQ assault should emerge through the war simulation rather than replacing it.

PV0-CO01-D06 — Immediate terminal freeze

Decision: Once WAR-01 establishes a result, world-time advancement stops for the current playable session.

Reason: Continuing production, firing or delivery after battle termination would create post-result state that could not affect the resolved battle.

PV0-CO01-D07 — Mutual HQ destruction

Decision: Same-timestamp destruction of both primary HQs produces a draw.

Reason: WAR-01 defeats both belligerents; timestamp equality provides an unambiguous bounded resolution.

PV0-CO01-D08 — No surrender substitute

Decision: Commander death, ammunition exhaustion, logistics exhaustion and personnel annihilation do not replace HQ destruction.

Reason: Keep the currently locked primary-belligerent victory condition explicit.

74. Future compatibility

Any later design adding:

procedural HQ placement;

multiple HQs;

structural weapon categories;

fortification;

repair;

surrender;

retreat;

capture;

campaign transitions;

secondary belligerents;

must explicitly revisit:

HQ objective knowledge;

damage;

outcome;

mutual destruction;

terminal-state behavior.

Engineering returns unresolved product semantics rather than inventing them.

## Focused HQ Assault Load Amendment — 25 October 2026

This amendment clarifies Sections 63 and 64 of Playable Version 0 — Combat Outcome 01: Sector-Native Combat HQs & Battle Termination.

It applies only to the bounded deterministic Friendly-Victory and Enemy-Victory acceptance scenarios.

1. Authorized attacking-side load

For the focused HQ-assault acceptance scenario, designate one actual assault Squad on the attacking side.

That Squad contains four ordinary compatible rifle infantry.

Before battle initialization and before replenishment-target snapshotting, those four infantry begin with:

32 Rifle Ammunition rounds each

Total authored starting ammunition for the assault Squad:

128 rounds

This is an acceptance-scenario starting load, not a weapon-stat change, ammunition grant after initialization, or final carrying-capacity decision.

2. Replenishment-target consequence

The existing replenishment-target rule remains unchanged.

Because those four infantry begin the focused scenario with 32 rounds each, their scenario-start replenishment targets are:

32 rounds each

Do not secretly retain the normal 12-round value as a hidden target or cap.

This remains a replenishment target only; final carrying capacity remains unresolved.

3. Other attacking-side personnel

All other attacking-side personnel retain their ordinary authored starting ammunition for the normal scenario.

Do not increase their loads for this acceptance proof.

Only the four designated assault-Squad rifle infantry receive the focused 32-round starting load.

4. Defending-side ammunition

For the focused HQ-assault acceptance scenario, all ordinary compatible rifle personnel on the defending side may be authored with:

0 Rifle Ammunition rounds

before initialization.

Their replenishment targets consequently snapshot to 0 under the accepted rules.

This is permitted solely to bound opposing combat pressure and keep the evidence focused on legitimate HQ assault and WAR-01 termination.

No defender receives ammunition after initialization unless the already accepted physical logistics systems legitimately provide it.

5. Combat statistics remain ordinary

The focused scenario does not alter:

rifle damage;

accuracy;

fire rate;

range;

line of sight;

movement speed;

health;

suppression;

HQ Integrity;

HQ rifle-hit damage;

command latency;

tactical decision rules.

The attacking infantry use ordinary Rifle Ammunition and ordinary rifle combat.

6. Starting geography

The designated attacking Squad must begin:

outside valid rifle range of the target Combat HQ;

without a valid starting rifle shot against that HQ;

on ordinary representative-sector ground;

with a legitimate traversable route toward the assigned HQ objective.

The focused scenario may author a clear/reachable route before initialization.

It may not start the Squad already at the HQ or inside an artificial damage radius.

The Squad must physically approach through normal sector movement.

7. Objective and hierarchy

The focused scenario uses the normal authored objective:

Destroy Enemy Combat HQ

The objective must still propagate through:

Commander → Company → Platoon → Squad Leader → infantry

The increased starting ammunition does not bypass any echelon.

8. No required logistics assist

The focused HQ-assault proof does not require an ammunition resupply cycle before HQ destruction.

The 32-round starting load exists so the outcome proof is not accidentally blocked by ammunition exhaustion before twelve legitimate structural hits can occur.

If ordinary accepted logistics happen naturally during the scenario, they remain valid, but acceptance must not inject or force them.

9. Required physical assault

Acceptance still requires:

objective propagation
→ physical Squad movement
→ legitimate HQ observation/range
→ ordinary rifle firing
→ real ammunition expenditure
→ 12 legitimate HQ hits
→ HQ Integrity 12 → 0
→ battle terminal result

The authored 32-round load does not count as evidence of any of those later events.

10. No post-initialization assistance

After initialization, the focused assault scenario may not:

grant ammunition;

alter replenishment targets;

move attackers;

move the Combat HQ;

alter HQ Integrity;

inject hits;

force target selection;

force firing;

suppress legitimate local hostile-person engagement;

change objectives;

alter weapon statistics.

All combat and movement after initialization must come from the normal game systems.

11. Mirrored Enemy-Victory evidence

The Enemy-Victory focused scenario uses the exact mirrored rule:

one designated enemy assault Squad;

four ordinary enemy rifle infantry;

32 rounds each before initialization;

target 32 each;

all other enemy personnel retain ordinary authored loads;

ordinary compatible friendly defenders may be authored to 0;

attackers begin outside valid HQ rifle range;

ordinary hierarchy, movement and combat must destroy Friendly Combat HQ.

No side-specific advantage exists in the outcome semantics.

12. Normal default remains unchanged

None of these focused values modifies normal F5 battle initialization.

Normal play retains its existing:

starting ammunition;

replenishment targets;

force composition;

positions;

logistics;

combat behavior.

The 32-round assault load is internal acceptance authoring only.

Design-history entry
PV0-CO01-D09 — Focused assault starting ammunition

Decision: In mirrored deterministic Combat HQ assault evidence, the four ordinary rifle infantry of the designated attacking Squad begin with 32 Rifle Ammunition rounds each before initialization.

Reason: The outcome proof requires twelve legitimate HQ rifle hits after physical approach while ordinary local combat remains active. A bounded higher starting load prevents ammunition exhaustion from becoming an incidental blocker without changing rifle statistics, injecting post-start supply or bypassing the hierarchy.

Target effect: Their replenishment targets snapshot to 32 under the ordinary accepted rule.

Defending pressure: Compatible defending rifle personnel may be authored to 0 before initialization.

Status: Acceptance-only focused scenario; normal gameplay unchanged.

## Commander-Loss Acceptance Clarification — 25 October 2026

This amendment clarifies Sections 29, 30, 65 and the acceptance requirements of Playable Version 0 — Combat Outcome 01: Sector-Native Combat HQs & Battle Termination.

1. No Commander embodiment added

Combat Outcome 01 does not introduce a physical Commander person.

The currently accepted Commander remains the existing logical adjacent-echelon command decision role.

#19 must not add solely for outcome testing:

Commander Soldier/person identity;

Commander health;

Commander position;

Commander weapon/ammunition;

Commander death animation/state;

Commander succession;

replacement Commander selection;

physical Commander movement.

Those are unresolved command/personnel-system questions outside this capability.

2. WAR-01 semantic requirement

The authoritative outcome rule remains:

Only destruction of a primary belligerent's Combat HQ produces that belligerent's WAR-01 defeat in this package.

Therefore loss, absence or inability of command personnel/roles must not independently create:

Friendly Victory;

Friendly Defeat;

Mutual HQ Destruction;

any other terminal battle result.

3. Runtime negative evidence

Normal/focused runtime evidence must demonstrate a real non-HQ leadership/personnel loss while both Combat HQs remain above 0 Integrity.

Valid examples include:

Platoon Leader death;

Squad leadership loss;

extensive infantry casualties;

complete current battlefield-personnel annihilation if naturally or deterministically established.

Expected outcome:

Battle remains Active

unless a Combat HQ has actually reached 0 Integrity.

This evidence must be described using the actual actor that died.

Do not label a Platoon Leader or other Soldier as the Commander.

4. Commander-loss outcome guard

Because the current product contains no killable Commander actor, the specific statement:

Commander loss is not victory

may be verified with an isolated outcome-only Commander-loss guard.

The guard may establish the abstract outcome precondition:

the side's Commander role is considered lost/unavailable

while:

Friendly Combat HQ Integrity > 0;

Enemy Combat HQ Integrity > 0.

Expected result:

Battle remains Active.

No WAR-01 terminal result may be produced from that fact.

5. Guard boundary

The Commander-loss guard proves only:

battle-outcome logic does not treat Commander loss as Combat HQ destruction.

It does not prove or define:

how a Commander dies;

whether Commander is ever embodied;

succession;

communications after Commander loss;

formation behavior after Commander loss;

who assumes command.

Those remain outside #19.

The guard must be labeled as an isolated outcome-semantic fixture rather than normal gameplay evidence.

6. No synthetic gameplay effects

The guard must not be used to:

remove real battlefield orders;

suppress command processing;

create succession;

kill another actor as a proxy;

alter Combat HQ Integrity;

cause or prevent HQ assault.

It tests the outcome boundary only.

7. Runtime command behavior remains existing behavior

Outside the isolated guard, the existing accepted logical Commander and command hierarchy continue unchanged.

Combat Outcome 01 adds no new response to "Commander death" because no such ordinary runtime event currently exists.

If a later design introduces an embodied Commander, that design must separately define:

death;

succession;

information consequences;

command continuity.

WAR-01 will still require Combat HQ destruction unless deliberately amended.

8. Revised negative-acceptance set

#19 now requires three distinct non-HQ negative checks:

A. Real leadership/personnel loss

A real embodied battlefield leader/person dies while HQ survives.

Expected:

Battle Active

B. Commander-loss outcome guard

Abstract Commander-loss fact with both HQs intact.

Expected:

Battle Active

C. Ammunition/logistics exhaustion

A side loses immediately usable ammunition and/or finite logistics supply while HQ survives.

Expected:

Battle Active

None substitute for Combat HQ destruction.

Design-history entry
PV0-CO01-D10 — Commander remains logical in Combat Outcome 01

Decision: #19 does not create an embodied Commander merely to test the negative WAR-01 rule.

Reason: Commander embodiment, health and succession are separate game systems. Introducing them here would expand outcome implementation into unresolved command/personnel design.

Acceptance: Real personnel/leadership loss proves ordinary runtime non-HQ casualties do not terminate battle; a clearly isolated outcome-only Commander-loss guard proves the explicit Commander-loss negative branch.

Status: Authoritative PV0 boundary.
