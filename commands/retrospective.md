---
description: Review recent work for patterns worth turning into memory, CLAUDE.md rules, or new skills
---

Scope: $ARGUMENTS (default: last 10 commits + currently uncommitted changes; or last N sessions if user specifies "sessions")

Goal: surface **patterns** — things that happened more than once, or things that surprised. Output is a short structured review, not a summary of activity.

Steps:

1. **Gather signal**:
   - `git log --oneline -n 10` (or N if user specified)
   - `git diff` for any uncommitted work
   - If user said "sessions", scan recent files in `~/.claude/projects/<this-project>/` for transcripts (read on demand, don't dump)

2. **Look for these patterns** — only mention what actually appears:
   - **Repeated mistakes**: same fix done multiple times, same correction from user
   - **Validated approaches**: user accepted a non-obvious choice without pushback
   - **Friction**: tools you kept asking permission for, commands you kept running by hand
   - **Drift**: places the code diverged from CLAUDE.md rules
   - **Knowledge gaps**: things you had to re-derive that should've been in memory

3. **Output format** (skip empty sections):

   ```
   ## Patterns
   <pattern> — <evidence: file/commit/turn> — <suggested memory or rule>

   ## Suggested memory writes
   - [type] <name> — <why>

   ## Suggested CLAUDE.md / settings changes
   - <specific change> — <why>

   ## Nothing-to-do
   <only if the retrospective genuinely found nothing actionable>
   ```

4. **Don't auto-apply** any suggestion. Let the user pick what to action — for each accepted item, then offer to write it via `/learn` or by editing the relevant file.

A retrospective that finds nothing is a valid result. Don't manufacture findings.
