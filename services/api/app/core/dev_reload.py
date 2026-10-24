# Purpose: Compatibility hook; development source reloads never change a database.
"""Retained for callers that imported the previous reload hook."""


def prepare_native_reload(config):
    """No schema operations are permitted during API startup or source reload."""
    return None
