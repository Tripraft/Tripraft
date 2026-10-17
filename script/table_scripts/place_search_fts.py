#!/usr/bin/env python3
"""SQLite FTS5 virtual index managed by triggers; never overwrite manually."""
from managed_table import run_managed
if __name__=="__main__":run_managed("place_search_fts")
