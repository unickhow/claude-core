# claude-core

Personal Claude Code guidelines and focused skills. Drop-in, stack-agnostic, designed to work in any project.

## What this is

A minimal, opinionated baseline for how I want Claude to behave across all my work — plus two skills that fill gaps the default environment doesn't cover (design taste with WCAG, cross-stack performance review).

Everything here is biased toward **caution over speed, simplicity over flexibility, evidence over assertion**. If you want rules that keep an AI collaborator from over-engineering, hiding uncertainty, or shipping untested claims, start here.

## Structure

```
claude-core/
├── CLAUDE.md                                  ← always-on behavioral rules
└── skills/
    ├── design-taste-review/SKILL.md           ← UI review via Rams / Ive / Jobs / Norman / Tufte / WCAG
    └── performance-review/SKILL.md            ← DB / API / frontend / build perf audit
```

## Install

Pick one — all three are valid depending on how much you want to sync.

### Option A — Global (recommended)

Symlink to your user-level Claude config so every project inherits it.

```bash
# Back up existing config first
mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak 2>/dev/null

ln -s ~/Projects/claude-core/CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/skills
ln -s ~/Projects/claude-core/skills/design-taste-review ~/.claude/skills/design-taste-review
ln -s ~/Projects/claude-core/skills/performance-review  ~/.claude/skills/performance-review
```

Update by `git pull` in `claude-core`; every project picks it up immediately.

### Option B — Per-project

Copy (or symlink) only what that project needs into `<project>/.claude/`.

```bash
cp ~/Projects/claude-core/CLAUDE.md <project>/CLAUDE.md
```

Useful when a project has its own overrides that should merge with the baseline.

### Option C — Git submodule

```bash
cd <project>
git submodule add https://github.com/<you>/claude-core .claude-core
# then symlink into .claude/ as needed
```

Keeps the baseline versioned inside each project.

## Contents

### `CLAUDE.md` (139 lines)

Always-on rules, covering:

- Principle precedence (user intent > safety > YAGNI > KISS > DRY)
- Think-before-coding / simplicity / surgical edits
- Goal-driven execution with verification
- Testing, debugging, security, performance — short rules that point to deeper skills
- Error handling and schema migration safety (expand → migrate → contract)
- Communication and PR reporting discipline
- Frontend design-taste pointer

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

### `skills/performance-review`

Triggered on "slow", "optimize", profiling work, or pre-ship audits. Covers DB (N+1, indexes, EXPLAIN), API (serialization, sync I/O), frontend (LCP / INP / CLS, bundle, re-renders), and build / CI. Enforces **measure before optimizing, prove the fix with numbers**.

## Companion tools

`CLAUDE.md` references several skills from other plugins. Install these for the intended behavior.

### Required (referenced directly by CLAUDE.md)

| Tool | Why | Where |
|---|---|---|
| **superpowers** plugin | Provides `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `receiving-code-review`. CLAUDE.md delegates to these instead of duplicating their content. | Claude Code plugin marketplace |
| **`/security-review`** | Built-in command Claude Code ships with. `CLAUDE.md §7` routes security audits to it. | Built-in, no install |

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

- **[forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — the four core principles of `CLAUDE.md` (Think Before Coding / Simplicity First / Surgical Changes / Goal-Driven Execution, §1–§4) are adapted from this repo, itself inspired by Andrej Karpathy's observations on LLM coding failure modes. Everything else (§0 precedence, §5–§11, the two skills) is added on top.
- **[pbakaus/impeccable](https://github.com/pbakaus/impeccable)** and **[nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)** — referenced as companion tools; shaped how `design-taste-review` positions itself (evaluation, not generation).
- **Anthropic Superpowers** — the skills `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `receiving-code-review` are delegated to rather than duplicated.

## Updating

```bash
cd ~/Projects/claude-core
git pull
# symlinks pick up changes automatically
```

## License

Personal use. Fork freely.
