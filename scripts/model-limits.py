#!/usr/bin/env python3
"""model-limits.py — derive context/output limits from the model catalog.

Limits must come from the model, not from hand-typed numbers. This tool reads the
models.dev catalog (https://models.dev/api.json) and reconciles it with
src/data/routing.json:

    show [--json]     table of provider/model -> context/output (catalog values)
    check [--json]    exit 1 when routing.json disagrees with the catalog
    sync              rewrite routing.json cost_table[].context / .output from
                      the catalog (backup written next to the file)

Unresolvable models (local ollama tags, retired ids) are reported and never
overwritten: their existing values stay as an explicit local override.

Catalog caching: ~/.cache/opencode-setup/models-dev.json (24 h TTL).
Offline / tests: --catalog PATH (a models.dev-shaped JSON file) skips the network.

Stdlib only.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import time
import urllib.request
from pathlib import Path

CATALOG_URL = "https://models.dev/api.json"
CACHE_TTL = 24 * 3600


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def cache_path() -> Path:
    base = os.environ.get("XDG_CACHE_HOME") or os.path.join(os.path.expanduser("~"), ".cache")
    return Path(base) / "opencode-setup" / "models-dev.json"


def load_catalog(path: str | None, offline: bool = False) -> dict:
    if path:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)

    cached = cache_path()
    fresh = cached.exists() and (time.time() - cached.stat().st_mtime) < CACHE_TTL
    if offline:
        if not cached.exists():
            raise SystemExit("model-limits: --offline but no cached catalog at %s" % cached)
        with open(cached, encoding="utf-8") as fh:
            return json.load(fh)
    if fresh:
        with open(cached, encoding="utf-8") as fh:
            return json.load(fh)

    try:
        req = urllib.request.Request(CATALOG_URL, headers={"User-Agent": "opencode-initializer/model-limits"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode("utf-8")
        data = json.loads(raw)
        cached.parent.mkdir(parents=True, exist_ok=True)
        cached.write_text(raw, encoding="utf-8")
        return data
    except Exception as exc:  # network down: fall back to a stale cache if present
        if cached.exists():
            print("model-limits: network failed (%s), using stale cache" % exc, file=sys.stderr)
            with open(cached, encoding="utf-8") as fh:
                return json.load(fh)
        raise SystemExit("model-limits: cannot fetch %s and no cache: %s" % (CATALOG_URL, exc))


def resolve(catalog: dict, key: str) -> dict | None:
    """provider/model -> catalog model entry (case-insensitive model match)."""
    if "/" not in key:
        return None
    provider, model = key.split("/", 1)
    entry = catalog.get(provider)
    if not isinstance(entry, dict):
        return None
    models = entry.get("models") or {}
    if model in models:
        return models[model]
    lowered = model.lower()
    for name, meta in models.items():
        if name.lower() == lowered:
            return meta
    return None


def _limit_field(field: str) -> str:
    """cost_table uses `context` for the window and `max_output_tokens` for the
    completion cap; `output` there is the OUTPUT PRICE per 1M tokens."""
    return "context" if field == "context" else "max_output_tokens"


def limit_of(meta: dict | None) -> dict | None:
    if not meta:
        return None
    lim = meta.get("limit") or {}
    context = lim.get("context")
    output = lim.get("output")
    if context is None and output is None:
        return None
    return {"context": context, "output": output}


def routing_path() -> Path:
    return Path(os.environ.get("ROUTING_JSON") or (repo_root() / "src" / "data" / "routing.json"))


def load_routing() -> dict:
    with open(routing_path(), encoding="utf-8") as fh:
        return json.load(fh)


def compute(catalog: dict, routing: dict) -> tuple[dict, list[str]]:
    table = routing.get("cost_table") or {}
    resolved: dict[str, dict] = {}
    unresolved: list[str] = []
    for key in table:
        lim = limit_of(resolve(catalog, key))
        if lim is None:
            unresolved.append(key)
        else:
            resolved[key] = lim
    return resolved, unresolved


def cmd_show(args) -> int:
    catalog = load_catalog(args.catalog, args.offline)
    routing = load_routing()
    resolved, unresolved = compute(catalog, routing)
    if args.json:
        print(json.dumps({"resolved": resolved, "unresolved": unresolved}, indent=2))
        return 0
    print(f"{'model':44} {'context':>10} {'output':>9}")
    for key, lim in resolved.items():
        print(f"{key:44} {str(lim['context']):>10} {str(lim['output']):>9}")
    for key in unresolved:
        print(f"{key:44} {'(unresolved: local override)':>21}")
    print(f"\nresolved {len(resolved)} / {len(resolved) + len(unresolved)} models")
    return 0


def cmd_check(args) -> int:
    catalog = load_catalog(args.catalog, args.offline)
    routing = load_routing()
    resolved, unresolved = compute(catalog, routing)
    table = routing.get("cost_table") or {}
    drift = []
    for key, lim in resolved.items():
        current = table.get(key) or {}
        for field in ("context", "output"):
            want = lim.get(field)
            have = current.get(_limit_field(field))
            if want is None:
                continue
            if have != want:
                drift.append({"model": key, "field": field, "routing": have, "catalog": want})
    if args.json:
        print(json.dumps({"drift": drift, "unresolved": unresolved}, indent=2))
    else:
        for d in drift:
            print(f"DRIFT {d['model']}: {d['field']} routing={d['routing']} catalog={d['catalog']}")
        print(f"model-limits: {'FAIL' if drift else 'OK'} ({len(resolved)} resolved, {len(unresolved)} local overrides)")
    return 1 if drift else 0


def cmd_sync(args) -> int:
    catalog = load_catalog(args.catalog, args.offline)
    path = routing_path()
    routing = load_routing()
    resolved, unresolved = compute(catalog, routing)
    table = routing.setdefault("cost_table", {})
    changed = []
    for key, lim in resolved.items():
        entry = table.setdefault(key, {})
        for field in ("context", "output"):
            want = lim.get(field)
            if want is None:
                continue
            if entry.get(_limit_field(field)) != want:
                changed.append((key, field, entry.get(_limit_field(field)), want))
                entry[_limit_field(field)] = want
    if changed and not args.dry_run:
        backup = path.with_suffix(path.suffix + ".bak-%s" % time.strftime("%Y%m%dT%H%M%S"))
        shutil.copy2(path, backup)
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(routing, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
        print(f"model-limits: wrote {path} (backup {backup.name})")
    for key, field, old, new in changed:
        print(f"{'would update' if args.dry_run else 'updated'} {key}.{field}: {old} -> {new}")
    for key in unresolved:
        print(f"kept local override for {key} (not in catalog)")
    print(f"model-limits: {len(changed)} change(s), {len(resolved)} catalog models, {len(unresolved)} overrides")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--catalog", help="path to a models.dev-shaped JSON (skips the network)")
    ap.add_argument("--offline", action="store_true", help="use the cached catalog only")
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name, fn in (("show", cmd_show), ("check", cmd_check), ("sync", cmd_sync)):
        p = sub.add_parser(name)
        p.add_argument("--json", action="store_true")
        if name == "sync":
            p.add_argument("--dry-run", action="store_true")
        p.set_defaults(func=fn)
    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
