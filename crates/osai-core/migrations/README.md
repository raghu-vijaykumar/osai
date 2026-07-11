# Database Migrations

This directory is the authoritative source for all SQLite schema migrations.

## Naming Convention

```
V<VERSION>__<description>.sql
```

Examples: `V1__initial_schema.sql`, `V2__add_projects_table.sql`

## Runners

| Layer | Tool | How migrations are loaded |
|-------|------|--------------------------|
| Rust core (`crates/osai-core/`) | `refinery` | Embedded at compile time via `refinery_macros::embed_migrations!()` |
| Node.js sidecars (`services/`, `packages/`) | `umzug` + `better-sqlite3` | Reads `.sql` files from disk (copied into sidecar package at build time) |

## Rules

1. **Idempotent** — all statements must be safe to re-run (`IF NOT EXISTS`, `IF EXISTS`, guard clauses)
2. **Forward-only** — never edit a committed migration. Create a new one.
3. **Backup** — the runner copies `osai.db` to `osai.db.bak` before applying any migration
4. **Checksums** — `refinery` and `umzug` both checksum each migration and reject tampered files
5. **One version number per PR** — if two developers add `V2__` simultaneously, the merge conflict must be resolved by renumbering one to `V3__`
