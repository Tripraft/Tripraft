#!/usr/bin/env python3
"""Audit from real code allocation events only; never fabricated."""
from managed_table import run_managed
if __name__=="__main__":run_managed("code_reservation_events")
