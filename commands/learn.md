---
description: Capture a non-obvious learning into per-project memory with the right type and structure
---

The user wants to record something they (or you) just learned, so future sessions inherit it.

Topic / fact to capture: $ARGUMENTS

Do this in order:

1. **Decide the type** based on Claude's memory schema (see your system prompt):
   - `user` — about who the user is, their role, expertise, preferences
   - `feedback` — corrections or validated approaches you should keep applying
   - `project` — active initiatives, decisions, deadlines (decays fast)
   - `reference` — pointer to an external system / dashboard / runbook

   If unclear, ask the user which fits — don't guess silently.

2. **Check for an existing memory** on this topic — scan `MEMORY.md` and existing files in the memory dir. Update in place if it exists; only create a new file if genuinely new.

3. **Write the memory file** with proper frontmatter (name, description, type). For `feedback` and `project` types, structure the body as: rule/fact, then `**Why:**` line, then `**How to apply:**` line.

4. **Update `MEMORY.md`** — add a one-line index entry: `- [Title](file.md) — one-line hook`. Keep the index lean (lines past 200 are truncated).

5. **Confirm** in one line: file path written, type, and one-sentence summary. Don't restate the body.

If the "learning" is just a code pattern, file path, or something derivable from `git log` / the codebase — push back. Memory is for non-obvious context that the repo can't tell future sessions on its own.
