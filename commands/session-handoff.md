---
description: Produce a structured handoff brief so the next session can pick up where this one ended
---

Write a handoff brief to `.claude/handoff.md` in the current project root (create the dir if needed). This file is **session-state, not memory** — it has a short shelf-life and gets overwritten each handoff.

Structure:

```markdown
# Handoff — <today's date in YYYY-MM-DD>

## Where I am
<1-3 sentences: current task, what step in it>

## What's done in this session
- <bullet>
- <bullet>

## What's in flight
- <file:line — what's half-done, what's the next concrete edit>

## Blocked / waiting on
- <blocker — who/what unblocks it>

## Open questions
- <question that needs the user, with enough context to answer cold>

## Files touched
<list paths from `git diff --name-only` if dirty, else "none uncommitted">

## Next concrete step
<one sentence: the very next action, specific enough to start without re-reading the convo>
```

Rules:

- **Cold-readable.** Write so the next session (which has zero context from this one) can act. No "the thing we discussed" — name it.
- **No restating known state.** Don't summarize the codebase or git history; those are derivable.
- **Surgical.** If nothing is in flight, say so — don't pad sections.
- **Confirm path** in one line after writing. Don't dump the file content back to the user.

If `.claude/handoff.md` already exists, overwrite it (handoffs are last-writer-wins by design).
