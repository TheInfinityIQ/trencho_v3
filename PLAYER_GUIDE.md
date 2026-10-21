# Play the operations slice

Open **operations.tscn** in Godot and press **F6**.

For competing requests, open **priority_operations.tscn** instead. Two formations
physically stage and each requests eight rounds. The right panel keeps Request-A
and Request-B separate, showing requested/delivered/remaining, priority and state.
In the Rear, **PRIORITIZE REQUEST-A/B** selects one outstanding request; **ALL NORMAL**
restores oldest-first ordering. Priority selects eligible, uncommitted stock only.
LOCKED and the RESERVE floor still govern whether stock may be committed at all.

To see scarcity matter, produce one Worker batch, mark B PRIORITY, then choose
AVAILABLE. B owns those eight rounds through loading, shipment and physical truck
delivery. Changing A to PRIORITY afterward cannot take B's stock. Produce another
real batch for A; only its own later delivery restores A's readiness. Both formations
continue their existing missions autonomously. A two-batch Worker order also works.

Press **C / REQUEST CONTEXT** in either map to compare established friendly
assignments: A is **MAIN EFFORT**, with its existing objective task; B is **SUPPORT**,
with its existing support task. The comparison also shows the shared mission ID,
real ammunition/readiness reason, request age, delivered amount and information
sources. Assignment time describes an established command record; the separate
own-Supply time describes direct friendly logistics. Neither is an enemy forecast.
The panel offers facts, not a recommended winner. Priority remains your Rear choice;
opening context does not move the camera, switch maps or issue formation orders.

Your formation has a mission, but not enough ammunition. You operate its protected
rear. Soldiers, vehicles and commanders act autonomously.

1. Watch the battlefield until the eight-round supply request appears.
2. Press **Tab** to enter the protected rear. Move your avatar with **WASD**.
3. Press **P**, then click free ground to place a workbench. Stand nearby and
   press **E** once. Four world seconds of work turns one Metal into eight rounds.
4. The finished rounds remain **LOCKED**. Choose **AVAILABLE [1]** to authorize
   military use. **RESERVE [2]** protects the number beside it; **LOCKED [3]**
   blocks new allocations. Already committed or travelling rounds are not recalled.
5. Press **Tab** to watch the shipment reach military receiving, then the truck
   physically reach your formation. Its mission resumes automatically. Newly
   supplied rounds are used in combat; Company assigns the final HQ fire task
   after the infantry reaches its objective.

In the rear, choose **1–3 batches** beside **WORKER ORDER [F]**, then click the
button or press **F**. The worker walks to the bench and completes that finite
order while you observe either map. Each batch consumes one Metal when it starts
and produces eight rounds after four world seconds. Future inputs are not reserved.
If input or a requirement is missing, the order waits and resumes when available.
**STOP FUTURE BATCHES [X]** lets an active batch finish, then stops; a waiting order
stops immediately. There is no refund. Another order requires another explicit
assignment. Worker production leaves your military stock policy unchanged.

On the battlefield, press **B** and click a map location for an HQ inquiry. Reports
arrive with delay; an empty result means no established information. **R** shows
known historical evidence and pauses the world; **Esc** returns to live play.
Reported enemy contacts show their last known position and observation time.

The operations panel separates **Military Need**, **Rear Stock**, **Supply Stage**
and **Rear Work**. "Uncommitted" is your unused finished stock; "eligible" is what
the current policy permits the military to draw. Loading, shipment transit and
truck custody are not Soldier delivery. The lower prompt explains the current
useful logistics/observation action, or that no player action is required.

Contact labels are **LAST KNOWN**, with age, observation/receipt time and Company
provenance. **RECENT** is up to 5 world seconds, **AGING** is more than 5 through
15, and **STALE** is older than 15. Old evidence stays visible until a newer locally observed report reaches
Company. A stale marker does not prove the enemy is still there. Worker status
shows completed/requested batches, blocking or stop state, and how many later
batches are scheduled. A completed or stopped order never repeats by itself.

Victory or defeat ends and freezes the battle. You can still switch maps to
inspect the aftermath. There are no Soldier movement, targeting or attack orders.

The bottom **ALERTS** strip prioritizes **RESULT**, then **ACTION NEEDED**, then
**INFO** in either map. Separate counts show open/unread actions, unread information
and unread results. **H / ALERT HISTORY** expands priority rows; click a row to
acknowledge it, or **K / ACK PRIMARY** for the current headline. Opening the list
does not pause live play.

An acknowledged action can still be open: acknowledgement does not fix a shortage
or authorize stock. The row stays available until the real condition clears, then
shows **RESOLVED** separately. A continuing block stays silent after acknowledgement;
a later real clear and reoccurrence can notify again. Unread updates for the same
Company contact combine into one row with a count and latest report times. Open
actions and the battle result are protected; up to eight other history rows rotate.
After battle end, the result remains the headline, marked ACK after acknowledgement.

Alerts cover blocked/completed Worker orders, stock awaiting military authorization,
completed physical delivery, new reports received by Company, and the battle result.
“Rear attention useful” and “Battlefield report available” are suggestions. You
choose whether to switch with **Tab**. Alerts never authorize stock, start/stop work,
issue military orders or switch maps for you. They do not expose enemy events that
have not reached Company, and historical reconstruction does not replay live alerts.
