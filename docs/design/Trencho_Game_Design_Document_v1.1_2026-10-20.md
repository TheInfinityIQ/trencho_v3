# Trencho Game Design Document

**Version 1.1 · 20 October 2026 · Designer-owned product specification**

Trencho lets the player build and operate a protected logistics base that supports an autonomous military institution. The player shapes what the army can do through people, production, equipment and technology, then observes a physical war conducted by commanders with limited information.

This GDD defines the intended experience and the rules that make it coherent. It is a tool for game designers to frame bounded developer tasks. It is not a software architecture specification, a backlog, or permission to build every described feature.

## How to use this document

The game designer owns product meaning, player behavior, scope and design acceptance. Developers choose technical implementation within the issued task. A developer may identify feasibility problems and propose changes, but a change to player agency, information access, resource ownership or intended behavior returns to the designer for a decision.

The latest human direction takes precedence. This version incorporates the supplied v1.0 and subsequent confirmations of the shared clock, one military Building Material resource, separately crafted tools and category-compatible ammunition. It supersedes v1.0 wording where these differ. Existing code and developer reports describe implementation; they do not silently revise product intent.

**Design status is separate from implementation status.** A rule described here is not a claim that it exists in the game, has passed engineering checks or has been evaluated by players. Desired final-release systems are not automatically part of the next task.

Sections 1–25 retain the source GDD’s system coverage. Added identifiers such as `LOG-01` and `INF-01` identify product rules and examples that can be cited in a task. They are not class names, data schemas or prescribed algorithms. Appendix D collects unresolved design decisions; Appendix E explains how designers derive tasks and assess results.

**Reading priorities:** Start with player agency in section 3, command in section 7, knowledge in section 9, equipment and construction in sections 12–14, and progression in section 18. Consult the relevant open decisions before issuing a task.

## Document Purpose and Authority

This document consolidates the current product vision after the battlefield-alignment review. It is intended to prevent future implementation from proving a technically correct but semantically wrong abstraction. The design is intentionally deep on system behavior and intentionally light on balance constants, entity statistics and content volume.

Authority: Use this document as the current product-direction authority for future design and implementation planning. Existing prototype code is evidence and reusable infrastructure, not a definition of the final game.

Source basis: the prior Trencho Generation 2 GDD, the October 2026 system-alignment discussion, the attached clarification document, and the subsequent contradiction-resolution decisions made with the player/designer. No external research is required to interpret the product direction described here.

### Status Vocabulary

| Label | Meaning |
| --- | --- |
| LOCKED DIRECTION | A core product rule. Change it through an explicit designer revision within the human’s mandate, not an incidental implementation choice. |
| PROVISIONAL | A candidate direction to evaluate. Its exact behavior must be selected in a bounded design task before it becomes an implementation requirement. |
| DEFERRED | A desired or plausible system that should not block the next coherent vertical slice. |
| TUNING TBD | The mechanism is defined but numerical values, rates, capacities or thresholds are intentionally not assigned yet. |

## 1 Product Identity and North Star

North Star: Build and operate the logistics machine that enables a military institution, then watch autonomous command hierarchies fight a persistent physical war using the people, equipment, technology, infrastructure and information they actually possess.

Trencho is an indirect-control war-machine, logistics and autonomous-command strategy game. The battlefield is not an autobattler in the lane-based or collision-driven genre sense. Two or more hierarchical military AIs are effectively playing an RTS-like war against one another, while the human player acts upstream in a separate logistics space and observes the consequences on the battlefield.

### 1 1 Core Fantasy

- The player is the logistics authority, not the battlefield commander.
- The player physically inhabits and builds a protected logistics base, decides what to produce, may perform work manually, and assigns workers to automate production.
- The military may draw from the player-owned rear stock only within the player’s authorization. It can also obtain resources through explicitly supported battlefield capture, local production and cooperation. Once resources enter military control, the command hierarchy decides how to employ them.
- Senior commanders generate operational objectives autonomously. Intent is decomposed downward through companies, platoons and squads until individual soldiers execute local actions.
- The battlefield persists and tells its own story through formations, casualties, wrecks, damaged infrastructure, smoke, fortifications, changing civilian life and physical supply movement.
- The player can visually observe more than military command necessarily knows. Asking for information does not grant omniscience.
- A war can continue meaningfully with zero battlefield input from the human player.

### 1 2 Design Pillars

| # | Pillar | Consequence |
| --- | --- | --- |
| 1 | War exists without you | Battlefield competence cannot require tactical player orders. |
| 2 | You build capability; command employs it | Player agency is strongest in production, labor, procurement, technology and investigation. |
| 3 | Hierarchy decomposes intent | Higher command states goals; lower echelons decide how to accomplish them within authority. |
| 4 | People and equipment physically exist | Soldiers, workers, vehicles, weapons, ammunition and supplies are not decorative counters. |
| 5 | Information has provenance and latency | Observation, reporting and command knowledge remain separate from objective reality. |
| 6 | Logistics changes behavior | Scarcity, transport and availability materially alter what military AI can do. |
| 7 | The world remembers the war | Battlefield aftermath persists and becomes useful evidence and storytelling. |
| 8 | Strategy beats arbitrary AI randomness | Variation comes from state, uncertainty, competence, personality and resources, not deliberate stupidity rolls. |
| 9 | Technology is built through the deck | Faction color does not define equipment. The campaign deck defines manufacturing access; captured equipment remains usable when skills and support permit. |
| 10 | No tactical puppetry | The player does not routinely move squads, choose targets or solve firefights. |

### 1 3 Genre Description

Primary internal description: autonomous military command simulation with a hands-on logistics-management and roguelike technology layer. "Autobattler" should not be used as the primary design shorthand because it encourages overly abstract, lane-based or collision-driven implementations.

## 2 Setting Match Structure and Victory

### 2 1 Setting

For the current product direction, Trencho is set on an alternate-history Earth using an approximately World War II-era technological vocabulary without binding the game to historical nations, events or faction technology trees. The setting provides recognizable infantry organization, weapons, trucks, artillery, radios, factories, towns and field engineering while allowing fictional belligerents and outcomes.

Future setting expansion: Colonized worlds using a similar technological vocabulary remain a possible future direction. The current game should not be architected around space travel or space combat.

### 2 2 Battle and Campaign Structure

- A single battle is currently targeted to feel like a 30-45 minute real-time experience. This is a pacing target, not a balance guarantee.
- A roguelike campaign contains multiple battles with persistent campaign personnel, commanders, deck/capabilities and organizational history.
- The long-term campaign map/sequence is not yet fixed. It may become more dynamic over time.
- Large battles should be semi-infrequent. Commanders should normally contest smaller strategic objectives with portions of their forces instead of repeatedly committing one giant army blob.

### 2 3 Belligerents

- The war supports 2 to N primary belligerent command structures.
- Primary belligerents do not form normal alliances with one another. Avoid systems that naturally collapse every multi-sided war into coalition dogpiles.
- Diplomacy and alignment can exist with neutral/minor actors rather than between primary belligerents.
- AI belligerents should use the same command hierarchy and battlefield logic as the player-aligned military. Their protected rear logistics may be automated rather than player-operated.

### 2 4 Victory

Victory condition: Destroying a primary belligerent's HQ immediately eliminates that belligerent from the battle.

- Strategic objectives do not award arbitrary victory points. They matter because they provide resources, capabilities, positioning, population, industry, cover, access or other advantages that help destroy the enemy HQ.
- In a two-belligerent battle, destruction of the opposing HQ ends the battle immediately.
- In a battle with three or more primary belligerents, the defeated side is eliminated as a major belligerent, while its surviving military personnel retain their existing hierarchy as far as practical and become a permanent minor/rebel actor. Personnel at the destroyed HQ are presumed killed by the terminal event.
- Minor/rebel actors cannot restore themselves to full primary-belligerent status during the same battle under the current design.

### Battle outcome boundaries

**WAR-01 — Headquarters defeat.** HQ destruction is an immediate defeat event for that primary belligerent. Killing a commander elsewhere is a personnel/succession event; it is not a substitute victory condition. Capturing a town, exhausting ammunition or losing a battle does not independently satisfy HQ destruction.

In a two-sided battle, enemy HQ destruction ends the battle immediately. In a multi-sided battle, eliminating one opponent need not end the battle: its survivors remain as minor actors and other primary belligerents continue. The natural win condition is to become the last primary belligerent, but player defeat, simultaneous HQ destruction and campaign transition behavior must be settled under D-07 before that task is issued.

**Example for design acceptance:** In a three-sided battle, destroying one AI HQ must not delete all surviving soldiers or automatically award the player victory. The eliminated force cannot become a primary belligerent again during that battle.

## 3 Player Role and Core Loops

### 3 1 Player Avatar

The player has a unique, aesthetically customizable avatar that physically inhabits the logistics map. The avatar is not drawn from the population pool, does not enter the battlefield and cannot die because the logistics area is a protected, separate map. Cosmetic items may be unlocked as persistent player rewards.

### 3 2 Player Agency Boundary

| Player may directly control | Player does not routinely control |
| --- | --- |
| Avatar movement and interaction in logistics space | Battlefield unit movement |
| Free placement of logistics buildings and work areas | Squad/platoon tactical orders |
| Manual crafting or operation of workbenches | Target selection and moment-to-moment combat |
| Worker assignment and production automation | Subordinate command planning |
| Exact production choices and quantities | Military convoy route micromanagement after resources are released |
| Resource authorization: Available / Reserve N / Locked | Frontline ammunition handoffs or individual battlefield resupply orders |
| Campaign card purchases, drops and technology unlock choices | Directly choosing operational military objectives |
| Battlefield observation and binocular inquiries | Injecting player-observed truth into command knowledge |

### 3 3 Macro Loop

1.  Receive people and raw-material shipments in the protected logistics area.

2.  Build and arrange facilities, storage, loading areas and workspaces.

3.  Personally craft or assign workers to automate production and support tasks.

4.  Use campaign technology cards to unlock equipment, organizations and production capabilities.

5.  Set rear-owned stock to Available, Reserve N or Locked.

6.  Military logistics physically collects authorized goods and moves them into the battlefield supply chain.

7.  Autonomous command turns resources into operational action.

8.  Observe the battlefield, environmental aftermath and command-reported history.

9.  Adjust production, staffing, technology and authorization based on what the war appears to require.

10.  Win or lose the battle, carry campaign-persistent people/capabilities onward, and eventually conclude or abandon the roguelike campaign.

### Player agency contract

**PLY-01 — Logistics choices affect possibilities, not orders.** The player decides production, staffing, capability access and authorization of rear stock. Providing artillery does not order a bombardment. Releasing ammunition does not select a target. Unlocking engineering does not choose a battlefield bridge location.

**PLY-02 — Observation is not command.** Selecting a soldier, moving the camera, opening a stat card and querying a place do not move troops, nominate attack objectives or write player-only observations into command knowledge. Whether an inquiry can request new information collection is separately unresolved in D-03; it must not be implemented as a disguised tactical order.

**PLY-03 — Local labor has an opportunity cost.** Workers and potential recruits are the same kind of persistent person. Assigning a person to rear labor and sending that same person forward cannot produce two copies. The avatar is separate from this population.

**Experience question:** Can the player recognize a useful production or staffing choice after watching the war, without needing to take control of a squad to make progress? This remains a play-evaluation question, not something a unit test proves.

## 4 Time Model

Design direction: Use one authoritative world clock for both logistics and battlefield systems. Do not create a separate logistics-day timeline that reconciles in batches.

The battle should represent more in-world time than the player spends in real time. The exact compression factor is tuning TBD. Movement, combat, weather, civilian schedules, production, training, construction and communication all advance against the same world time.

### 4 1 Time Controls

- Pause: globally pauses the simulation and allows inspection/management.
- Normal speed: intended default play speed.
- Fast-forward: confirmed alongside global pause and normal speed. It advances the same world clock for logistics and battlefield. Exact speed options remain tuning TBD.
- Slow-motion is not currently required.

### 4 2 Manual Work and Time

When the player avatar manually operates a workbench or performs another job, the action consumes the same compressed simulation time as equivalent worker labor. Manual work is useful when automation is unavailable or when the player chooses to spend their own attention rather than assign labor.

### 4 3 Weather and Day Night

- Weather events are desired and should eventually affect terrain, visibility, roads, movement, cleanup and possibly combat.
- Day/night cycles remain provisional. Do not architect them out, but do not make them a near-term blocker.

### Shared time contract

**TIM-01 — One clock.** Changing the viewed map must not stop, accelerate or reset the other map. Pause stops progression in both. Fast-forward advances both, including production, movement, reports, training and manual work. A paused player may inspect or configure management choices, but cannot obtain completed labor or deliveries without world time advancing.

**TIM-02 — No independent production day.** Logistics cannot accumulate a separate day's output and inject it into an earlier battlefield moment. Communication delay and travel time use the shared timeline.

**Example for design acceptance:** Begin a production job and a military shipment, then change views. Both continue according to world time. Pause freezes their progress; resuming preserves progress. The example specifies player-visible behavior, not a required scheduling algorithm.

The five-minute event-history window and the 30–45-minute battle target still need an explicit real-time versus world-time definition where relevant; see D-02.

## 5 World Terrain and Strategic Geography

### 5 1 Map Model

Battlefield gameplay occurs on a continuous top-down 2D map. Fixed combat lanes, mandatory StrategicArea boxes and predefined collision zones are not product assumptions. Geography should create problems that commanders must solve.

### 5 2 Terrain

- Infantry can traverse most terrain without roads.
- Tracked and half-tracked vehicles can operate off-road.
- Off-road wheeled vehicles such as armored cars can leave roads where terrain permits.
- Ordinary road vehicles require roads. Tracked, half-tracked and designated off-road wheeled vehicles may travel off-road where terrain permits. Damaged roads may remain passable to road vehicles at extreme slowdown and with a risk of becoming stuck. A route planner must not turn an ordinary truck into an off-road vehicle merely because the road is inconvenient.
- Terrain can provide resources. Forests may supply wood and wildlife; rivers and bodies of water may supply food; other natural features may provide scenario-specific resources.
- Terrain influences movement, visibility, concealment, cover, tactical routes and strategic value.

### 5 3 Strategic Locations

- Towns and villages
- Bunkers and defensive sites
- Natural passes, crossings, clearings, low-tide routes and other geographic chokepoints
- Factories and depots
- Farms and food-producing areas
- Military bases and camps
- Rebel forts and displaced-person camps
- Roads and bridges
- Abandoned settlements
- Historical sites such as castles and older forts

Objectives are valuable because of what they physically or economically enable. Commanders should be pressured to take risks because surrendering useful geography makes the enemy stronger or constrains future operations.

### 5 4 Control and Fronts

Control is embodied. If a force leaves an area, it loses control unless some meaningful occupying presence remains, such as a manned fortification. "No people, no control." Front lines are visual interpretations of actual occupied and contested space, not authoritative game objects that exist independently of formations.

## 6 Population Personnel and Identity

### 6 1 Persistent People

Soldiers, workers and civilians are individual entities with persistent identity. This does not require every person to be simulated at full frequency at all distances. Use simulation level-of-detail so nearby/relevant people receive detailed updates while distant populations retain identity and state at lower update frequency.

### 6 2 Civilian Jobs and Aptitudes

- Civilians may have existing occupations of varying rarity.
- Civilian job experience can provide subtle aptitude advantages when later trained for related military or industrial skills.
- Any person can train new skills given sufficient time and resources; background should influence efficiency, not hard-lock careers.
- Workers assigned to the logistics base are drawn from the same population that could otherwise be trained and sent to HQ.

### 6 3 Rank Role Qualification and Acting Appointment

| Concept | Definition |
| --- | --- |
| Rank | Formal military authority. Promotions are relatively rare and distinct from skill proficiency. |
| Role | Current functional job: rifleman, machine gunner, medic, squad leader, driver, etc. |
| Qualification / skill | What a person has been trained to do and how proficient they are. |
| Acting appointment | Temporary command responsibility assumed during an engagement when the formal leader is unavailable. |

### 6 4 Skills and Qualifications

Skills should form broad parent categories with more specialized child expertise. Parent training permits competent general use; child specialization improves efficiency. Example: Firearms -> rifles, machine guns, sniper weapons, pistols, shotguns. Specialist families may include flamethrowers, bazookas, grenades/assault equipment, mechanics, engineering, aviation, ordinary driving and tracked-vehicle driving.

### 6 5 Veterancy and Promotion

- Veterancy should be subtle. It primarily changes what tasks, command options and responsibilities a person can credibly perform rather than producing huge generic combat multipliers.
- Promotion is separate from skill efficiency.
- A squad can appoint a replacement acting leader in the field only when a suitably ranked and qualified person is available. Exact eligibility is a design decision to settle before implementing succession; weapon proficiency alone does not confer command authority.
- Formal promotion cascades should occur after the immediate engagement rather than causing disruptive hierarchy reshuffles mid-firefight.

### 6 6 Legendary Soldiers

Exceptional soldiers may become Legendary. Their exploits are remembered in a persistent memorial outside campaigns. A legendary person may reappear in later campaigns even if they died in a previous run; this is meta-level recurrence, not a claim that one continuous historical timeline resurrected them.

### Identity and eligibility contract

**PER-01 — A person survives changes of assignment.** Training, changing weapons, joining a squad, taking acting command and entering rear work preserve the person's identity and history. Death ends that person's current-run service; Legendary recurrence belongs to a later campaign.

**PER-02 — Distinct attributes.** Rank grants formal authority; qualification permits a kind of work; proficiency affects how well it is done; role is the present assignment. None automatically substitutes for the others. A tool kit supplies equipment, not qualifications. A promotion does not refill ammunition, heal injuries or create a new soldier.

**Example for design acceptance:** A skilled rifleman may change weapon assignment without being promoted. A qualified acting leader can temporarily lead without receiving a permanent rank increase. The exact eligible successor and what a leaderless squad does are open design decisions D-04, not reasons to invent universal instant promotion.

## 7 Military Organization and Command

Hierarchy: Operational Commander -> Company -> Platoon -> Squad -> Individual Soldier

### 7 1 Objective Decomposition

The military hierarchy is not a stack of synchronized state machines receiving the same order. Each level receives intent appropriate to its authority and decomposes it into more local problems.

1.  Operational command chooses a major objective, such as taking a town, securing a bridge, holding a corridor or destroying an enemy concentration.

2.  Company command decides which platoons participate, what remains in reserve, where to stage, which avenue of approach to use and how to sequence the mission.

3.  Platoon leadership coordinates squads, assigns local tasks and keeps the platoon geographically coherent.

4.  Squad leadership selects local routes, positions, formations, fire elements and immediate tactical responses while still pursuing platoon intent.

5.  Individual soldiers execute local movement, cover, firing, reloading, equipment handling and other immediate behaviors under squad leadership.

### 7 2 Physical Location of Leaders

- Operational and company-level command normally operate from HQ/command-post positions rather than fighting as ordinary riflemen.
- Platoon leaders should be physically with or near their platoons, able to coordinate subordinate squads in the field.
- Squad leaders physically remain with their squads.

### 7 3 Adaptation Failure and Authority

- Subordinates can adapt plans within the intent they were given.
- A lower leader may abandon an objective when there is no credible chance of success.
- Such decisions can have career consequences if higher command judges them as failure, cowardice or insubordination.
- That judgment is made from the superior's own plausibly available information, including later reports, not omniscient world truth.
- This permits objectively correct decisions to be misunderstood and objectively poor decisions to escape punishment when information is incomplete.

### 7 4 Coordination

- Peers may coordinate when assigned to the same task.
- If two companies share an operational objective, their commands may cooperate rather than acting as isolated agents.
- Command and coordination messages use the same communication media and latency rules as information reports.

### 7 5 Succession

Every military person can die. If a leader dies during combat, an eligible subordinate may assume acting command so the mission can continue coherently. Formal reorganization and promotion occur after the immediate engagement, avoiding a cascading permanent promotion event in the middle of tactical contact.

### Command responsibilities and communication

**CMD-01 — Each echelon adds decisions.** Operational command selects the objective; company command commits and organizes platoons; platoon leadership coordinates squads; squad leadership solves local tactical problems; soldiers execute immediate actions. One identical attack state copied to every level does not satisfy this hierarchy.

**CMD-02 — Decisions have reasons and constraints.** Leaders use the information available to them, the authority they hold and resources they can actually employ. They may pursue, adapt, stage, withdraw or abandon a task when permitted by the design. They must not claim to execute an impossible plan through teleportation, free equipment or knowledge they have not received.

**CMD-03 — New intent must arrive.** Sending an order is not the same as a subordinate receiving it. Reports and peer coordination likewise need the appropriate communication path. Exact message failure, expiry and replacement rules require D-03 before implementation.

**CMD-04 — Judgment is knowledge-bound.** A superior may assess a subordinate using information received later, but not information that remains unknown to that superior. A decision may be reasonable in local circumstances and still be judged poorly. The final punishment catalog and its triggers remain design work.

**Design example:** Company command wants a crossing secured. A platoon assigns one squad to cover and another to approach. A squad leader encounters an unexpected obstacle and changes the local route. That local choice does not require the player or top commander to select individual cover positions. A delayed report means company command may continue to hold an outdated assessment.

**Observe in a playable evaluation:** Do the lower leaders visibly contribute to the plan, and can the player understand why a force is staging or withdrawing? Logging can establish causal implementation; it cannot establish whether this is compelling to watch.

## 8 Autonomous Planning and Decision Making

### 8 1 Best Perceived Option

AI chooses the best option it can perceive under its current knowledge, authority, resources, competence and personality. There is no generic "AI stupidity chance" whose purpose is to force obviously worse actions for variety.

### 8 2 Commander Competence

- Command competence comes from the person occupying the role and their stat/skill profile.
- Competence may influence planning quality, estimation accuracy, logistics forecasting, use of reserves, interpretation of reconnaissance, risk evaluation and coordination.
- Difficulty should improve or degrade these capabilities rather than granting omniscient information or hidden combat multipliers.

### 8 3 Commander Personality

Personality may influence risk tolerance, logistical caution, willingness to disengage, reserve preference, reporting style and other decision tendencies. Personality does not define faction technology.

### 8 4 Player Influence on Command

Operational objectives are generated autonomously. The player does not presently dictate what town to capture or what front to attack. The player influences war indirectly by deciding what people, supplies, equipment and technologies become available. Direct strategic priority control can be revisited only if later playtesting demonstrates a clear benefit.

### 8 5 Commander Replacement

Commanders arise from the generated personnel population. The player may eventually spend a resource to remove/demote a commander or vouch for another candidate. Vouching adds weight to an autonomous internal selection process rather than directly appointing any arbitrary person. Vacancies cascade through appropriate ranks after the current engagement.

## 9 Information Communication and Knowledge

### 9 1 Three Information Layers

| Layer | Meaning |
| --- | --- |
| World State | Objective authoritative reality: what physically exists and what actually happened. |
| Player Observation | What the human can directly see on the battlefield presentation. This may exceed command knowledge. |
| Command Knowledge | Facts that have been observed and plausibly delivered through military communication. Binocular inquiry is bound to this layer. |

### 9 2 Knowledge Records

Maintain one authoritative world state, but do not give every command direct access to it. Observations create knowledge records with provenance and time. A command may use only records that have reached it. This preserves information latency without requiring an elaborate conflicting-report/deception model.

### 9 3 No Active Deception Initially

- Initial design avoids deliberately contradictory reports.
- Unknown information may be omitted or represented approximately rather than filled with invented falsehoods.
- Estimate quality may later depend on reconnaissance/observation skill.
- Active interception, deception and information warfare are deferred possibilities, not current requirements.

### 9 4 Command Propagation

Orders move downward through communication media just as reports move upward. Communication quality therefore affects both what commanders know and how quickly subordinate organizations receive new intent.

### 9 5 Reconnaissance

Infantry is the initial reconnaissance capability. Vehicles, aircraft, dedicated scouts and other reconnaissance methods can be added later as distinct tools. Different capabilities should improve different stages of detection, observation, reporting, communication or interpretation rather than collapsing into a generic intelligence percentage.

### Knowledge boundaries

**INF-01 — Truth is not shared awareness.** An enemy moving in the world does not update every command. A fact can be known to one squad, absent at company HQ and visible to the player at the same time.

**INF-02 — Time belongs to information.** A report describes what was observed at its observation time. Receiving it later does not make it a current exact location. The interface must distinguish an old report from current observation when that distinction affects understanding.

**INF-03 — Unknown is a valid result.** An inquiry must be able to return no established information, incomplete history or approximate information. Missing evidence must not be filled with a confident invented cause. Avoiding active deception does not eliminate uncertainty, stale information or different commands knowing different things.

**INF-04 — Friendly inspection is an explicit player privilege.** Exact friendly living-person and vehicle inventories are available through normal inspection as agreed. That UI access does not transmit the same information to military commanders or grant exact enemy inspection. Do not generalize this exception into an omniscient battlefield dashboard.

**Example for design acceptance:** The player sees a convoy destroyed before HQ receives the report. The destruction exists, but a command-bound history query cannot yet assert its full circumstances. After the report arrives, the history may change and should retain the original event time. See D-03 for which command's knowledge supplies that inquiry.

## 10 Movement Navigation and Tactical Execution

### 10 1 Individual Spatial Presence

Individual soldiers physically occupy the battlefield. They are not decorative sprites attached to a platoon token. Their local movement is subordinate to squad behavior, but they require enough independent navigation to move around terrain, maintain spacing, use cover and execute fire-team behavior.

### 10 2 Squad Cohesion and Fire Elements

- Squads generally remain close to their squad leader and geographically coherent.
- Squad leaders may split a squad into temporary fire/maneuver elements when the tactical problem justifies it, such as suppressing and flanking a machine gun or sniper.
- Platoons should remain geographically cohesive even when squads have separate local tasks.

### 10 3 Formation and Doctrine

Movement posture should reflect context. A squad expecting no resistance may march in an orderly formation; contact, terrain or doctrine may require dispersion, bounding, flanking or use of cover. Where authentic doctrine provides clear patterns, it should inform AI behavior, while local AI remains available for novel situations.

### 10 4 Cover

Cover is environmental and dynamic. Buildings, rocks, parked cars, non-burning wrecks, trenches, sandbags, bunkers and other obstacles can create useful positions. Because the world is destructible, cover representation should support dynamic creation/removal rather than rely exclusively on a permanently authored cover-point list.

### 10 5 Assembly and Staging

Commanders may establish temporary assembly/staging areas anywhere suitable; they are not restricted to fixed FOBs. FOBs, command posts and infrastructure improve staging but do not monopolize it.

### Movement and physical presence

**MOV-01 — Individuals matter spatially.** Two soldiers belonging to one squad can occupy different cover, carry different ammunition and suffer different outcomes. Their positions must affect relevant local interactions; visual offsets around an indivisible platoon token are insufficient.

**MOV-02 — Cohesion is organizational, not a rigid shape.** Squad and platoon cohesion constrain behavior without requiring soldiers to overlap, move in lockstep or maintain parade formations during combat. Temporary fire elements remain part of their squad.

**MOV-03 — A route can fail.** A blocked road, destroyed crossing or unreachable destination must create an observable inability to proceed, followed by behavior appropriate to the leader's authority. A failed route must not be reported as arrival. Exact replanning and fallback choices belong to the bounded design task; navigation algorithms belong to developers.

**Example:** Destroying a bridge should change the viability of a truck route. It must not cause ordinary trucks to cross the river on foot or bypass the restriction as off-road vehicles.

## 11 Combat Morale and Casualties

### 11 1 Detection and Engagement

- Units cannot intentionally engage enemies they have not detected.
- Line of sight, terrain, observation capability and local awareness matter.
- Small-arms engagement should resolve from shooter/target geometry, cover, weapon characteristics, skill and current tactical state.

### 11 2 Small Arms vs Area Effects

| Combat type | Authoritative model |
| --- | --- |
| Small arms | Do not require every bullet to exist as a physics object. Resolve line of fire, cover and hit outcome; visual tracers/muzzle effects may represent the exchange. |
| Explosives / area effects | Use real spatial impact/effect locations. Geometry, nearby entities, obstacles and destructible cover affect the result. |

Examples of spatial area effects include mortar rounds, grenades and flamethrower-like weapons. An obstacle between an impact and a soldier can reduce or prevent the effect depending on the ordnance and obstacle. Cover destroyed by the event may still provide protection during that event according to the eventual combat rules; full damage is not automatic merely because the cover ends destroyed.

### 11 3 Suppression

Suppression is a tactical constraint more than a generic damage debuff. It changes which actions are credible or available: a squad pinned by machine-gun fire should not casually choose an exposed charge. Exact suppression values are tuning TBD.

### 11 4 Morale

Morale primarily exists at squad level. Routing should be possible but relatively rare because soldiers normally possess baseline trust in leadership.

- Primary morale inputs should include casualties, leader loss, suppression, isolation, flanking, nearby friendly retreat, supply problems, veterancy and commander reputation.
- Low morale may reduce tactical options or eventually cause autonomous routing even when formal command wanted the squad to hold.

### 11 5 Casualties and Medical Care

Combat should eventually distinguish more than alive/dead. Wounded personnel, medics, medical supplies, field hospitals and recovery/evacuation are desired. The exact injury model is deferred, but architecture should not assume every casualty is an instant permanent death.

### Combat causality

**COM-01 — Contact changes choices before casualties alone.** Suppression can prevent an exposed maneuver even when nobody has died. Squad morale and suppression are related influences but are not interchangeable labels.

**COM-02 — Local geometry matters.** Cover and impact location affect the soldiers actually exposed. A visual explosion cannot arbitrarily apply the same result to every member of a platoon because they share an organizational identifier.

**COM-03 — Casualties preserve consequences.** A dead soldier stops acting and their equipment remains physically accounted for until recovery, looting or destruction. Wounded-person categories and recovery are deferred design, not permission to turn every casualty into instant death or automatic healing.

**Example for design acceptance:** Two soldiers from the same squad stand on opposite sides of a protecting obstacle. An area effect can have different consequences for them. Numerical damage and blast penetration are tuning; whether geometry matters is a product rule.

A future combat task must choose a small weapon and casualty subset explicitly. The final-release list is not a requirement to build all weapon types in the first slice.

## 12 Weapons Equipment and Combined Arms

### 12 1 Weapon Abstraction Level

Use meaningful weapon classes rather than an excessively granular industrial catalog. Candidate categories include bolt-action rifle, semi-automatic rifle, assault rifle, machine gun, submachine gun, sniper weapon, shotgun and pistol, plus specialist/area weapons. A campaign card may define which specific model fills a class slot, but the player should not need to mass-produce several near-identical bolt-action rifle models merely for variety.

### 12 2 Ammunition Compatibility

All belligerents use the same weapon-category and ammunition-category definitions. Every bolt-action rifle accepts bolt-action rifle ammunition, regardless of model, origin or current owner. The same category-based rule applies to semi-automatic rifles, assault rifles, sniper rifles, machine guns, submachine guns, pistols and other defined categories. Do not add caliber, faction or model compatibility restrictions within a category. Captured weapons follow exactly the same rule. Compatibility between different categories is not implied.

### 12 3 Captured Equipment

Rule: Deck technology controls what the player can reliably manufacture, not what a soldier is physically allowed to pick up and use.

- Weapons, supplies and vehicles may be captured and reused if personnel have appropriate skills and supporting resources.
- Captured supply caches create a reason to seize positions intact rather than always destroy them with artillery.
- Captured technology does not automatically unlock permanent manufacturing unless a separate campaign rule explicitly grants such capability.
- Rarely subordinating a neutral force may provide access to its unit types or technology as a special consequence.

### 12 4 Combined Arms Ambition

Final-release ambition includes infantry, vehicles, artillery, air support, machine guns and mortars. Infantry, vehicles and artillery should be developed earlier than the rest once the command hierarchy and individual-soldier foundation is proven.

### Ammunition and equipment contract

**EQP-01 — Shared categories across all sides.** A weapon model belongs to an agreed gameplay category, and ammunition compatibility follows that category. A captured bolt-action rifle can use the capturing side's bolt-action rifle ammunition immediately if someone can operate the weapon. Compatibility does not require a faction conversion, a technology card or a matching manufacturer.

**EQP-02 — Category names are gameplay definitions.** Historical descriptions can overlap: a real-world sniper rifle might also use a bolt action. Developers must not decide compatibility from historical terminology. Before adding such a weapon, the designer assigns its gameplay category. Cross-category compatibility is not assumed.

**EQP-03 — Capture is not manufacture.** Picking up a weapon transfers possession of an existing item. It does not manufacture another copy or automatically unlock its production. A technology unlock enables a defined capability; it does not by itself create stock unless the card is explicitly a consumable grant.

**Example for design acceptance:** A friendly soldier recovers an enemy bolt-action rifle and compatible bolt-action ammunition. The rifle is usable despite not being manufacturable from the current deck. Pistol ammunition does not satisfy the rifle's ammunition requirement. The old owner's inventory cannot retain the recovered copy.

Exact reload quantities, magazine handling, carrying capacity and weapon-category catalog are deferred; the shared compatibility rule is fixed.

## 13 Engineering Fortifications and Destruction

### 13 1 Field Engineering

- Engineers specialize in roads, bridges, reinforced defenses, mines, barbed wire, Czech hedgehogs, buildings and advanced fortifications.
- Ordinary infantry may perform approved low-skill fieldwork at lower efficiency. A basic shovel enables permitted digging work; advanced specialist work requires the appropriate specialization toolkit and qualified personnel. The task catalog must explicitly state which work requires Building Material in addition to tools and labor. A shovel does not grant engineering qualifications.
- New roads are possible but should be major commitments. Bridges can be constructed. Paths through forests can be cleared manually or by sufficiently capable heavy equipment.

### 13 2 Materials

The military uses exactly one generic Building Material resource for construction. Logistics may consume several distinct inputs, such as wood and metal, to manufacture it. Frontline recipes must not introduce separate wood, metal, concrete or other construction-material currencies. Specialization toolkits and basic shovels are separately crafted equipment, not additional building materials. Skills, tools, labor and Building Material are separate requirements. Local improvisation remains desired, but its conversion rules must be designed before implementation; it must not silently create a parallel construction economy.

### 13 3 Destruction and Repair

- Everything significant should be destructible in principle.
- Destroyed buildings transition to a destroyed-building state rather than being progressively erased into featureless ground.
- Roads can be damaged and repaired. Damage should strongly penalize road vehicles before complete impassability is necessary.
- Vehicles and buildings/fortifications require maintenance after damage; general passive equipment degradation is not currently desired.

### Construction and tools contract

**BLD-01 — One military material.** Building Material is the single military construction resource. Its rear recipe may consume several logistical inputs. Requiring military units to separately obtain timber, steel and concrete would contradict this rule.

**BLD-02 — Tools are separate equipment.** Basic shovels and specialization toolkits are crafted and supplied separately. A qualified engineer without a required toolkit is not fully equipped; an unqualified soldier with the toolkit is not thereby qualified.

**BLD-03 — Each activity states its requirements.** A designer-defined construction activity must name required skills, tools, labor, Building Material if any, and the resulting structure or terrain change. Unreinforced digging and supplied construction must not be conflated. Toolkit durability, sharing, consumption and the material costs of individual activities remain D-05.

**Examples for design acceptance:**
- Ordinary infantry carrying a shovel can perform the permitted basic digging activity; possessing Building Material alone does not enable that activity without the shovel.
- Reinforced works may require Building Material and an appropriate specialist capability. Holding a shovel alone does not unlock every fortification.
- Manufacturing Building Material in the rear consumes the specified recipe inputs and produces only that output. It does not also create a toolkit.
- A local-resource improvisation feature must explicitly define how its output fits the same military resource model.

These examples define meaning, not recipe quantities or construction durations.

## 14 Logistics Supply and Physical Inventory

### 14 1 Ownership and Authorization

Rear-owned resources are not automatically military-owned. The player decides availability; the military decides employment after authorized resources cross the boundary.

| Player policy | Meaning |
| --- | --- |
| AVAILABLE | Military may draw from the eligible rear stock as legitimate need arises. |
| RESERVE N | Military may draw only the amount above the player-specified reserve floor. |
| LOCKED | Military may not draw the resource. |

Committed/allocated inventory is not a fourth player policy. It is stock already accounted for by the logistics system and must not be double-counted.

### 14 2 Resource Families

- Fuel
- Ammunition families
- Medical supplies
- Individual weapons and equipment, including separately crafted specialization toolkits and basic shovels
- Building Material, the single generic military construction resource
- Rear raw/industrial inputs including metal, wood and fabric
- Finished outputs such as repair kits, medkits, uniforms, weapons, ammunition and vehicles

### 14 3 Individual Inventories

Each soldier carries their own equipment and ammunition. Vehicles and containers have their own inventories. Squad-level planning may compute aggregate availability, but this total is derived from member inventories rather than a magical squad stockpile.

- Squadmates physically transfer compatible ammunition when close enough.
- If a soldier dies, the items on that soldier remain on the battlefield unless recovered, looted, destroyed or otherwise removed.
- Soldiers can offload equipment to trucks when appropriate.
- Resupply should show credible loading/restocking behavior without animating every individual cartridge or item transfer.

### 14 4 Military Logistics

- Transportation assets, drivers, fuel and cargo are physical resources.
- Command may establish depots and intermediate stockpiles.
- Higher logistics command can prioritize scarce supply and deliberately starve a quiet area to support an important operation.
- Convoys can be interdicted, destroyed or captured.
- Military logistics does not mine/refine the homeland raw economy; it moves finished or field-usable resources within the war system.

### Stock and transfer contract

**LOG-01 — Availability is not location or ownership.** AVAILABLE, RESERVE N and LOCKED regulate military access to rear-owned stock. They do not teleport it to a squad. Military collection, transport and distribution remain separate actions.

**LOG-02 — No double allocation.** A resource committed to one outgoing shipment is not also available for another shipment, rear production or an additional inventory total. A transfer changes where a resource is accounted for; it does not duplicate it.

**LOG-03 — Reserve governs new draw.** At a new allocation decision, military access must respect the chosen reserve and existing commitments. Exact stock-account semantics and policy changes affecting already committed goods require D-06. Do not implement LOCKED as retroactive deletion of cargo already in military possession.

**Illustrative accounting case, not a balance constant:** There are 100 uncommitted units in the rear and RESERVE 30. At most 70 are eligible for a new military draw. Once 50 are committed, a second allocation cannot draw those same 50 again. The reserve is a protected quantity, not a newly created pile of 30 additional units.

**LOG-04 — Physical custody matters.** Equipment carried by a soldier is not simultaneously in a vehicle. Equipment on a dead soldier is not a living squadmate's ammunition until recovered. Nearby sharing is a transfer, not remote access to a global pool.

**LOG-05 — Loss and capture have consequences.** Destroyed cargo cannot arrive later as usable supply. Captured cargo moves into the captor's custody; the original owner cannot spend it again. Command awareness of the loss may lag the physical event.

**Experience question:** Can a player connect a shortage, a delayed convoy or captured supplies to a change in military behavior without being required to inspect a debug ledger?

## 15 Rear Logistics Base Production and Workers

### 15 1 Separate Protected Map

The player-operated logistics area is a separate protected map, not physically contiguous with the battlefield and not attackable. It is connected conceptually through shipment entry/exit points such as roads, docks or rail stations.

### 15 2 Free Spatial Construction

- Facilities and work areas use free spatial placement rather than fixed lots.
- The player walks the base with WASD-style direct control.
- The physical arrangement should matter enough to feel like a place the player builds, without requiring unrealistic conveyor-belt automation.
- Small tactile activities such as clearing rocks or performing simple manual work can occupy the player during waits, provided they remain optional and do not become mandatory busywork.

### 15 3 Production

- The player makes exact production decisions and may manually produce goods when necessary.
- Workers automate jobs by being assigned to facilities/workstations.
- Production requires time and appropriate inputs/capability.
- Raw inputs arrive as shipments from outside the simulated homeland economy. The game does not currently simulate mines, national textile industries or other upstream extraction systems.
- The player may retain skilled people in industry or train/send them forward to HQ, creating a labor-versus-military-specialist tradeoff.

### 15 4 Logistics Space Activities

A light Stardew Valley-like layer is acceptable as a pacing tool: clearing space, breaking rocks, carrying out simple chores, manually operating benches or interacting with deliveries. Such activities should support the logistics fantasy rather than become a second unrelated crafting game.

### Production and population contract

**REA-01 — Technology, inputs, equipment and labor are distinct.** Owning a production capability is not the same as having inputs, a workstation or a worker. A completed output must arise from the appropriate job and costs, not merely from selecting a card.

**REA-02 — Manual work uses the same world.** Player labor and worker labor operate against the shared clock. Automation lets the player attend to something else; switching to battlefield view must not erase assigned workers' progress.

**REA-03 — A protected rear still connects causally.** The rear is not attackable, but its exports enter a vulnerable military supply chain. The two maps' connection must preserve resource identity and avoid simultaneous stock at both ends. Entry/exit representation, travel delay and collection ownership require D-06.

**REA-04 — A worker cannot serve twice.** Assigning someone to training or sending them forward must resolve their current rear job. The exact cancellation, reassignment and replacement behavior is D-01; it cannot silently leave their productive labor active after departure.

**Design example:** A skilled person operates a workshop. Sending them to military training may provide a useful specialist later, but the workshop loses that person's labor. The player's meaningful choice is the tradeoff, not a free copy of the worker.

Do not invent a continuous income source, infinite free manpower or an export-reward economy merely to make a prototype run indefinitely. A task may use clearly labeled starting stock or fixtures until D-01 is resolved.

## 16 Civilians Towns Occupation and Minor Actors

### 16 1 Civilian Life

Civilians are individuals with homes, jobs, local relationships and changing circumstances. Their detailed behavior may use simulation LOD, but identity persists. Damage to homes and workplaces can create unemployment, homelessness, hunger, desperation and political consequences.

### 16 2 Local Sentiment and Collective Action

- Different individuals within one town may hold different opinions of a belligerent.
- Towns may also make collective decisions, including votes on local action.
- Looting, destruction, occupation behavior, protection, food support and casualties can change sentiment.
- Long or threatening wars can generate militias, sympathizer groups, rebels and warlords.
- War lords may prey on civilians or small military groups for equipment or prisoners.

### 16 3 Occupation and Factory Labor

Captured factories or economic sites do not automatically function. A belligerent can send its own workers, offer supplies/resources to gain local cooperation, or compel/enslave the local population. These choices should differ in productivity, resentment, sabotage risk, flight, rebellion and future recruitment consequences.

### 16 4 Minor and Neutral Forces

- Neutral armed forces may rarely become subordinate to a primary belligerent.
- Defeated primary-belligerent survivors become permanent minor/rebel actors in multi-sided battles.
- Minor actors can possess distinct unit types or technologies that may become accessible through subordination/capture.
- Primary belligerents do not form normal alliances with one another.

### Civilian and occupation boundaries

**CIV-01 — Civilian consequences have causes.** Destroyed homes and workplaces change the circumstances of the affected individuals. Sentiment, desperation and group formation respond through the intended social systems rather than appearing as unrelated random event spawns.

**CIV-02 — Occupation belongs to autonomous command.** The player controls the protected rear and its contributions. Battlefield occupation and factory employment are military decisions within the existing agency boundary, unless a later design revision explicitly grants another player action.

**CIV-03 — Taking a factory is not teleporting its output.** Workers, inputs, operational condition, local control and a way to move output must matter. Occupation alone cannot deposit unlimited goods into the protected rear.

Prisoners, forced labor, starvation and displacement are consequential parts of the intended setting, but their detailed mechanics, presentation and content boundaries require an explicit design task. The examples here do not constitute a fully specified prisoner or coercion system.

**Experience question:** Can the player understand why a town becomes more cooperative, hostile or unstable from what happened there, rather than from an unexplained attitude number?

## 17 Battlefield History Binoculars and Environmental Storytelling

### 17 1 Environment First

The battlefield should communicate history through physical aftermath before relying on UI event markers. Dead soldiers, wrecked vehicles, smoke, damaged infrastructure, abandoned positions, shell damage, discarded supplies, ruined fortifications and civilian responses are evidence generated naturally by play.

### 17 2 Persistence and Cleanup

- Major aftermath persists for the entire game unless another system changes it.
- Rain can wash away blood and small debris.
- Townspeople may loot/bury bodies after an area has been safe for a meaningful period.
- Wildlife may consume corpses in appropriate settings.
- Friendly recovery parties may reclaim bodies/equipment and potentially provide a small economic benefit.
- Artillery or further destruction can obliterate piles of bodies or other aftermath.

### 17 3 Binocular Mode

Core interaction: Activate binocular mode, then click essentially any battlefield location. The inquiry asks: "What can our side establish about this place?"

- Binocular inquiry is not restricted to predefined zones or event icons.
- The player may click an apparently empty forest, a pile of bodies, a destroyed convoy, a town street or any other location.
- Inquiry output is command-knowledge-bound. The player may personally have seen something that military command cannot yet confirm.
- Initial reporting should prefer known/unknown/approximate information over speculative narratives. A speculative reporting layer may be added only if playtesting supports it.
- The textual interface should present a dated/time-stamped log of what the military knows happened at that location.

### 17 4 Holographic Ghost Reconstruction

When sufficient known history exists, binocular mode may enter an interruptible reconstruction cutscene using ghost soldiers and other reconstructed actors. It visualizes what friendly command has established, not omniscient truth.

- Known friendly participants appear when established.
- Known enemy participants appear when established.
- Unknown causes remain unknown: if an explosion killed soldiers but command never identified whether it came from a tank or artillery, the reconstruction must not invent an answer.
- Information learned later can enrich the reconstruction of an older event.

### 17 5 Event Overlay

An optional event-history overlay begins toggled off and highlights locations of player-visible events from approximately the previous five minutes as a navigation aid. It does not replace environmental storytelling and does not grant command knowledge. The five-minute window is provisional pacing, not a balance constant.

### Investigation and reconstruction contract

**HIS-01 — Query locations, not authored answer buttons.** Binocular inquiry can target ordinary locations, including apparently empty places. A location without established history produces an honest lack of information. It is not remapped into one of three fixed scenario answers.

**HIS-02 — Reconstruction is evidence-bound.** A ghost sequence depicts only established participants, actions and causes. An unknown attacker does not become visible simply because the world engine knows who fired. Later evidence can enrich the reconstruction without changing what physically happened.

**HIS-03 — Overlay and inquiry have different sources.** The optional overlay records player-visible event locations and starts off. The inquiry and ghost history remain command-bound. Selecting a marker does not convert personal observation into military evidence.

**HIS-04 — Cleanup changes evidence, not the past.** Recovering a body or removing debris must not retroactively mean the casualty never happened. Conversely, a permanent history record must not leave a duplicate physical corpse after cleanup.

**Example for design acceptance:** Command knows a friendly soldier was killed by an explosion but does not know the firing source. The reconstruction can show the established casualty and explosion without inventing a tank or artillery crew. If evidence later establishes the source, the history can become more complete.

The query footprint, source command, five-minute time basis and whether reconstruction pauses the world remain explicit decisions D-02 and D-03.

## 18 Deck Technology and Roguelike Campaign Progression

### 18 1 Technology Identity

- Faction identity is primarily color/presentation. Equipment and technology are determined by the campaign deck and unlocked card pool.
- Commander identity does not select a national tech tree.
- Cards should unlock or transform real mechanisms: equipment classes, production methods, organizational capability, engineering, communications, reconnaissance, staffing, etc.
- Baseline resource economy must remain viable without lucky card draws. Resource/personnel/equipment cards may provide one-off windfalls but are not the primary source of war sustainment.

### 18 2 Meta Unlock Pool

Outside an active campaign, the player owns a persistent pool of unlocked cards. Meta currency earned from completed campaigns is spent through a slot-machine-like unlock experience that expands this pool. The player may be able to blacklist a limited number of unlocked cards from appearing; the exact quantity is tuning TBD.

### 18 3 Campaign Card Drops

- During a campaign, the player purchases card drops using campaign-earned currency/rewards.
- Drops are tiered from Tier 1 through Tier 5. A drop contains cards only from the purchased tier.
- The player may be able to pay for category-constrained drops such as a weapon drop, or choose a cheaper broad drop.
- A drop presents multiple card choices (current design example: three) and the player chooses one.
- Technology/equipment cards enter the current campaign hand/capability set; consumable cards may be used immediately.
- A held-card combination/recipe system is an optional future experiment, not a locked requirement.

### 18 4 Campaign vs Meta Persistence

| Scope | Persists |
| --- | --- |
| Within one battle | All ordinary world state, soldiers, commanders, equipment and history. |
| Across battles in one campaign | Surviving soldiers/commanders, campaign deck/capabilities, organizational history and other run state. |
| Across separate campaigns | Meta card unlock pool, player knowledge/unlocks, avatar cosmetics, memorial/Legendary Soldier records and other explicit meta progression. |

### 18 5 Campaign Exit

Accessing the out-of-campaign slot-machine/meta shop requires ending the current campaign. Abandoning a campaign grants no completion rewards. Successful campaign completion awards meta currency based on performance; exact scoring is tuning TBD.

### Progression contract

**CAR-01 — Four different things.** The meta unlock pool determines which cards can become available across campaigns. Campaign acquisition gives the current run a card. Activating a technology card enables its stated capability. Physical production creates equipment. These are separate events and must not be collapsed into one inventory counter.

**CAR-02 — Same-tier offers.** A Tier 1 drop contains only Tier 1 candidates; a Tier 5 drop contains only Tier 5 candidates. The example of three offered cards is not yet a locked offer count. Optional category-constrained drops and combination recipes remain provisional.

**CAR-03 — Consumables resolve once.** A resource/personnel/equipment card explicitly grants its defined windfall when used. It must not remain repeatedly redeemable unless a future card design explicitly says so. Such windfalls do not replace the ordinary sustainment economy.

**CAR-04 — Run and meta state do not leak.** The current run's acquired technology hand is lost when that campaign ends. The meta unlock pool remains. Ordinary campaign personnel do not automatically appear in a new campaign. Legendary recurrence is an explicit exception to design, not accidental survival of the old army.

**CAR-05 — Abandonment is not a reward shortcut.** Accessing the meta shop requires concluding or abandoning the active run; abandonment grants no campaign completion rewards. The rules for defeat rewards and previously earned rewards are D-08.

**Example for design acceptance:** Unlocking a card in the meta pool does not instantly grant it to the current campaign or place its weapon into soldiers' hands. Capturing that weapon during battle can still permit its use without the card.

The persistence of the physical rear base, workers, stocks, vehicles, injuries and map aftermath between battles needs an explicit transition design. “Other run state” is not sufficient permission to choose arbitrary persistence.

## 19 UI Camera Readability and Player Information

### 19 1 Battlefield Camera

- Top-down camera with broad pan/zoom.
- Strategic zoom is desirable: higher zoom levels emphasize formations and geography; closer zoom reveals more individual soldiers, bodies, debris and environmental detail.
- The battlefield should remain understandable without exact numeric overlays.

### 19 2 Friendly Unit Inspection

- Friendly living units may expose exact stat cards appropriate to the player's own organization.
- Friendly living soldiers and vehicles may expose exact inventory directly without binocular mode.
- Destroyed vehicles and dead soldiers are not directly inventory-inspectable through the normal unit card; they become environmental evidence/recovery targets instead.
- Exact direct stat-card and inventory inspection is a friendly-only privilege. Enemy information is shown through supported observation/intelligence, with unknown or approximate fields where appropriate; it does not grant direct access to the enemy entity inventory.

### 19 3 Information Readability

The UI must distinguish direct visual observation from command-established knowledge. Seeing an enemy or explosion is not the same as the military organization having received and interpreted a report about it.

## 20 Persistence Save Replay Performance and Inspectability

### 20 1 Persistent World

The authoritative world must retain enough history to support environmental aftermath, command reporting, binocular reconstruction, personnel careers, promotions, campaign progression and post-run analysis.

### 20 2 Inspectable AI

- Important command decisions should be reconstructable as decision -> reasoning -> outcome.
- Logging should record what happened, what information a command possessed, what alternatives it considered and what it chose.
- The same logging approach should benefit player-aligned and AI-aligned command hierarchies.
- Debug/omniscient views must remain separate from player-facing information.

### 20 3 Determinism and Replay

Deterministic/replayable simulation remains valuable for debugging, AI analysis and regression even though the final experience is a physical battlefield rather than an abstract simulation dashboard. Replay infrastructure should preserve causal ordering and information flow.

### 20 4 Performance Strategy

- Use level-of-detail simulation for civilians and potentially distant soldiers/activities without erasing persistent identity.
- Do not require every bullet to be a physics entity.
- Strategic zoom can also reduce visual/animation detail when the camera is far away.
- Persistent aftermath may use representation LOD while preserving meaningful state.

### Evidence and technical freedom

**EVD-01 — Three acceptance questions.** Design acceptance asks whether delivered behavior matches the issued requirement. Engineering verification asks which implementation checks were actually performed. Player evaluation asks whether the experience works for the human. Record these separately.

**EVD-02 — Preserve semantics when optimizing.** Lower-frequency updates and visual simplification may reduce cost, but must not silently create ammunition, erase civilian identity, grant command omniscience or make outcomes depend on which map the player watches. Developers choose the architecture and propose tradeoffs where preserving behavior is costly.

**EVD-03 — Diagnose without exposing everything to the player.** Developer diagnostics may inspect objective truth. Player interfaces must still honor the agreed information boundaries. Debug features are not automatically product features.

Save/load behavior and supported replay guarantees need an explicit task scope. The existence of replay infrastructure is not evidence that a complete campaign can already be saved, restored or deterministically replayed.

## 21 Art and Audio Direction

### 21 1 Visual Goal

The battlefield should read as a lived-in war rather than a diagram or flowchart. Art should communicate hierarchy, geography, aftermath and logistics through the world itself. UI markers are secondary aids.

### 21 2 Scale Aware Presentation

- Zoomed out: recognizable formations, front geography, roads, objectives, convoy movement and broad combat activity.
- Medium zoom: squads, tactical movement, fortifications, vehicles and combat posture become legible.
- Zoomed in: individual soldiers, bodies, equipment, debris, cover use and environmental storytelling become richer.

### 21 3 Audio

Audio should reinforce spatial causality: distant artillery, small-arms contact, engines, workbench activity, loading, alarms, weather and local civilian ambience can provide information before the player opens an overlay. Exact audio system design is deferred.

## 22 Superseded Prototype Assumptions

Important: The following may exist in current code or previous documents but should not be treated as intended final product rules.

- Platoon as the indivisible authoritative maneuver actor.
- Representative soldier sprites that do not exist as individual battlefield entities.
- Three fixed horizontal combat lanes or fixed route columns as the world model.
- Fixed StrategicArea boxes as the only valid inquiry target.
- Fixed event icons as the primary means of understanding battlefield history.
- A generic lane-like attack/defend/retreat loop as the intended command hierarchy.
- Artificial scenario reinforcement/ammunition feeders as the final upstream economy.
- The term "autobattler" as the primary genre definition.
- Faction/commander choice determining equipment technology.
- An omniscient shared command belief state.
- The four-state prototype procurement vocabulary where Direct Commitment is a permanent player-facing stock policy. Current intended policy is Available / Reserve N / Locked, with committed stock tracked separately.

## 23 Do Not Infer

- Individual soldiers existing does not mean soldiers choose operational objectives.
- Autonomous war does not mean lane collision or passive auto-combat.
- The player avatar existing does not mean the avatar can enter combat or die.
- Player visual observation does not update command knowledge.
- Binocular inquiry does not reveal omniscient truth.
- Friendly exact unit inspection does not imply exact enemy inspection.
- Deck technology does not make captured enemy equipment unusable.
- Cards do not replace the ordinary resource and production economy.
- Primary belligerents do not form alliances merely because a war has three or more sides.
- Neutral cooperation does not imply a general diplomacy/coalition system.
- Persistent bodies/wrecks do not mean nothing can ever clean them up; cleanup itself must be an in-world process.
- Historical inspiration does not require exact WWII nation/faction reproduction.
- The current absence of day/night, active deception, air power or advanced medicine does not mean the architecture should prohibit them.

## 24 Deferred Tuning and Open Design Questions

The following items are intentionally not locked because they should be answered by prototyping/playtesting rather than invented prematurely.

| Area | Open / tuning TBD |
| --- | --- |
| Unit composition | Exact squad/platoon/company sizes, weapon allocations and reinforcement package sizes. |
| Combat | Hit probabilities, suppression thresholds, morale curves, casualty rates, weapon cadence and explosive radii. |
| Time | Exact world-time compression, fast-forward speeds, construction/production/training durations. |
| Weather | Specific event types, severity, road effects and forecastability. |
| Day/night | Whether a full cycle materially improves play enough to justify implementation. |
| Medicine | Injury categories, stabilization, evacuation, recovery and permanent disability. |
| Recon | Exact estimate precision model and later dedicated scout/recon vehicles/aircraft. |
| Deck | Meta currency rates, drop prices, blacklist count, exact card counts/rarities and whether card-combination recipes are worth keeping. |
| Campaign | Number of battles, branching structure, final campaign victory goal and difficulty ramp. |
| Civilians | Scale of voting, collective actions, starvation/desperation thresholds, militia formation and warlord emergence. |
| Occupation | Exact productivity/sentiment consequences of cooperation, requisition and forced labor. |
| Logistics mini-activities | Which physical chores remain fun and optional rather than repetitive busywork. |
| Strategic objectives | Exact objective-generation algorithm and value forecasting. |
| Audio/art | Final visual style, animation fidelity and sound-information language. |

### Open decisions are not all tuning

Section 24's numerical items can often wait for testing, but some unresolved choices change player behavior or system meaning. Appendix D distinguishes those decisions from ordinary implementation freedom. A task should resolve only the entries it actually depends on; the entire list is not a prerequisite for all progress.

An implementation may expose adjustable values without inventing final balance. It may not disguise an unanswered product question as a configurable constant and treat every setting as accepted design.

## 25 Recommended Validation Sequence

This section proposes an order for evaluating design hypotheses. It is not an implementation dispatch, an approved roadmap, or authorization to resume development. The human’s latest stop/resume instruction governs. Each selected slice needs its own bounded designer task and player-facing question.

1.  Hierarchical infantry proof: one small battlefield with companies, platoons, squads and individual soldiers. Operational command creates a simple objective; the hierarchy decomposes it; squad leaders maneuver real soldiers; no player tactical orders.

2.  Information proof on the real battlefield: reports propagate, command knowledge lags player observation, binocular mode works at arbitrary coordinates, and a known casualty site can reconstruct a partial ghost replay without omniscience.

3.  Physical supply proof: individual inventories, squad ammunition transfers, military requests, transport, capture and resupply affect tactical behavior.

4.  Rear logistics proof: player avatar, free building placement, manual work, worker assignment, production automation and Available / Reserve N / Locked authorization feed the same battlefield.

5.  Persistent-world proof: bodies, wrecks, damage, civilian cleanup/recovery and location history remain causally coherent over a complete battle.

6.  Combined-arms expansion: vehicles and artillery join only after infantry hierarchy, information and logistics already feel correct.

7.  Roguelike campaign proof: multiple battles preserve campaign personnel/deck state; meta card unlocks and Legendary Soldier memorials persist appropriately.

## Appendix A Current Locked Product Decisions

- Alternate-history Earth with an approximately WWII-era technological vocabulary for the current product direction.
- Protected, separate player-operated logistics map with a customizable immortal player avatar.
- Free logistics-base construction and manual/automated production.
- Workers are real people who could instead be trained and sent to HQ.
- Continuous physical battlefield with individual soldiers and civilians.
- Command hierarchy: Operational Commander -> Company -> Platoon -> Squad -> Soldier.
- Player does not tactically control battlefield units or choose operational objectives in the first intended implementation.
- Platoon leaders accompany their platoons; squad leaders accompany squads.
- Small-arms projectile flight may be abstracted; explosive/AoE effects require spatial impact resolution.
- Squad morale, suppression and rare autonomous routing are real systems.
- Captured weapons, supplies and vehicles can be reused when skills/support permit.
- No primary-belligerent alliances; neutral/minor diplomacy may exist.
- HQ destruction immediately defeats a primary belligerent.
- Player observation can exceed command knowledge; binocular results cannot.
- Event overlay is optional, initially off, and is secondary to environmental storytelling.
- Cards define technology/capability, not faction identity.
- One authoritative world clock links logistics and battlefield.
- Commanders may judge subordinates using incomplete information rather than omniscient truth.

## Appendix B Product Level Causal Chains

### B 1 From Player Workbench to Firefight

Shipment arrives -> player stores inputs -> player or worker produces equipment -> stock becomes Available above any reserve -> military logistics collects it -> HQ/depots distribute it -> individual soldiers receive/carry it -> squad/platoon/company plans change because capability or supply changed -> battlefield outcome changes -> aftermath and reports become observable -> player adapts logistics.

### B 2 From Commander Intent to Soldier Action

Operational objective -> company plan -> platoon task decomposition -> squad local plan -> soldier movement/cover/fire -> local outcome -> squad/platoon report -> higher command updates knowledge -> next plan.

### B 3 From Battlefield Event to Player Understanding

World event -> direct visual evidence and/or local military observation -> report propagation -> command knowledge -> binocular location history / partial reconstruction. Player-only observation never shortcuts the military reporting chain.

## Appendix C Revision history

v1.0 replaces the earlier abstract-front battlefield interpretation with a hierarchical physical-war model containing real individual soldiers, subordinate tactical leadership, a separate hands-on logistics base, persistent civilian life and battlefield history. Existing deterministic logistics, communication, replay and information-separation work remains valuable infrastructure where compatible with this product model.

**v1.1** incorporates the human’s later clarifications, sharpens ownership and knowledge boundaries, adds product-rule references and acceptance examples, and separates unresolved design from developer discretion. No development work is authorized by this revision.

## Appendix D Design decisions to settle when relevant

These are designer-owned questions, not requests for the human to answer everything now. Defaults or experiments below are not accepted rules. Before issuing a dependent task, the designer should resolve the smallest necessary subset, using available context and asking the human only when the choice materially changes the vision.

| ID | Decision and why it matters | Resolve before |
| --- | --- | --- |
| D-01 | How raw materials and people are obtained, paid for and scheduled; baseline sustainment; training and production cancellation; the handling of workers sent forward. Avoid inventing free supply or a market. | Playable rear economy or recruitment task |
| D-02 | World-time compression; fast-forward options; whether the event window means five real or world minutes; reconstruction clock behavior; meaning of the 30–45-minute target under time controls. Global pause, normal and fast-forward are already confirmed. | Time controls, history retention or pacing task |
| D-03 | Which command's knowledge answers binocular inquiries; query area/footprint; whether asking can trigger collection; order replacement/expiry and communication failures. No automatic player-to-command truth injection. | Inquiry and communication task |
| D-04 | Acting-command eligibility, behavior without an eligible successor, what ends an engagement for promotion, and how vacancies propagate. | Succession and command failure task |
| D-05 | Specialist toolkit catalog, who carries/shares it, whether it is reusable, exact activity requirements, and local material conversion. One military Building Material resource is fixed. | Field engineering and toolkit task |
| D-06 | Rear-to-battlefield transfer point, commitment ownership, pickup delays/cancellation, effect of later reserve changes and inventory units. No duplication or remote delivery. | Physical export and procurement task |
| D-07 | Player HQ defeat in a multi-sided battle, simultaneous HQ destruction, who can destroy a final HQ, and the exact win/lose transition. Immediate primary-belligerent elimination is fixed. | Battle termination task |
| D-08 | Defeat versus success rewards, campaign currency sources, shop timing, retained rewards after abandonment, starting capabilities, and card activation/hand limits. Abandonment yields no completion reward. | Campaign economy and progression task |
| D-09 | What moves to the next battle: base layout, workers, stock, vehicles, injuries, surviving minor actors and physical map history; how starting positions are formed. | Multi-battle campaign task |
| D-10 | Final gameplay weapon categories and assignments, especially overlapping labels such as sniper versus bolt-action; reload/carrying units. Do not add within-category compatibility restrictions. | Weapon content and inventory task |
| D-11 | Initial casualty subset, recovery/evacuation rules and persistence of injury; food and hunger scope for soldiers versus civilians. | Medical, survival or civilian economy task |
| D-12 | Factory operation/capture/recapture, civilian autonomy, occupation behavior, prisoner systems and what minor-actor subordination unlocks. | Civilian and occupation task |
| D-13 | Save/resume guarantees, required replay coverage and treatment of in-progress transfers/orders on restoration. | Save or campaign persistence task |
| D-14 | What the player can directly see through terrain or fog, limits of sound cues, and whether unexplored areas are visually available. Player sight exceeding command knowledge does not automatically mean unrestricted omniscient vision. | Battlefield visibility and UI task |

**Other deliberate deferrals:** exact formation sizes; weapon and vehicle roster; tactical doctrine library; suppression and morale thresholds; weather types; day/night inclusion; card prices, rarity distribution and blacklist count; campaign branching and final goal; art style; audio fidelity. These need appropriate design work, but do not justify reopening already settled core rules.

## Appendix E From designer intent to developer tasks

### Ownership

The GDD remains owned by game design. The designer selects a coherent behavior slice and explains the player-facing reason. Developers select suitable technical designs, structures, algorithms and tools. Their feasibility feedback may reveal a product choice; they should surface that choice rather than silently alter the intended game.

Do not issue “implement the GDD” as a task. The document includes final-release ambitions, provisional ideas and unresolved decisions as well as firm rules.

### A compact task brief

For a selected task, use only the fields that help:

1. **Goal:** What should the player observe, understand or be able to do?
2. **Basis:** GDD version, relevant sections/rule IDs, and the accepted starting behavior.
3. **Required behavior:** Trigger, actor, available information, action, feedback and consequence. Include one ordinary case and important failure/edge cases.
4. **Boundaries:** What must remain unchanged, what is excluded, and which Appendix D decisions have been resolved for this task.
5. **Acceptance:** Observable design cases plus the smallest useful player evaluation. Identify the necessary engineering evidence without prescribing implementation.
6. **Ownership and stopping point:** Implementing owner, dependencies, delegated choices and when the result returns for design review.

Any temporary prototype simplification must be explicit, bounded and labeled as such. A fixture can supply starting resources for a proof; it cannot silently redefine the final economy. A simplified display can reduce detail; it cannot claim individual soldier behavior when soldiers are only decorative.

### Example of a task derived from this GDD

**Illustration only — not an issued task.** Demonstrate compatible ammunition recovery from a captured bolt-action rifle scenario. Reference EQP-01, EQP-03 and LOG-04. Use one existing rifle category and an explicit, limited transfer scenario. Show that compatible ammunition can be used across belligerents, that possession is transferred once, and that capturing the weapon does not unlock manufacturing. Exclude weapon catalog expansion, full scavenging AI and campaign progression. The developer chooses data representation and implementation.

This example is intentionally smaller than “build captured equipment.” It verifies one important rule without implying that every recovery, ownership and UI system is already approved or present.

### Review and acceptance

A delivery report should separate:

- **Design match:** Which required behaviors are demonstrated and which are incomplete?
- **Engineering evidence:** What was directly inspected or run, and what was only reported?
- **Player evaluation:** What was actually tried, what question it answered, and what remains uncertain?

A valid status might be “design match accepted on reported engineering evidence; player evaluation pending.” Passing tests is not proof that autonomous war is interesting, logistics is satisfying or history reconstruction is understandable.

A review result closes or revises the bounded task. It does not authorize new development beyond the human's mandate or override a stop instruction.

## Appendix F Revision scope and source traceability

**Source:** Trencho Game Design Document v1.0, dated 20 October 2026, supplied by the human from the previous Video Game Designer chat.

**Later human decisions incorporated:** shared world clock with global pause and fast-forward; one military Building Material resource manufactured from potentially multiple rear inputs; separately crafted specialization toolkits and basic shovels; universal ammunition compatibility within each gameplay weapon category, including captured equipment.

**Clarifications added in v1.1:** explicit distinction between product rules and task scope; authority and information boundaries; material versus tool requirements; capture versus production access; physical custody and no double accounting; time and persistence boundaries; examples of observable design acceptance; a register of unresolved behavior decisions.

**Not claimed:** complete software architecture, final balance, a fully specified task for every system, independent engineering verification, or player approval of an implemented experience.

**Continuity:** Use this version as the working design reference together with later human decisions. Keep subsequent revisions explicit about which rules change. Preserve the original v1.0 as historical reference; do not let an old prototype or completion report silently supersede the current design.
