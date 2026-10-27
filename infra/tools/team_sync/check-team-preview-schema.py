import sys
from pathlib import Path
import os

from alembic.config import Config
from alembic.migration import MigrationContext
from alembic.script import ScriptDirectory
from dotenv import dotenv_values
from sqlalchemy import create_engine, text


def main():
    if len(sys.argv) != 3:
        print("Usage: check-team-preview-schema.py CHECKOUT_PATH ENV_PATH")
        return 1

    checkout = Path(sys.argv[1]).resolve()
    env_file = Path(sys.argv[2]).resolve()

    migrations = checkout / "services/api/migrations"

    if not migrations.is_dir() or not env_file.is_file():
        print("BLOCKED - Checkout or .env not found.")
        return 1

    # Match Flask and the privilege preflight: shell values override .env.
    settings = {**dotenv_values(env_file), **os.environ}
    database_url = settings.get("DATABASE_URL")

    if not database_url:
        print("BLOCKED - DATABASE_URL missing.")
        return 1

    try:
        sys.path.insert(0, str(checkout / 'services/api'))
        from schema_status import schema_status

        config = Config()
        config.set_main_option("script_location", str(migrations))

        scripts = ScriptDirectory.from_config(config)
        code_versions = set(scripts.get_heads())

        engine = create_engine(
            database_url,
            hide_parameters=True,
            pool_pre_ping=True,
            connect_args={"connect_timeout": 10},
        )

        try:
            with engine.connect() as connection:
                connection.execute(text("SET TRANSACTION READ ONLY"))
                connection.execute(text("SET LOCAL statement_timeout = '10s'"))

                db_versions = set(MigrationContext.configure(connection, opts={
                    'version_table_schema': 'public',
                }).get_current_heads())
        finally:
            engine.dispose()

    except Exception:
        print("BLOCKED - Could not verify Supabase schema.")
        return 1

    print("Code versions:", sorted(code_versions))
    print("Supabase versions:", sorted(db_versions))

    status = schema_status(scripts, db_versions)
    if status.state != 'current':
        print("BLOCKED - " + status.message)
        print("Guide: docs/operations/database-releases.md")
        return 1

    print("PASS - Database migration versions match.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
