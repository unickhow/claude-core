# agent-core

AI-agent behavioral baseline (`CLAUDE.md`) plus a Claude Code harness (hooks, slash commands, settings, skills). Drop-in, stack-agnostic, designed to work in any project. `AGENTS.md` is a stub per the [agents.md convention](https://agents.md/) — projects adopting this baseline should fill it in with their own setup / tests / conventions.

## What this is

A minimal, opinionated baseline for how I want AI coding agents to behave across all my work — behavioral rules **plus** the harness scaffolding (hooks, slash commands, memory schema, bootstrap) that turns those rules into something the runtime actually enforces.

`CLAUDE.md` is the cross-project behavioral layer — loaded into every Claude Code session as the always-on baseline. `AGENTS.md` is intentionally a stub here; agent-core's project-level info already lives in this README. For your own projects, write `AGENTS.md` per the [convention](https://agents.md/) — read by Codex, Cursor, Copilot, Aider, Zed, Warp, and 20+ other agents. The harness layer (hooks / commands / settings) is currently Claude Code-specific.

Everything here is biased toward **caution over speed, simplicity over flexibility, evidence over assertion**. If you want rules that keep an AI collaborator from over-engineering, hiding uncertainty, or shipping untested claims, start here.

## Structure

```
agent-core/
├── CLAUDE.md                                  ← always-on behavioral rules (Claude Code, cross-project)
├── AGENTS.md                                  ← stub per agents.md convention (fill in per your project)
├── settings.template.json                     ← merge-friendly settings.json baseline (read-only allowlist + hook wiring)
├── hooks/                                     ← runtime safety + context injection
│   ├── pre-tool-use.sh                        ← block catastrophic destructive Bash
│   └── user-prompt-submit.sh                  ← inject git branch / dirty / ahead-behind on every prompt
├── commands/                                  ← stack-agnostic slash commands
│   ├── learn.md                               ← capture non-obvious knowledge into per-project memory
│   ├── session-handoff.md                     ← write a cold-readable brief for the next session
│   ├── retrospective.md                       ← surface patterns from recent commits / sessions
│   └── stack-test.md                          ← detect-and-dispatch test runner (pattern example)
├── memory-template/                           ← seed memory for new projects
│   ├── MEMORY.md                              ← empty section scaffold (User/Feedback/Project/Reference)
│   └── README.md                              ← schema explanation + bootstrap instructions
├── bin/
│   ├── init-project.sh                        ← bootstrap a project's .claude/ + memory dir, with stack detection
│   └── test-hooks.sh                          ← run all PreToolUse + UserPromptSubmit test cases
└── skills/
    ├── design-taste-review/SKILL.md           ← UI review via Rams / Ive / Jobs / Norman / Tufte / WCAG
    ├── migration-safety/SKILL.md              ← DB schema change checklist (expand → migrate → contract)
    └── performance-review/SKILL.md            ← DB / API / frontend / build perf audit
```

The skills are the **knowledge** layer (what to apply when). Everything else is the **harness** layer (how the runtime enforces, gates, and bootstraps).

## Install

Pick one — all three are valid depending on how much you want to sync.

### Option A — Global (recommended)

Symlink to your user-level Claude config so every project inherits it.

```bash
# Back up existing config first
mv ~/.claude/CLAUDE.md       ~/.claude/CLAUDE.md.bak       2>/dev/null
mv ~/.claude/settings.json   ~/.claude/settings.json.bak   2>/dev/null

# Behavioral rules (cross-project baseline)
ln -s ~/Projects/agent-core/CLAUDE.md ~/.claude/CLAUDE.md

# Skills
mkdir -p ~/.claude/skills
ln -s ~/Projects/agent-core/skills/design-taste-review ~/.claude/skills/design-taste-review
ln -s ~/Projects/agent-core/skills/migration-safety    ~/.claude/skills/migration-safety
ln -s ~/Projects/agent-core/skills/performance-review  ~/.claude/skills/performance-review

# Slash commands
mkdir -p ~/.claude/commands
ln -s ~/Projects/agent-core/commands/learn.md           ~/.claude/commands/learn.md
ln -s ~/Projects/agent-core/commands/session-handoff.md ~/.claude/commands/session-handoff.md
ln -s ~/Projects/agent-core/commands/retrospective.md   ~/.claude/commands/retrospective.md
ln -s ~/Projects/agent-core/commands/stack-test.md      ~/.claude/commands/stack-test.md

# Hooks (PreToolUse safety + UserPromptSubmit git context)
mkdir -p ~/.claude/hooks
ln -s ~/Projects/agent-core/hooks/pre-tool-use.sh       ~/.claude/hooks/pre-tool-use.sh
ln -s ~/Projects/agent-core/hooks/user-prompt-submit.sh ~/.claude/hooks/user-prompt-submit.sh

# Settings (read-only allowlist + hook wiring) — drop in if you have nothing,
# OR merge the `permissions.allow` and `hooks` blocks into your existing file.
cp ~/Projects/agent-core/settings.template.json ~/.claude/settings.json
```

Hook paths inside `settings.template.json` reference `$HOME/.claude/hooks/...` (location-independent — survives moving / renaming `agent-core`). After editing any hook, run `bin/test-hooks.sh` to catch regressions.

Update by `git pull` in `agent-core`; every project picks it up immediately.

### Option B — Per-project

Copy (or symlink) only what that project needs into `<project>/.claude/`.

```bash
# Per-project behavioral overrides (Claude reads project-level CLAUDE.md too)
cp ~/Projects/agent-core/CLAUDE.md <project>/CLAUDE.md
```

For the project's `AGENTS.md`, write your own per the [convention](https://agents.md/) — describing that project's setup, tests, and conventions. Don't copy this repo's `AGENTS.md`; it's an intentional stub.

Or use the bootstrap script — it sets up `.claude/settings.local.json` with stack-detected hints and seeds the per-project memory dir:

```bash
~/Projects/agent-core/bin/init-project.sh <project-path>
# or, from inside the project:
~/Projects/agent-core/bin/init-project.sh
# preview without writing:
~/Projects/agent-core/bin/init-project.sh --dry-run
```

Useful when a project has its own overrides that should merge with the baseline.

### Option C — Git submodule

```bash
cd <project>
git submodule add https://github.com/<you>/agent-core .agent-core
# then symlink into .claude/ as needed
```

Keeps the baseline versioned inside each project.

## Contents

### `CLAUDE.md`

Always-on behavioral baseline loaded into every Claude session. Covers:

- Principle precedence (user intent > safety > YAGNI > KISS > DRY)
- Intellectual honesty — truth over agreement, evidence over confidence
- Think-before-coding / simplicity / surgical edits
- Goal-driven execution with verification
- Testing, debugging, security, performance — short rules that delegate to skills
- Error handling and destructive-op confirmation
- Communication and PR reporting discipline
- Pointers to design-taste, migration-safety, and performance-review skills

### `AGENTS.md`

Intentional stub per the [AGENTS.md convention](https://agents.md/). agent-core's project-level info (layout, setup, testing, PR rules, security) lives in this README, so there's nothing to duplicate inside `AGENTS.md`.

For projects adopting agent-core as a baseline: write your own `AGENTS.md` describing that project's setup, tests, code style, and PR conventions. The convention has no required fields — see [agents.md](https://agents.md/) for sample sections.

### `skills/design-taste-review`

Triggered when finalizing UI / reviewing a design decision. Applies real frameworks as checklists (not cosplay):

- **Dieter Rams** — 10 principles, "as little design as possible"
- **Jony Ive** — material honesty, meaningful elements only
- **Steve Jobs** — say no to 1000 things
- **Don Norman** — affordance / feedback / mapping / constraints
- **Edward Tufte** — data-ink ratio (data viz only)
- **Freiberg / Kowalski** — motion serving information
- **WCAG / inclusive design** — mandatory, overrides aesthetic calls

Output is always a concrete **cut / change / keep** list.

### `skills/migration-safety`

Triggered on DB schema changes (ALTER, DROP, RENAME, column add/remove, constraints, indexes). Enforces:

- **Expand → migrate → contract** staging (never rename/drop in one step)
- Pre-flight checklist (backup verified, row count, lock behavior, timeout, idempotent, down path)
- Per-change decision tree (add column, rename, type change, FK, index — each has a safe path)
- Large-table specifics (> 10M rows): batched backfill, online DDL, replica lag monitoring
- Rollback plan covering mid-run failure, deploy failure, and late revert

Separated from `CLAUDE.md §10` because migration rules are context-triggered, not always-on.

### `skills/performance-review`

Triggered on "slow", "optimize", profiling work, or pre-ship audits. Covers DB (N+1, indexes, EXPLAIN), API (serialization, sync I/O), frontend (LCP / INP / CLS, bundle, re-renders), and build / CI. Enforces **measure before optimizing, prove the fix with numbers**.

### `hooks/`

Two hook scripts wired in via `settings.template.json`. Symlinked into `~/.claude/hooks/` at install — paths in settings are location-independent.

- **`pre-tool-use.sh`** — last-line-of-defense safety hook on `Bash`. Verified against 46 test cases (`bin/test-hooks.sh`). Blocks:
  - **rm**: `rm -rf /`, `rm -rf ~`, `rm -rf $HOME/...`, `rm -rf ./`
  - **wrapper bypass**: `bash -c "rm -rf /"`, `eval "rm -rf ~"`, `sh -c '...'`
  - **escape / absolute path**: `\rm -rf /`, `/bin/rm -rf /`, `/usr/bin/rm -rf ~`
  - **find / xargs**: `find / -delete`, `find ~ -exec rm`, `... | xargs rm -rf`
  - **git**: force-push to protected branches (allows `--force-with-lease`), `--no-verify`, `--no-gpg-sign`, hard-reset on protected branches, `branch -D` on protected branches
  - **chmod**: `chmod 777 ~` / `/`
  - **credential exfiltration**: `cat ~/.ssh/id_*`, `cat ~/.aws/credentials`, `cat ~/.netrc`, `cat ~/.kube/config`, `cat ~/.npmrc`, `cat /etc/passwd|shadow|sudoers`, `cat .env*` (excluding committed templates `.env.example|sample|template|dist`)

  The model is supposed to confirm destructive ops; this hook catches the misses.

- **`user-prompt-submit.sh`** — informational hook that injects a `<git-context>` block (branch, dirty count, ahead/behind) on every prompt. Silent in non-git directories.

Both are pure bash + `jq`. Run `bin/test-hooks.sh` after editing either to catch regressions.

### `commands/`

Stack-agnostic slash commands (universal workflows that don't care what language the project is in):

- **`/learn`** — capture a non-obvious learning to per-project memory with the right type and structure. Pushes back if the "learning" is derivable from `git log` or the codebase.
- **`/session-handoff`** — write `.claude/handoff.md` with a cold-readable brief (what's in flight, what's blocked, the next concrete step). Designed so the next session — which has zero context from this one — can act.
- **`/retrospective`** — review recent commits / sessions for **patterns** worth turning into memory or CLAUDE.md rules. Doesn't manufacture findings; "nothing to do" is a valid result.
- **`/stack-test`** — example of the **detect-and-dispatch pattern**: one stack-agnostic command that figures out what `test` means in this repo and runs it. Copy this structure for `/stack-build`, `/stack-lint`, etc.

### `memory-template/`

Seed memory for new projects (gets copied into `~/.claude/projects/<encoded-path>/memory/` by `bin/init-project.sh`):

- `MEMORY.md` — empty section scaffold (`User` / `Feedback` / `Project` / `Reference`). Auto-loaded into Claude's context every conversation; lines past 200 are truncated, so it stays lean by default.
- `README.md` — schema explanation, manual bootstrap snippet, what NOT to put in memory. NOT copied to projects.

New projects start empty by design. Accumulate entries via `/learn` as patterns surface — don't pre-seed assumptions that may not apply or that Claude already derives from the system prompt / environment.

The four memory type definitions (`user`, `feedback`, `project`, `reference`) live in Claude's system prompt — this template doesn't restate them, to avoid drift.

### `bin/init-project.sh`

Bootstraps a project's harness:

1. Detects stack from marker files (`package.json`, `Cargo.toml`, `go.mod`, `pubspec.yaml`, `pyproject.toml`, `Gemfile`, `composer.json`, `pom.xml`/`build.gradle*`, `Package.swift`, `tauri.conf.json`, `Dockerfile`).
2. Writes `<project>/.claude/settings.local.json` with stack-specific hints (commented-out, ready to uncomment).
3. Seeds `~/.claude/projects/<encoded-path>/memory/MEMORY.md` from the template.

Idempotent (skips existing files; `--force` to overwrite). `--dry-run` shows what would happen without writing.

### `bin/test-hooks.sh`

Runs all PreToolUse + UserPromptSubmit test cases against the scripts in `hooks/`. Use after editing any hook to verify the regex changes didn't break existing rules or open new bypasses. Exit code 0 if all pass, 1 otherwise — wire into a git pre-commit hook on this repo if you want stronger guarantees.

### `settings.template.json`

A drop-in `~/.claude/settings.json` containing personal Claude Code config:

- **67 Bash allowlist entries** (66 read-only + `mcp__pencil`) — `ls`, `git status`/`log`/`diff`, `grep`/`rg`, `find`, `gh pr view`, etc. Covers universal read-only operations so they don't prompt every time. Stack-specific commands (`npm test`, `cargo test`, etc.) are intentionally **not** here — those go in per-project `settings.local.json`.
- **Hook wiring** — references `~/.claude/hooks/pre-tool-use.sh` and `~/.claude/hooks/user-prompt-submit.sh` (location-independent — install symlinks them from `agent-core/hooks/`).
- **`enabledPlugins`** (9) — `context7`, `superpowers`, `code-simplifier`, `ralph-loop`, `ui-ux-pro-max`, `supabase`, `rust-analyzer-lsp`, `codex`, `claude-hud`.
- **`extraKnownMarketplaces`** (4) — `pbakaus/impeccable`, `nextlevelbuilder/ui-ux-pro-max-skill`, `openai/codex-plugin-cc`, `jarrodwatts/claude-hud`.
- **`statusLine`** — the `claude-hud` invocation (resolves latest cached version, runs via `fnm`'s default Node).
- **`theme`** — `light`.

`skipAutoPermissionPrompt` is intentionally absent — the allowlist + hooks now make it unnecessary, and removing it restores the per-tool confirmation safety net for anything not on the allowlist.

If you already have a `~/.claude/settings.json`, merge the `permissions.allow` and `hooks` blocks into it rather than overwriting.

## Harness layers — how the pieces fit

```
┌────────────────────────────────────────────────────────────────────────┐
│ KNOWLEDGE      CLAUDE.md (rules) + skills/ (domain checklists)         │
│ ────────────                                                           │
│ HARNESS        hooks/ (runtime gates) + settings (permissions)         │
│                + commands/ (workflows) + memory-template/ (long-term)  │
│ ────────────                                                           │
│ STACK BRIDGE   bin/init-project.sh + .claude/settings.local.json       │
│                + detect-and-dispatch slash commands                    │
└────────────────────────────────────────────────────────────────────────┘
```

Two patterns let a stack-agnostic template handle stack-specific reality without polluting the template:

### Layered override

| Layer | Where | What lives there |
|---|---|---|
| **Template** | `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/commands/` | Universal behavioral baseline, safe allowlist, hook wiring, stack-agnostic commands |
| **Project** | `<project>/CLAUDE.md`, `<project>/AGENTS.md`, `<project>/.claude/settings.local.json`, `<project>/.claude/commands/` | Project-specific behavioral overrides, project-level AGENTS.md (per convention — setup / tests / conventions), stack-specific test/build/lint commands |

Claude Code merges these automatically. The template never assumes a stack; the project fills in its own.

### Detect-and-dispatch

For commands that *behave* the same across stacks but *invoke* different tools (test, build, lint, format), write **one** stack-agnostic command and let it detect-and-dispatch at runtime. `commands/stack-test.md` is the worked example.

## What's intentionally NOT in this template

To stay genuinely stack-agnostic:

- **No hard-coded build/test/format/lint commands.** Those live in `<project>/.claude/settings.local.json` after running `bin/init-project.sh`.
- **No framework-specific skills** (React, Django, SwiftUI, etc.) — those should be separate plugins (`claude-frontend-pack`, `claude-backend-pack`).
- **No specific MCP server configs** beyond the ones that are genuinely universal (e.g. `context7` for docs).
- **No CI / monorepo / single-repo assumptions.**

If you find yourself wanting to add something here that only one stack would use, that's the signal it belongs in a separate pack.

## Companion tools

`CLAUDE.md` references several skills from other plugins. Install these for the intended behavior.

### Required (referenced directly by CLAUDE.md)

| Tool | Why | Where |
|---|---|---|
| **superpowers** plugin | Provides `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `receiving-code-review`. CLAUDE.md delegates to these instead of duplicating their content. | Claude Code plugin marketplace |
| **`/security-review`** | Built-in command Claude Code ships with. `CLAUDE.md §8` routes security audits to it. | Built-in, no install |

### Strongly recommended

| Tool | Why |
|---|---|
| **context7** MCP server | Fetches current library/SDK docs on demand. Without it, Claude answers from training data which may be months stale. Essential for anything touching framework APIs. |

### Optional enhancements

| Tool | Use case |
|---|---|
| **ui-ux-pro-max** ([nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)) | Design-system generator: 67 UI styles, 161 color palettes, 57 font pairings, 161 industry reasoning rules. Install: `npm i -g uipro-cli && uipro init --ai claude`. Best at **breadth** — "what kind of design should this be?" |
| **impeccable** ([pbakaus/impeccable](https://github.com/pbakaus/impeccable)) | Design language fighting LLM-default aesthetics (Inter, purple gradients, weak contrast, nested cards). 7 reference files (typography / color / spacing / motion / interaction / responsive / UX writing) + `/audit`, `/polish`, `/critique`, `/animate` commands. Best at **craft** — polishing output so it doesn't look AI-generated. |
| **frontend-design** (Anthropic) | Production-grade React component generation with distinctive aesthetic. Complements the above for component scaffolding. |
| **openspec** | Structured proposal / spec discipline for larger architectural changes |
| **mason** | Git commit planning |
| **claude-hud** | Statusline showing current context usage / model |

### Frontend design stack (how they layer)

For frontend-heavy work, the three design tools form a natural pipeline:

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. ui-ux-pro-max      → decide direction (style / palette / type) │
│ 2. impeccable         → generate and polish against AI defaults   │
│ 3. design-taste-review → final gate: Rams / Ive / Norman / WCAG   │
└─────────────────────────────────────────────────────────────────┘
```

- **Breadth → Craft → Gate.** Each layer narrows the decision space.
- Skip layer 1 when the design direction is already set.
- Never skip layer 3 — WCAG is not optional.

## Philosophy

Three principles, in order of precedence:

1. **YAGNI** — build only what's needed now
2. **KISS** — the simplest thing that works
3. **DRY** — eliminate meaningful duplication, not incidental

When they conflict, see `CLAUDE.md §0`. The default stance is: **fewer diff lines, clearer intent, verified outcomes**.

## Credits & inspiration

- **[forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — the four core principles of `CLAUDE.md` (Think Before Coding / Simplicity First / Surgical Changes / Goal-Driven Execution, §2–§5) are adapted from this repo, itself inspired by Andrej Karpathy's observations on LLM coding failure modes. Everything else (§0 precedence, §1 intellectual honesty, §6–§12, the two skills) is added on top.
- **[pbakaus/impeccable](https://github.com/pbakaus/impeccable)** and **[nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)** — referenced as companion tools; shaped how `design-taste-review` positions itself (evaluation, not generation).
- **Anthropic Superpowers** — the skills `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `receiving-code-review` are delegated to rather than duplicated.

## Updating

```bash
cd ~/Projects/agent-core
git pull
# symlinks pick up changes automatically
```

## License

Personal use. Fork freely.
