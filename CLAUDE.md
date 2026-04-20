# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

> §1–§4 adapted from [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills). Everything else added on top.

## 0. Principle Precedence

When rules conflict, resolve in this order:

1. **User's explicit instructions** (this turn's request)
2. **Safety & correctness** (security, data integrity, reversibility)
3. **YAGNI** — don't build what isn't needed now
4. **KISS** — simplest thing that works
5. **DRY** — eliminate *meaningful* duplication, not incidental

Early-stage code: YAGNI > KISS > DRY.
Mature code: DRY > KISS > YAGNI.
Critical systems: KISS > DRY > YAGNI.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios — "impossible" means *guaranteed by a type, invariant, or upstream check you can point to*. If you can't point to the guarantee, handle it.
- If 200 lines could be 50, rewrite it.

Test: "Would a senior engineer say this is overcomplicated?"

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that **your** changes made unused. Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Tests for invalid inputs pass"
- "Fix the bug" → "Test reproducing the bug passes"
- "Refactor X" → "Tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```

Before claiming done: run the verification. Paste the evidence. No "should work" claims.
→ Use `superpowers:verification-before-completion` before declaring any task complete.

## 5. Testing

- Write tests when the user asks, when fixing bugs (regression test first), or when adding non-trivial logic. Skip for throwaway scripts.
- Cover happy path, boundaries, error conditions.
- Test behavior, not implementation. AAA / Given-When-Then.
- A feature isn't "done" until tests pass locally.
→ For any non-trivial implementation, use `superpowers:test-driven-development`.

## 6. Debugging

Systematic, not guess-and-check:

1. Reproduce consistently.
2. Isolate scope (bisect, minimal repro).
3. Form a hypothesis about root cause.
4. Test the hypothesis — "bug went away" ≠ "root cause found."
5. Fix the cause, not the symptom.
6. Add a regression test.

Don't stop at the first plausible cause.
→ For any bug or test failure, use `superpowers:systematic-debugging`.

## 7. Security

- Never trust external input (users, APIs, files, env).
- Validate at boundaries. Sanitize before interpolating into SQL, shells, HTML, or paths.
- Never log secrets or PII. Never commit them.
- Principle of least privilege for tokens, DB roles, file permissions.
- Flag security implications of changes — don't silently expand the attack surface.
→ Before merging auth / input-handling / third-party integration changes, run `/security-review`.

## 8. Performance

- Don't optimize without measuring. Profile first.
- Watch for N+1 queries, unbounded loops, missing indexes, sync I/O in hot paths.
- Cache only with evidence of need and a clear invalidation story.
→ For deeper audits (DB / API / frontend Core Web Vitals / bundle), use the `performance-review` skill.

## 9. Error Handling & Destructive Operations

- Fail loudly in dev, gracefully in prod. Never silently swallow errors.
- User-facing errors: actionable messages, no stack traces.
- For destructive or hard-to-reverse operations (DB migrations, data deletes, force-push, dependency removal): confirm with the user first, ensure a rollback path, and prefer reversible intermediate states.

**Schema migration rules** (when changing DB structure):

- **Expand → migrate → contract.** Never rename / drop in one step. Add the new shape as nullable → backfill → switch reads → switch writes → drop the old shape. Each step ships independently.
- Don't ship schema change and app code that depends on it in the same deploy.
- Large tables: check lock behavior before `ALTER`. Prefer online / concurrent variants.
- Always have a backup (or point-in-time recovery verified) before running in prod.
- Migrations must be idempotent and reversible. Write the `down` path, even if you don't expect to use it.

## 10. Communication

- Code reviews: explain *why*, suggest alternatives, be specific.
- Commit messages: explain intent, not diff contents.
- Progress reports: state what changed, what's verified, what's outstanding. No trailing summaries of obvious work.
- When blocked: name the blocker concretely. Don't disappear into partial work.

## 11. Frontend Design Taste

When building or reviewing UI, don't settle for "looks fine." Apply established design frameworks as checklists, not cosplay.
→ Use the `design-taste-review` skill when finalizing components, pages, or interactions.

---

**Working signals:** fewer unnecessary diff lines, fewer rewrites for over-engineering, clarifying questions *before* implementation, verification evidence *before* "done."
