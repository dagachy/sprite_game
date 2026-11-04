"""Turn token-guard features on or off by editing ~/.claude/token-guard/config.json.

Usage:
  python3 tgctl.py statusline on|off|status
"""

import json
import sys

from tg_lib import INSTALL_DIR, load_config

FEATURES = {"statusline": "상태 표시줄"}


def write_setting(key, value):
    path = INSTALL_DIR / "config.json"
    try:
        current = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        current = {}
    current[key] = value
    INSTALL_DIR.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(current, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main(argv):
    if len(argv) != 3 or argv[1] not in FEATURES or argv[2] not in ("on", "off", "status"):
        print(__doc__)
        return 2

    key, action = argv[1], argv[2]
    if action == "status":
        state = "on" if load_config()[key] else "off"
        print(f"{FEATURES[key]}: {state}")
        return 0

    write_setting(key, action == "on")
    print(f"{FEATURES[key]}: {action}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
