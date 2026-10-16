#!/usr/bin/env python3
"""fix-context-1m.py — make the 1M context window actually take effect.

Problem found 2026-10-16:
- opencode-dcp shipped with legacy defaults (minContextLimit 20000 /
  maxContextLimit 48000) which compressed/pruned context long before the
  declared 1M window -> the session saw context-watch warnings at ~36%.
- compaction carried V2-only keys (threshold, context_window) that V1 ignores,
  so native compaction behaved unpredictably.

Fix:
- dcp compress.enabled=false and prune.enabled=false (rely on native compaction)
- compaction -> strictly V1-valid keys: auto / tail_turns / reserved / prune
- model limit.context stays 1_000_000 (source of truth for compaction math)
Applies to global + all project configs; backups kept.
"""
import json, re, os, glob, datetime

ts = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
targets = [os.path.expanduser("~/.config/opencode/opencode.json")]
targets += sorted(glob.glob(os.path.expanduser("~/Projects/*/opencode.json")))

for p in targets:
    if not os.path.exists(p):
        continue
    raw = open(p).read()
    d = json.loads(re.sub(r"^\s*//.*$", "", raw, flags=re.M))
    open(p + f".bak-ctx1m-{ts}", "w").write(raw)

    # 1) native compaction, V1-valid keys only
    d["compaction"] = {"auto": True, "prune": False, "tail_turns": 2, "reserved": 10_000}

    # 2) disable dcp's own compression (it would shrink context far below 1M)
    pk = "plugin" if "plugin" in d else "plugins"
    for i, e in enumerate(d.get(pk, [])):
        nm = e[0] if isinstance(e, list) and e else (e.get("package") if isinstance(e, dict) else e)
        if nm != "opencode-dcp":
            continue
        if isinstance(e, list) and len(e) == 2 and isinstance(e[1], dict):
            e[1] = {"compress": {"enabled": False}, "prune": {"enabled": False}}
        elif isinstance(e, dict):
            e["options"] = {"compress": {"enabled": False}, "prune": {"enabled": False}}

    # 3) model limit stays 1M everywhere
    for pp in ("provider", "providers"):
        for pv in (d.get(pp) or {}).values():
            for mv in (pv.get("models") or {}).values():
                lim = mv.setdefault("limit", {})
                lim["context"] = 1_000_000
                lim.setdefault("output", 65_536)

    open(p, "w").write(json.dumps(d, indent=2))
    print(f"ctx1m applied: {p}")
print("DONE — restart opencode sessions to pick up the corrected context settings")