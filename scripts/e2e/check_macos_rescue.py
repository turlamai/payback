#!/usr/bin/env python3
"""Allow Cmd+Q reaping only when this run's trace explicitly records rescue."""

import json
import sys
from pathlib import Path


def rescue_observed(path: str) -> bool:
    try:
        trace = json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, UnicodeError, ValueError):
        return False
    if not isinstance(trace, dict):
        return False
    observations = trace.get("observations")
    return (
        isinstance(observations, dict)
        and observations.get("correction-dismissal-observed") is True
    )


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(2)
    sys.exit(0 if rescue_observed(sys.argv[1]) else 1)
