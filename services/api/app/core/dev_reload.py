# Purpose: Applies pending backed-up local migrations before native development source reload initializes the API.
import os
from pathlib import Path
import subprocess
import sys


def prepare_native_reload(config):
    """Only the launcher's explicit development reload mode may migrate here."""
    if os.getenv('TRIPRAFT_DEV_RELOAD') != '1' or config.FLASK_ENV != 'development':
        return
    api = Path(__file__).resolve().parents[2]
    root = api.parents[1]
    subprocess.run([sys.executable, str(root / 'start.py'), '--migrate-native'],
                   cwd=api, env=os.environ.copy(), check=True, timeout=60)
