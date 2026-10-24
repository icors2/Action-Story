#!/usr/bin/env python3
"""Generate game/data/level_table.json for levels 1–70."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game" / "data" / "level_table.json"
MAX_LEVEL = 70


def exp_to_next(level: int) -> int:
    # level is current level (1..69). Tuned so early kills stay short.
    return int(round(12.0 * (level**1.62) + 8.0 * level + 5.0))


def main() -> None:
    table = [exp_to_next(lv) for lv in range(1, MAX_LEVEL)]
    OUT.write_text(
        json.dumps({"schema_version": 1, "max_level": MAX_LEVEL, "exp_to_next": table}, indent=2)
        + "\n",
        encoding="utf-8",
    )
    print(f"wrote {OUT} ({len(table)} entries, lv1={table[0]} lv10={table[9]} lv69={table[-1]})")


if __name__ == "__main__":
    main()
