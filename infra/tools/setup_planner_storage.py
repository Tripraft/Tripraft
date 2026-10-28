# Purpose: Checks or explicitly creates the private Supabase group vault bucket without printing credentials.
"""Run from the repository root after setting API-only Storage credentials."""
import argparse
from pathlib import Path
import sys

API = Path(__file__).resolve().parents[2] / 'services' / 'api'
sys.path.insert(0, str(API))

from app.trips.services.vault_storage import SupabaseVaultStorage, VaultStorageError  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--create', action='store_true', help='Create the private bucket if missing; never changes an existing bucket.')
    args = parser.parse_args()
    try:
        storage = SupabaseVaultStorage()
        storage.prepare_bucket(create=args.create)
        print(f'Private group vault bucket is ready: {storage.bucket}')
        return 0
    except VaultStorageError as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
