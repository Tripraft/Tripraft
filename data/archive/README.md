# Preserved database copies

`root-tripraft-2026-10-19.db` is the former repository-root `tripraft.db`.
It contains an empty travel schema and was not selected by the inspected runtime
configuration. Its SQLite integrity check passed before relocation. The file was
moved intact; no tables or records were changed. It is not the active development
application database and is ignored by Git and Docker builds.

Keep database archives under `data/`, separate from planning documents in `docs/`.
The active application data remains in `data/runtime/dev/tripraft.db`.
