---
name: design-taste-review
description: Use when finalizing a UI component, page layout, or interaction — applies established design frameworks (Rams, Ive, Jobs, Norman, Tufte, Freiberg) as evaluation checklists to catch generic, decorative, or over-designed work before it ships. Triggers on UI review, design critique, "does this look right?", polish passes, component sign-off.
---

# Design Taste Review

Apply real design frameworks as checklists, not cosplay. The goal is concrete **cut / change / keep** decisions, not vague praise.

## When to use

- Finalizing a UI component, screen, or flow
- Reviewing a design decision before committing
- Self-check: "is this actually good, or just done?"

## Workflow

### Step 1 — State intent

One sentence: what is this element *for*? If you can't write it, the design isn't ready — stop and clarify first.

### Step 2 — Select 2–3 relevant personas

Don't run all of them. Pick by context:

| Context | Use |
|---|---|
| General UI component | Rams + Ive + Norman + **WCAG** |
| Product / feature scope decision | Jobs + Rams |
| Data visualization | Tufte + Rams + **WCAG** |
| Micro-interaction / animation | Freiberg + Norman + **WCAG** |
| Marketing / emotional surface | Ive + Jobs |
| **Any shipped UI** | **WCAG is mandatory, not optional** |

### Step 3 — Run each persona's sharpest question

**Dieter Rams — 10 principles**
Innovative · Useful · Aesthetic · Understandable · Unobtrusive · Honest · Long-lasting · Thorough in detail · Environmentally friendly · **As little design as possible.**
→ Sharpest question: *What can be removed without losing function?*

**Jony Ive**
Material honesty. Unity of surface. Care in the details that aren't on the critical path.
→ Sharpest question: *Does every element exist because it's meaningful, or because it's decorative?*

**Steve Jobs**
"Say no to 1000 things." End-to-end experience. What happens before the user opens the box.
→ Sharpest question: *What 3 things can I cut so the remaining thing becomes undeniable?*

**Don Norman**
Affordances, feedback, mapping, constraints.
→ Sharpest questions:
- Can the user tell how to operate this *without a label*?
- After they act, do they know it worked?
- Do controls map to their effect spatially / logically?
- Is misuse *structurally impossible*, not just warned against?

**Edward Tufte** (data viz only)
Data-ink ratio. No chartjunk. Small multiples over dashboards.
→ Sharpest question: *How much ink serves data vs. decoration?*

**Rauno Freiberg / Emil Kowalski** (modern interaction)
Motion serves information hierarchy. Transitions make state changes legible.
→ Sharpest question: *Does this motion explain something, or perform for its own sake?*

**WCAG / Inclusive design** (functional requirement, not taste)
Accessibility is legally and ethically non-negotiable. Check:
- **Keyboard:** every interactive element reachable and operable via Tab / Shift+Tab / Enter / Space / Esc. Visible focus ring. Logical tab order.
- **Semantics:** native elements (`<button>`, `<a>`, `<label>`) over `<div onClick>`. ARIA only when no native equivalent exists.
- **Contrast:** body text ≥ 4.5:1, large text / icons ≥ 3:1. Test dark mode separately.
- **State not by color alone:** errors = red + icon + text. Success = green + check + text.
- **Screen reader:** form fields have labels. Images have meaningful `alt` (or `alt=""` if decorative). Dynamic content uses `aria-live`.
- **Motion:** respects `prefers-reduced-motion`. No autoplay. Nothing flashes > 3×/sec.
- **Hit targets:** ≥ 24×24 CSS px (WCAG 2.2), 44×44 preferred on touch.
→ Sharpest question: *Can a user complete this task with keyboard only, and hear it narrated correctly?*

### Step 4 — Output: cut / change / keep

Produce a concrete list:

- **Cut:** [elements to remove, each with a reason]
- **Change:** [elements to modify, with before → after]
- **Keep:** [elements that survive — one line why]

**Decision rule:** if all selected personas independently say "cut" → cut. Don't negotiate.

**WCAG override:** if the WCAG check fails, the component is not shippable regardless of what other personas say. Fix a11y before worrying about aesthetics.

## Red flags

- "It looks modern" — modern is a style, not a quality check
- "Users will figure it out" — if they must figure it out, the design failed
- "We might need it later" — YAGNI applies to pixels too
- Decorative motion with no informational role
- Borders, shadows, or gradients added "to make it feel richer"
- Copy padding or sizing from a reference without knowing *why* that reference chose it

## Anti-patterns

- Running all personas on every decision → decision fatigue, signal dilution
- Using personas to justify decisions already made → motivated reasoning
- Cosplaying ("Steve would hate this!") instead of applying the framework
- Treating the checklist as the goal; the goal is a better decision
