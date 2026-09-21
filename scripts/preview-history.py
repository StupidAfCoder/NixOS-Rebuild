#!/usr/bin/env python3
"""Write explicitly labeled demo history to a NEW file, never the user's real history."""
import argparse
import json
from datetime import datetime, timedelta
from pathlib import Path

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("output", type=Path)
a = p.parse_args()
days = {}
today = datetime.now().date()
for offset in range(56):
    if offset % 11 == 3:  # explicit gaps, not zero-use days
        continue
    day = (today - timedelta(days=offset)).isoformat()
    minutes = (offset * 47 + 83) % 400
    days[day] = {"firefox": minutes * 24, "emacs": minutes * 21, "foot": minutes * 12, "thunar": minutes * 3}
days[(today - timedelta(days=4)).isoformat()] = {}
a.output.parent.mkdir(parents=True, exist_ok=True)
with a.output.open("x") as f:
    json.dump({"sampleData": True, "days": days, "updated": datetime.now().isoformat()}, f)
a.output.chmod(0o600)
print("Sample history only:", a.output)
