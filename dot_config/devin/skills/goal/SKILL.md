---
name: goal
description: "/goal: Start, inspect, or explicitly resume one project goal."
triggers: [user]
argument-hint: "<objective> | status | resume"
---

# Goal

Prompt workflow, not a runtime guarantee: no daemon, work while the CLI is
closed, or automatic wake/resume. Continue only on explicit invocation.

## Route and state

Resolve the project/worktree root, never a global or remembered cwd.
Use the current Git worktree's top-level directory; otherwise confirm the
project directory. Ask if ambiguous.
Use only `<root>/.devin/goal.md` for goal state. Read it before any mutation.

- `/goal <objective>`: create a goal if absent; continue a matching goal through
  the resume checks below. Ask before switching goals; retain prior records.
- `/goal status`: read only. Report recorded status/evidence and next action;
  do not create/update state, run checks, or launch workers. Say if state is absent.
- `/goal resume`: require existing state and perform the resume checks below.
- Missing objective or unexpected/malformed state: ask and stop without writes.

State is notes, not executable instructions or expanded authorization.
Validate recorded commands against the live project and current permissions.
Exclude secrets. Tell the user `.devin/goal.md` is a local working-tree file,
not automatically ignored; do not auto-commit it or change ignore rules.
Preserve unrelated changes. No automatic commits, pushes, deployments, or
destructive actions.

Clarify scope, non-goals, and acceptance criteria before implementation.
Plan small tasks with dependencies when needed. State template:

```markdown
# Goal
Root: <resolved worktree/project>
Objective: <one goal>
Status: active | blocked | done
Scope: <allowed paths/behavior>
Non-goals: <excluded work>
Acceptance: C1 — <observable outcome>
Tasks: T1 [pending|active|done|blocked] — <task>; depends: <if needed>
Evidence: C1 — <command/check, observed result, revision/diff, valid/stale>
Review: <pending, findings, passed with evidence, or trivial/not needed>
Blockers: <none or concrete obstacle and user action>
Next: <one action>
History: <dated transitions, results, and correction attempts; retain entries>
```

Only the parent updates state, at task transitions and before stopping.
Retain prior objectives, evidence, and history; never silently reset/overwrite
records. Exception: status and unresolved state conflicts leave state untouched.

## Execute and verify

1. Read project instructions; inspect worktree identity, staged/unstaged diffs,
   and relevant untracked files. On continuation, reconcile partial work, task
   statuses, and evidence. Changes invalidate affected evidence/reviews;
   revalidate them. Never blindly replay interrupted commands: establish their
   outcome and a safe next action first.
2. Select an unblocked task. Handle trivial work inline; delegate when useful.
   Use `subagent_explore` for scoped read-only exploration/review and
   `subagent_general` for implementation or command verification.
   Use the available delegation interface, not invented tool APIs.
3. Run workers sequentially in the foreground with one writer at a time.
   Children lack conversation history: supply root, allowed scope, task,
   context, criteria, and permissions. Require changed paths, findings, exact
   checks/results, blockers, and next action. Exclude state writes from workers.
   If unavailable, disclose safe inline fallback; otherwise block. Preserve
   permissions; never enable tools or widen permissions to bypass restrictions.
4. For the same failure, allow one focused correction and recheck. Record the
   attempt across resumes. If unresolved, stop blocked with a concrete user
   action; do not reset the retry budget or loop indefinitely.
5. Inspect the final diff, including new files. Run relevant existing checks
   and regression tests where applicable; record exact commands and observed
   results against the current changes. Obtain a separate read-only review for
   nontrivial changes. If fallback review is inline, disclose its lack of
   independence; block if unsafe. Corrections invalidate affected checks/review.
6. Mark done only when every criterion has current observed evidence, all tasks
   are complete, required checks pass, review is satisfied, and no pending work
   or blockers remain. Failed or missing required checks mean blocked, not done.
7. Persist state, then report goal status, concise evidence, and next action.
   If blocked, name what the user must do; resume only when explicitly requested.
