#!/usr/bin/env python3
# scripts/context-budget.py — model-aware context-overflow monitoring (Wave 3)
#
# Complements the opencode-context-watch / opencode-context-compress plugins,
# which warn at runtime from provider-reported usage. This initializer-side tool
# adds the piece they cannot: a consumer of the model-limits registry
# (src/data/routing.json → cost_table[].context) that reports a session's usage
# against ITS OWN model's maximum, plus a CLI budget report for offline review.
#
# Subcommands:
#   models            table of known models + context windows (from routing.json)
#   status            scan recent opencode sessions, report usage vs model limit
#   check [--strict]  same as status; --strict exits 1 when any session is at
#                     ACT level (for CI/scripts); without --strict always exits 0
#   --json            machine-readable output for status/check/models
#
# Thresholds (WARN / ACT) express how full a model's context window is:
#   WARN = 0.77 (≈77%) — industry convergence for "compression should have fired
#   ACT  = 0.90 (≈90%) — the practical ceiling; beyond this the model silently
#         degrades or drops context. An absolute token cap (~350k) is a separate
#         plugin concern; this tool only compares against each model's window.
# These defaults live in ~/.config/opencode/context-guard.json under "budget"
# (warn_percent / act_percent) and are only read — never written — here.
#
# Stdlib only. No network. Never crashes on malformed session JSON.
import argparse
import json
import os
import sys


DEFAULT_WARN = 0.77
DEFAULT_ACT = 0.90
MAX_SESSION_FILES = 20

MODEL_ID_KEYS = ("modelid", "model_id", "modelname", "model_name")
PROVIDER_KEYS = ("providerid", "provider_id", "provider", "providername")
SESSION_ID_KEYS = ("id", "sessionid", "session_id", "session", "sessionname")


# ── Generic helpers ──────────────────────────────────────────────────────────
def walk_dicts(obj, depth=0, max_depth=8):
    """Yield every dict reachable from obj, bounded depth (no cycles in JSON)."""
    if depth > max_depth:
        return
    if isinstance(obj, dict):
        yield obj
        for v in obj.values():
            yield from walk_dicts(v, depth + 1, max_depth)
    elif isinstance(obj, list):
        for v in obj:
            yield from walk_dicts(v, depth + 1, max_depth)


def _lower_keys(d):
    return {str(k).lower(): v for k, v in d.items()}


def _first_str(lk, keys):
    for k in keys:
        v = lk.get(k)
        if isinstance(v, str) and v.strip():
            return v.strip()
    return None


# ── Routing registry (SSOT: src/data/routing.json → cost_table) ─────────────
def load_cost_table():
    path = os.environ.get("ROUTING_JSON")
    if not path:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        path = os.path.join(script_dir, "..", "src", "data", "routing.json")
    try:
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except Exception as exc:  # noqa: BLE001 — registry is required; fail loud
        print("error: cannot read routing.json at %s: %s" % (path, exc), file=sys.stderr)
        sys.exit(1)
    if not isinstance(data, dict):
        print("error: routing.json is not a JSON object: %s" % path, file=sys.stderr)
        sys.exit(1)
    cost = data.get("cost_table")
    return cost if isinstance(cost, dict) else {}


def resolve_limit(model_id, cost_table):
    """Match a session model id to a routing key by containment (case-insensitive).

    routing keys look like 'deepseek/deepseek-v4-pro'; session ids may be the
    full 'deepseek/deepseek-v4-pro' or the bare 'deepseek-v4-pro'. A match is
    declared when either string contains the other.
    """
    if not model_id:
        return None
    m = model_id.lower().strip()
    if not m:
        return None
    for key in sorted(cost_table.keys()):
        k = key.lower()
        if m == k or m in k or k in m:
            entry = cost_table[key]
            if isinstance(entry, dict):
                ctx = entry.get("context")
                if isinstance(ctx, (int, float)):
                    return int(ctx)
    return None


# ── Thresholds (read-only, from context-guard.json) ─────────────────────────
def load_thresholds(home):
    warn, act = DEFAULT_WARN, DEFAULT_ACT
    xdg = os.environ.get("XDG_CONFIG_HOME")
    if not xdg:
        xdg = os.path.join(home, ".config")
    cfg_path = os.path.join(xdg, "opencode", "context-guard.json")
    try:
        with open(cfg_path, "r", encoding="utf-8") as fh:
            cfg = json.load(fh)
    except Exception:  # noqa: BLE001 — config is optional; defaults apply
        return warn, act
    if not isinstance(cfg, dict):
        return warn, act
    budget = cfg.get("budget")
    watch = cfg.get("watch")
    if isinstance(budget, dict):
        if isinstance(budget.get("warn_percent"), (int, float)):
            warn = float(budget["warn_percent"])
        if isinstance(budget.get("act_percent"), (int, float)):
            act = float(budget["act_percent"])
    if isinstance(watch, dict) and not (
        isinstance(budget, dict) and isinstance(budget.get("warn_percent"), (int, float))
    ):
        w = watch.get("warn_percent") or watch.get("threshold")
        if isinstance(w, (int, float)):
            warn = float(w)
    return warn, act


# ── Session extraction (best-effort, never crashes) ─────────────────────────
def extract_model(obj):
    for d in walk_dicts(obj):
        if not isinstance(d, dict):
            continue
        lk = _lower_keys(d)
        for k in MODEL_ID_KEYS:
            v = lk.get(k)
            if isinstance(v, str) and v.strip():
                prov = _first_str(lk, PROVIDER_KEYS)
                if prov and "/" not in v:
                    return "%s/%s" % (prov, v)
                return v
        mv = lk.get("model")
        if isinstance(mv, str) and mv.strip():
            return mv
        if isinstance(mv, dict):
            mk = _lower_keys(mv)
            mid = _first_str(mk, MODEL_ID_KEYS)
            if mid:
                prov = _first_str(mk, PROVIDER_KEYS)
                if prov and "/" not in mid:
                    return "%s/%s" % (prov, mid)
                return mid
    return None


def extract_usage(obj):
    for d in walk_dicts(obj):
        if not isinstance(d, dict):
            continue
        lk = _lower_keys(d)
        if not any("token" in k for k in lk):
            continue
        for tk in ("total_tokens", "total"):
            v = lk.get(tk)
            if isinstance(v, (int, float)):
                return int(v)
        total = 0
        for k in ("input_tokens", "output_tokens", "cache_read_tokens",
                  "cache_write_tokens", "input", "output", "cache_read", "cache_write"):
            v = lk.get(k)
            if isinstance(v, (int, float)):
                total += int(v)
        if total > 0:
            return total
        s = 0
        for k, v in lk.items():
            if "token" in k and isinstance(v, (int, float)):
                s += int(v)
        if s > 0:
            return s
    return None


def extract_session_id(obj):
    for d in walk_dicts(obj):
        if not isinstance(d, dict):
            continue
        lk = _lower_keys(d)
        sid = _first_str(lk, SESSION_ID_KEYS)
        if sid:
            return sid
    return None


def find_session_files(home):
    base = os.path.join(home, ".local", "share", "opencode", "storage")
    roots = [os.path.join(base, "session"), base]
    files = {}
    for root in roots:
        if not os.path.isdir(root):
            continue
        for dirpath, _dirnames, filenames in os.walk(root):
            for fn in filenames:
                if fn.endswith(".json"):
                    p = os.path.join(dirpath, fn)
                    if p not in files:
                        try:
                            files[p] = os.path.getmtime(p)
                        except OSError:
                            files[p] = 0.0
    ranked = sorted(files.items(), key=lambda kv: (-kv[1], kv[0]))
    return [p for p, _ in ranked[:MAX_SESSION_FILES]]


def parse_session_file(path):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            data = json.load(fh)
    except Exception:  # noqa: BLE001 — malformed session files are skipped
        return None
    if not isinstance(data, dict):
        return None
    model = extract_model(data)
    if model is None:
        return None
    sid = extract_session_id(data) or os.path.splitext(os.path.basename(path))[0]
    return {"session": sid, "model": model, "used": extract_usage(data)}


def collect_sessions(cost_table, warn, act, home):
    sessions = []
    for path in find_session_files(home):
        rec = parse_session_file(path)
        if rec is None:
            continue
        model = rec["model"]
        used = rec["used"]
        limit = resolve_limit(model, cost_table)
        if limit is not None and isinstance(used, (int, float)):
            pct = round(used / limit * 100.0, 1)
            if pct >= act * 100:
                status = "ACT"
            elif pct >= warn * 100:
                status = "WARN"
            else:
                status = "OK"
        elif limit is not None:
            pct = None
            status = "OK"
        else:
            pct = None
            status = "UNKNOWN"
        sessions.append({
            "session": rec["session"],
            "model": model,
            "used": used if isinstance(used, (int, float)) else None,
            "limit": limit,
            "pct": pct,
            "status": status,
        })
    # deterministic: newest mtime first (already), then name
    sessions.sort(key=lambda s: s["session"])
    return sessions


def _render_human(sessions, warn, act):
    if not sessions:
        print("No opencode session records found (advisory - nothing to report).")
        return
    print("%-32s %-30s %10s %10s %6s  %s" % ("session", "model", "used", "limit", "pct", "status"))
    for s in sessions:
        used = str(s["used"]) if s["used"] is not None else "?"
        limit = str(s["limit"]) if s["limit"] is not None else "?"
        pct = ("%.1f" % s["pct"]) if s["pct"] is not None else "?"
        print("%-32s %-30s %10s %10s %6s  %s" % (
            s["session"], s["model"], used, limit, pct, s["status"]))
    act_n = sum(1 for s in sessions if s["status"] == "ACT")
    warn_n = sum(1 for s in sessions if s["status"] == "WARN")
    print("warn=%g act=%g  act_sessions=%d warn_sessions=%d" % (warn, act, act_n, warn_n))


def _render_json(sessions, warn, act):
    payload = {
        "warn_percent": warn,
        "act_percent": act,
        "total": len(sessions),
        "act_count": sum(1 for s in sessions if s["status"] == "ACT"),
        "warn_count": sum(1 for s in sessions if s["status"] == "WARN"),
        "sessions": sessions,
    }
    print(json.dumps(payload, indent=2, ensure_ascii=False))


def cmd_models(cost_table, as_json):
    rows = []
    for key in sorted(cost_table.keys()):
        entry = cost_table[key]
        if not isinstance(entry, dict):
            continue
        ctx = entry.get("context")
        free = entry.get("free")
        local = bool(entry.get("local", False))
        note = ""
        if isinstance(free, bool):
            note = "free" if free else "paid"
        if local:
            note = ("%s · local" % note) if note else "local"
        rows.append({"model": key, "context": ctx if isinstance(ctx, (int, float)) else None, "note": note})
    if as_json:
        print(json.dumps({"models": rows}, indent=2, ensure_ascii=False))
    else:
        print("%-40s %12s  %s" % ("model", "context", "note"))
        for r in rows:
            ctx = str(r["context"]) if r["context"] is not None else "?"
            print("%-40s %12s  %s" % (r["model"], ctx, r["note"]))


def cmd_status(cost_table, warn, act, as_json):
    home = os.environ.get("HOME") or os.path.expanduser("~")
    sessions = collect_sessions(cost_table, warn, act, home)
    if as_json:
        _render_json(sessions, warn, act)
    else:
        _render_human(sessions, warn, act)
    return 0


def cmd_check(cost_table, warn, act, strict, as_json):
    home = os.environ.get("HOME") or os.path.expanduser("~")
    sessions = collect_sessions(cost_table, warn, act, home)
    if as_json:
        _render_json(sessions, warn, act)
    else:
        _render_human(sessions, warn, act)
    act_n = sum(1 for s in sessions if s["status"] == "ACT")
    if strict and act_n > 0:
        return 1
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="context-budget.py",
        description="Report opencode session token usage against each model's context window.",
    )
    sub = parser.add_subparsers(dest="command")

    p_models = sub.add_parser("models", help="list models + context windows from routing.json")
    p_models.add_argument("--json", action="store_true", help="machine-readable output")

    p_status = sub.add_parser("status", help="scan sessions and report usage vs model limit")
    p_status.add_argument("--json", action="store_true", help="machine-readable output")

    p_check = sub.add_parser("check", help="status + exit 1 on ACT sessions (with --strict)")
    p_check.add_argument("--strict", action="store_true", help="exit 1 when any session is at ACT level")
    p_check.add_argument("--json", action="store_true", help="machine-readable output")

    args = parser.parse_args(argv)

    cost_table = load_cost_table()
    home = os.environ.get("HOME") or os.path.expanduser("~")
    warn, act = load_thresholds(home)

    if args.command == "models":
        cmd_models(cost_table, args.json)
        return 0
    if args.command == "status":
        return cmd_status(cost_table, warn, act, args.json)
    if args.command == "check":
        return cmd_check(cost_table, warn, act, args.strict, args.json)

    parser.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())
