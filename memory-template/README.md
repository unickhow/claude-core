# memory-template

Seed memory for new projects.

## How memory works

Claude Code stores per-project memory at:

```
~/.claude/projects/<encoded-project-path>/memory/
```

`MEMORY.md` in that directory is auto-loaded into every conversation as an index.
Individual memory files are read on demand when their entry in the index looks relevant.

This dir is a **seed** — copy contents (don't symlink) into a new project's memory dir to bootstrap.

## What's in here

- `MEMORY.md` — empty section scaffold (4 type buckets, no synthetic content). Copied to every new project.
- `README.md` — this file (NOT copied to projects).

New projects start with an empty memory dir by design — accumulate entries via `/learn` as patterns surface, don't pre-seed assumptions.

## Bootstrapping

Run from anywhere:

```bash
~/Projects/agent-core/bin/init-project.sh <project-path>
```

It copies all `*.md` files from `memory-template/` (except `README.md`) into the new project's memory dir, plus sets up other harness pieces.

Manual equivalent:

```bash
project_id="$(echo "$PWD" | sed 's|/|-|g')"
target=~/.claude/projects/"$project_id"/memory
mkdir -p "$target"
cp ~/Projects/agent-core/memory-template/MEMORY.md "$target/"
```

## The four types

| Type | Decay | Lead with |
|---|---|---|
| **user** | Long-lived | Profile facts (role, expertise, preferences) |
| **feedback** | Long-lived | Rule + **Why:** + **How to apply:** |
| **project** | Days–weeks | Fact/decision + **Why:** + **How to apply:** |
| **reference** | Stable until system changes | Pointer + what it's for |

Full schema rules live in Claude's system prompt — don't re-document them in this template; they'd just drift.

## What NOT to put in memory

- Code patterns, file paths, architecture — derive from the repo
- Git history — `git log` is authoritative
- Debug recipes — the fix is in the code
- Anything in CLAUDE.md (loaded every session — duplication would just drift)
- Ephemeral session state (use `.claude/handoff.md` via `/session-handoff` instead)

If you find yourself writing a memory that summarizes recent activity, ask: "what was *surprising* or *non-obvious* about this?" — that's the part worth keeping.
