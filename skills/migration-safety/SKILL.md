---
name: migration-safety
description: Use when altering database schema — adding/removing columns, renaming, changing types, adding constraints, creating/dropping indexes, or any operation that modifies table structure. Enforces expand → migrate → contract staging, lock-aware operations, backup verification, and reversible down paths. Triggers on migration, schema change, ALTER TABLE, DROP, RENAME, column add/remove.
---

# Migration Safety

Schema changes have the highest blast radius of any routine dev work: a bad migration can lock production for hours, corrupt data, or block rollback. Treat every one as high-risk, even "trivial" ones.

## Core principle: expand → migrate → contract

**Never rename or drop in one step.** Any destructive change is decomposed into phases, each shipped independently:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. EXPAND   Add new shape alongside the old one (nullable)  │
│ 2. BACKFILL Copy / compute data into the new shape          │
│ 3. DUAL     Application writes to both, reads from new      │
│ 4. SWITCH   Reads fully on new shape; old becomes dead      │
│ 5. CONTRACT Drop the old shape                              │
└─────────────────────────────────────────────────────────────┘
```

Each phase deploys separately, with monitoring between them. Any phase can be rolled back without data loss.

**Never ship a schema change and the app code that depends on it in the same deploy.** If one rolls back, the other breaks.

## Per-change decision tree

| Change | Safe approach |
|---|---|
| **Add nullable column** | Single migration, safe |
| **Add NOT NULL column** | Add nullable → backfill → add `NOT NULL` constraint |
| **Rename column** | Add new → dual-write → backfill → switch reads → drop old |
| **Change column type** | Add new typed column → backfill with cast → switch reads/writes → drop old |
| **Drop column** | Stop reading (deploy) → stop writing (deploy) → drop (deploy) |
| **Add index** | Use `CONCURRENTLY` (PG) / `ALGORITHM=INPLACE, LOCK=NONE` (MySQL) |
| **Add FK / CHECK constraint** | Add with `NOT VALID` → validate in background → mark valid |
| **Rename table** | Create view with old name → migrate callers → drop view |

## Pre-flight checklist

Before running in production, confirm each:

- [ ] **Backup verified.** Not "backup exists" — verified restorable within acceptable RTO.
- [ ] **Row count known.** `SELECT count(*)` on affected table. Migrations on > 10M rows need special treatment.
- [ ] **Lock behavior checked.** Will this acquire `ACCESS EXCLUSIVE` (PG) / table metadata lock (MySQL)?  For how long?
- [ ] **Long-running query protection.** Statement timeout and lock timeout configured so a stuck migration doesn't block the app indefinitely.
- [ ] **Replica lag assessed.** Will this generate enough WAL / binlog to lag replicas?
- [ ] **Down migration written.** Not "we probably won't need it" — actually written and tested.
- [ ] **Idempotent.** Re-running the migration partway through must be safe (`IF EXISTS` / `IF NOT EXISTS`).
- [ ] **Deploy gate.** App code that depends on the new shape is NOT in the same deploy.

## Large-table specifics (> 10M rows)

- Backfill in batches (typically 1k–10k rows), with sleeps. Never `UPDATE ... WHERE true` on a big table.
- Use online DDL:
  - PostgreSQL: `CREATE INDEX CONCURRENTLY`, `ALTER TABLE ... ADD CONSTRAINT ... NOT VALID` → `VALIDATE CONSTRAINT`.
  - MySQL: prefer `pt-online-schema-change` / `gh-ost` over native `ALTER` for destructive changes.
- Monitor replication lag during backfill. Throttle if lag exceeds threshold.
- Never hold a transaction open across a full backfill.

## Rollback plan

For each migration, answer:

1. **If the migration fails mid-run** — is the table still usable? Can it be resumed?
2. **If the migration succeeds but the app deploy fails** — does the old app still work against the new schema?
3. **If we need to revert days later** — is the down migration still valid (given data written in between)?

If any answer is "no" or "unsure," redesign before running.

## Anti-patterns

- **One-step rename / drop.** Always decompose.
- **Schema change + dependent code change in the same deploy.** Coupling increases blast radius.
- **`UPDATE` without `WHERE` + batch.** Locks the table until done.
- **`ALTER TABLE ADD COLUMN ... NOT NULL DEFAULT <expr>`** on old PG versions rewrites the table.
- **`DROP INDEX` on a live table without `CONCURRENTLY`** (PG) — blocks all reads.
- **Assuming tests cover migration safety.** Test environments are small; production lock behavior differs.
- **"We'll write the down migration if we need it."** Write it now, or the migration isn't done.
- **Trusting that staging ≈ production.** Row counts, distributions, and concurrent load matter more than schema.

## When to escalate

Stop and ask a DBA / senior engineer if:

- The table has > 100M rows
- The migration must complete within a specific window
- You're not sure what lock the operation takes
- The app has no migration framework (raw SQL only)
- Prior migrations on this table have caused incidents
