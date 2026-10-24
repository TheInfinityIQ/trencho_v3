# Trencho v3 task tracking

[GitHub Issues](https://github.com/TheInfinityIQ/trencho_v3/issues) are the canonical task ledger. They record scope, owner, blockers, revisions, evidence and acceptance; they do not grant design authority.

Dawson is the final project authority. The Central Game Designer defines and accepts bounded design tasks. The developer records implementation and verification. Later authoritative chat direction can supersede an issue: update the issue and identify the change rather than following stale text.

## Workflow

1. Receive an authorized bounded task; create or update its issue before work.
2. Record the owner role, baseline, scope, acceptance gates and dependencies. Use an assignee only when an actual GitHub identity has been designated.
3. Update the lifecycle label as work proceeds; record blockers without inventing approvals.
4. On delivery, link exact completion commits, inspectable evidence, verification scope and remaining limits. Reported engineering evidence is not independent designer inspection.
5. Record design acceptance separately from human evaluation. Keep a required human gate open until evaluated or explicitly superseded/waived by the appropriate authority.
6. Close only when the bounded task's gates are satisfied. A commit alone never closes a task. Stop/resume instructions remain binding regardless of issue state.

| Lifecycle | Label | Issue state |
|---|---|---|
| Ready | `ready` | Open |
| In Progress | `in-progress` | Open |
| Blocked | `blocked` | Open |
| Design Review | `design-review` | Open |
| Human Test | `human-test` | Open |
| Accepted | `accepted` | Closed |

Use one lifecycle label. `design-task`, `engineering`, `art` and `historical` describe type/context. Blocked is an optional branch, not a mandatory step. Human Test is required only when specified. Historical acceptance may close a superseded checkpoint; its body must explicitly preserve any missing human result. Accepted means the bounded milestone's gates are satisfied, not final gameplay/art/AI acceptance.

Issues plus these labels are sufficient; no separate GitHub Project was created. [Historical index](TASK_HISTORY.md).

## Art and scope boundaries

The only authorized 2D production recipient is **Initialize 2D asset production agent**, local chat `01a1660f-a461-7292-83d6-68caaefa588a`; see [ART_COORDINATION.md](ART_COORDINATION.md). An issue, label or dependency does not independently authorize an art commission or override Dawson.

PM-040 changes tracking/documentation only. The foreign local `project.godot` edit remains excluded. After this task, stop and report; the next gameplay task requires its own authorized scope.
