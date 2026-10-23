"""Print a source-only table access inventory. Never connect to Supabase."""
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
os.environ['DATABASE_URL'] = 'sqlite:///:memory:'
os.environ['REDIS_URL'] = ''
sys.path.insert(0, str(ROOT / 'services/api'))
from app.core.db.connection import _import_all_models  # noqa: E402
from app.core.db.base import Base  # noqa: E402


def main():
    _import_all_models()
    print('# Employee developer database access review\n')
    print('Source inventory only. Live Supabase table count, ownership, role inheritance, PUBLIC privileges and RLS have not been verified.\n')
    print('The local baseline contains 40 application tables plus alembic_version. Six new employee tables are proposed. Reconcile this with the reported 41 existing application tables before deploying.\n')
    print('All developer identities share tripraft-dev. SQL credentials can inspect/change every row covered by their grants; application RBAC does not constrain direct SQL. Only synthetic shared test data may be used. Production stays separate.\n')
    print('| Table | Default review decision | Direct SQL exposure |\n|---|---|---|')
    for name, table in sorted(Base.metadata.tables.items()):
        if name.startswith('employee'):
            decision, exposure = 'Deny developer access; protected control plane only', 'Approvals, identities, sessions, audit or credential metadata'
        elif name in ('users', 'user_sessions'):
            decision, exposure = 'Synthetic dev identities only; explicit CTO review', 'Password hashes, verification state, profile data and session digests; never store CTO control-plane identity here'
        elif 'audit' in name or 'history' in name or name.endswith('reviews'):
            decision, exposure = 'No direct modification; reviewed read access only', 'Before-state snapshots, actors and operational history'
        elif 'vault' in name or 'document' in name or 'signature' in name or 'agreement' in name:
            decision, exposure = 'Deny by default; synthetic fixtures only', 'Documents, personal or contractual data and storage references'
        elif name in ('gp_chat_messages', 'gp_chat_summaries') or 'agent_log' in name:
            decision, exposure = 'Deny by default; explicit diagnostics approval', 'Conversation content and AI inputs/outputs'
        else:
            decision, exposure = 'Explicit allowlist after synthetic-data review', ', '.join(column.name for column in table.columns)[:180]
        print(f'| `{name}` | {decision} | {exposure} |')
    print('\nReview SELECT-only access to alembic_version for Flask schema verification; deny updates. Grant no schema CREATE, ownership, superuser, CREATEROLE, CREATEDB, replication or BYPASSRLS. Review schema PUBLIC privileges and inherited grants. Do not use GRANT ALL or automatic grants on future tables.')
    print('\nRole scripts in app/employees/database_provisioning.py are drafts for CTO review. They intentionally omit passwords. Individual role creation is not executed automatically. The optional trusted revoker can disable only the deterministic individual developer role and terminate its sessions after explicit executor authorization.')


if __name__ == '__main__':
    main()
