# T3-LOOP-030 — Two-battle player campaign

Normal project launch now opens `campaign_loop.tscn`. Battle1 uses Operations;
Battle2 uses the existing priority/request-context Operations. Tab switches maps;
rear controls retain workbench placement, finite Worker orders, authorization and
logistics priority. V opens the campaign roster/history without pausing live play.
There are no tactical movement, fire, targeting or outcome controls.

Actual Battle1 EnemyHQ destruction freezes an intermission. Continue alone calls
the accepted Campaign transition. Persistent selected people retain IDs, rank,
qualifications and histories; physical state is freshly constructed. The existing
six-person registry additionally enrolls the existing incident victim P2-B.4 so
the ordinary B1 casualty is visible historically and excluded from redeployment.
The accepted five-person B2 deployment remains unchanged. The living P1-A.1
remains registered but is not selected for that deployment. This loop does not
invent a casualty for the old CAM proof's P1-A.1 fixture.

Save/Reload Intermission uses SAV021's validated BETWEEN_BATTLES values and one
`user://campaign_loop_intermission.json` file. Preparing that checkpoint operates
on detached progression, does not advance B2, and does not mutate the frozen B1.
Reload still requires Continue and builds the same selected fresh priority world.
SAV021 keeps archived outcome/time/HQ-history metadata rather than runtime worlds.
Direct continuation retains the original frozen B1 runtime as well.

Both trucks share the fresh campaign road/bridge state. Priority selects actual
uncommitted stock; physical delivery and ordinary autonomous movement still gate
mission progress and Company artillery release. The ammo technology is selected
through existing card ownership on initial entry; this grants capability only.

Actual B2 EnemyHQ destruction calls guarded Meta settlement once. Final UI shows
two wins, survivor summary, earned1 token and current balance. META is explicit;
the optional existing mortar purchase spends1 on future card eligibility only.
Actual FriendlyHQ destruction in either battle stops progression with the existing
DEFEAT_REWARD_POLICY_DEFERRED outcome, zero successful-completion reward and no B3.

Validation: final model run27 checks pass; full actual-input native renderer run36
checks pass (25 model checks at that revision plus11 UI checks), with11 inspected
milestone images. Two additional inspected native images verify final roster
latest-event wording and final Meta layout. Final panel/entry/import logs have no
script errors. All29 previous focused model suites pass, including SAV31/RSM33,
Campaign32/Meta34/PRI31/CTX21. Evidence is under ignored `artifacts/loop_*`.
The exact time0 capture temporarily freezes only the harness's physics for one
frame; the player roster panel itself keeps live simulation running.

Human evaluation remains pending: the frozen intermission and retained identities
make continuity explicit; fresh time0, empty stock/work and additional demand make
B2 distinguishable. The roster remains dense and the same authored geography and
rear labor can feel repetitive. The first delivery's movement consequence is
visible, but meaningful agency, pacing and fun require human play. These are
observations, not acceptance claims. No procedural campaign, additional battles,
personnel management, final defeat rewards, arbitrary multi-chain active saves,
migration or final Meta shop was added. PA-LOOP001..003 remain provisional.
