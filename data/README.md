# TripRaft data

The backend uses separate operational and reference databases. The frontend calls
the API and never opens these files directly.

| Location | Purpose |
| --- | --- |
| `runtime/dev/tripraft.db` | Active native development accounts, trips, invitations and expenses; selected by `services/api/.env` |
| `runtime/tripraft.db` | Older application data and unconfigured-API fallback; preserved |
| `catalog/tripraft-canonical.db` | General travel reference schema and data; currently an empty catalog |
| `catalog/tripraft_places.db` | Populated read-only Group Planner reference catalog |
| `archive/` | Preserved inactive root database; ignored except the README |
| `seeds/` | Seed documentation and input references; not automatically loaded |

The two catalog files are versioned. Runtime databases, archived database files
and SQLite journals are ignored. Their data is not shared by GitHub or Sapling.
Use one hosted PostgreSQL operational database for the remote beta.

See [the folder and database guide](../docs/project-structure.md) for exact settings,
the separate enrichment datasets and the frontend/backend connection flow.
