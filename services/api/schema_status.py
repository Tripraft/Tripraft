# Purpose: Explain migration ancestry without importing application settings or changing a database.
"""Read-only migration planning shared by startup and the release runner."""
from dataclasses import dataclass

from alembic.script.revision import ResolutionError, RevisionError


@dataclass(frozen=True)
class SchemaStatus:
    state: str
    code_heads: tuple[str, ...]
    database_heads: tuple[str, ...]
    pending: tuple[tuple[str, str], ...] = ()

    @property
    def message(self):
        if self.state == 'current':
            return 'Database migration versions match.'
        if self.state == 'behind':
            changes = '; '.join(f'{revision}: {description.rstrip(".")}' for revision, description in self.pending)
            return ('Database is behind this checkout. Pending migrations: ' + changes
                    + '. Automatic startup can only run owner-approved development migrations. '
                    'The owner must enable the approved migration function once or deploy this revision. '
                    'Setup: infra/sql/development/enable_approved_startup_migrations.sql.')
        if self.state == 'uninitialized':
            return 'Database has no migration history. Ask the release administrator to review initial provisioning.'
        if self.state == 'multiple-code-heads':
            return 'Code contains multiple migration heads. Merge the migration branches in code before release.'
        if self.state == 'unknown':
            return ('Database contains a revision absent from this checkout. It may be newer or from another branch. '
                    'Pull the approved matching code or ask the release administrator to review it.')
        return 'Code and database migration branches diverge. Ask the release administrator to reconcile them.'


def schema_status(scripts, database_heads):
    """Compare the graph, never the lexical order of revision identifiers."""
    code = tuple(sorted(scripts.get_heads()))
    database = tuple(sorted(database_heads))
    if len(code) != 1:
        return SchemaStatus('multiple-code-heads', code, database)
    if not database:
        return SchemaStatus('uninitialized', code, database)
    try:
        known = {revision.revision for revision in scripts.walk_revisions()}
        if not set(database) <= known:
            return SchemaStatus('unknown', code, database)
        if code == database:
            return SchemaStatus('current', code, database)
        pending = tuple((revision.revision, revision.doc or 'Schema update')
                        for revision in reversed(list(scripts.iterate_revisions(code, database))))
        return SchemaStatus('behind', code, database, pending)
    except (ResolutionError, RevisionError):
        return SchemaStatus('diverged', code, database)
