# Play the operations slice

Open **operations.tscn** in Godot and press **F6**.

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
