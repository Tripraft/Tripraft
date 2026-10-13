# Seed data

The travel-data source of truth is `../catalog/tripraft-canonical.db`, created empty
from `services/api/schema/tripraft-canonical-schema.sql`, including its extensions.
See [catalog setup](../catalog/README.md). This directory and `sql_database/` contain
candidate seed SQL; none is automatically imported. The older populated catalog
is preserved as a legacy reference. Application-data migrations remain in
`services/api/migrations`; private account/trip/expense data belongs in the ignored
`data/runtime` directory or PostgreSQL.
