---
name: performance-review
description: Use when the user reports slowness, before/after optimizing a critical path, or auditing a feature for performance. Covers DB, API, frontend (Core Web Vitals, bundle, render cost), and build-time performance. Triggers on "slow", "optimize", "performance", "CWV", "bundle size", "N+1", profiling work.
---

# Performance Review

Measure first. Fix root causes. Don't cache your way out of an algorithmic problem.

## Step 0 — Rule of engagement

**No optimization without a measurement.** If you can't show a number that's too high, you don't have a performance problem yet — you have a hunch. Capture the baseline before touching anything.

## Step 1 — Locate the bottleneck

| Symptom | Start here |
|---|---|
| Page slow to load | Frontend (CWV, network) |
| Page slow to interact | Frontend (render, JS) |
| API slow | Server-side profiling |
| API fast but DB pegged | Query analysis |
| Build / CI slow | Build tooling |
| Memory growth | Leak hunt (heap snapshots) |

## Step 2 — Per-layer checklist

### Database

- `EXPLAIN` the slow query. Watch for seq scans on large tables, nested loops at the top.
- N+1? Count queries per request — should be O(1), not O(rows).
- Missing index on columns in `WHERE` / `JOIN` / `ORDER BY`?
- Indexes that don't match query predicates (wrong column order, low selectivity)?
- Unbounded row growth (log tables, audit tables) without partitioning or TTL?
- Transactions held open too long?
- Connection pool saturated?

### API / Backend

- Serialization: shipping fields the client doesn't use?
- Sync I/O in a request path (file, external API) without timeout?
- N+1 fetches to downstream services?
- Response size: pagination missing? Compression (gzip / brotli) enabled?
- Recomputing idempotent data per request when it could be cached?
- CPU-bound work blocking the event loop (Node) / GIL (Python)?

### Frontend — Core Web Vitals

- **LCP (< 2.5s)** — largest element above the fold, usually hero image or display font.
  - Preload the LCP resource. Don't lazy-load above-fold.
  - Image format (AVIF / WebP), correct dimensions, responsive `srcset`.
- **INP (< 200ms)** — interaction to next paint.
  - Long tasks > 50ms on main thread? Break them up, yield, or move to a worker.
  - Event handlers doing sync expensive work?
- **CLS (< 0.1)** — layout shift.
  - Images / embeds without `width` & `height`?
  - Web fonts causing FOUT / FOIT? Use `font-display: swap` + preload.
  - Late-injected ads / banners pushing content?

### Frontend — Bundle & Runtime

- Bundle size: what's the biggest import? Use `rollup-plugin-visualizer` / `webpack-bundle-analyzer` / `vite-bundle-visualizer`.
- Tree-shaking working? Look for full-library imports (`import _ from 'lodash'` → `import debounce from 'lodash/debounce'`).
- Code splitting on route boundaries?
- Re-renders: in React, use Profiler; check context propagation, key stability, prop identity.
- Virtualize long lists (> 100 items).
- Memoize (`useMemo` / `useCallback`) **only after measuring** — premature memo adds allocation and hurts readability.
- Hydration cost on SSR: ship less JS, use islands / partial hydration where the framework supports it.

### Build / CI

- Parallelize independent steps.
- Cache: dependencies, test outputs, build artifacts (turbo / nx / cache actions).
- Incremental compilation (`tsc --incremental`, bundler caches).
- Is the slow step even needed on every run? (e.g. full e2e on docs-only changes)

## Step 3 — Prove the fix

Same measurement, before and after. Paste both numbers in your report. If the delta is within noise, you didn't fix anything — revert and re-investigate.

## Anti-patterns

- Adding a cache to hide an O(n²) algorithm — fix the algorithm
- "Optimizing" code that runs once at startup
- Micro-benchmarks that don't reflect production load
- Parallelizing I/O-bound work across threads (use async, not threads)
- Reflexive `useMemo` / `useCallback` — adds complexity, rarely helps
- "We optimized it" with no number attached
