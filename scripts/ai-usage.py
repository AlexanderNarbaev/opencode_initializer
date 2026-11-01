#!/usr/bin/env python3
"""ai-usage.py — token and spend report for OpenCode sessions.

Reads the token-tracker JSONL that the opencode-token-tracker plugin appends
(one record per assistant message) and reports spend per provider/model/day.
DeepSeek is pay-as-you-go with a monthly budget from routing.json
(`cost_policy.monthly_budgets`); the prepaid token plans are marked in
`cost_table[*].prepaid` and cost nothing per token.

Usage:
  scripts/ai-usage.py                     # last 30 days, human table
  scripts/ai-usage.py --days 7 --json     # machine-readable
  scripts/ai-usage.py --budget 10         # override the DeepSeek budget
Exit: 0 under budget, 1 at/over budget (useful for cron/monitoring).
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from collections import defaultdict

DEFAULT_LOG = "~/.config/opencode/logs/token-tracker/tokens.jsonl"
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_ROUTING = os.path.join(REPO_ROOT, "src", "data", "routing.json")


def load_routing(path: str) -> dict:
    try:
        with open(os.path.expanduser(path), encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return {}


def load_events(path: str, cutoff_ms: int) -> list[dict]:
    events: list[dict] = []
    try:
        fh = open(os.path.expanduser(path), encoding="utf-8")
    except OSError:
        return events
    with fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            if rec.get("type") not in (None, "tokens"):
                continue
            ts = rec.get("_ts") or 0
            if ts and ts < cutoff_ms:
                continue
            events.append(rec)
    return events


def aggregate(events: list[dict]) -> tuple[dict, dict, dict, dict]:
    providers: dict[str, dict] = defaultdict(lambda: {"cost": 0.0, "input": 0, "output": 0, "messages": 0})
    models: dict[str, dict] = defaultdict(lambda: {"cost": 0.0, "input": 0, "output": 0, "messages": 0})
    days: dict[str, float] = defaultdict(float)
    totals = {"cost": 0.0, "input": 0, "output": 0, "messages": 0}
    for rec in events:
        provider = str(rec.get("provider") or "unknown")
        model = f"{provider}/{rec.get('model') or 'unknown'}"
        cost = float(rec.get("cost") or 0.0)
        inp = int(rec.get("input") or 0)
        out = int(rec.get("output") or 0)
        for bucket in (providers[provider], models[model]):
            bucket["cost"] += cost
            bucket["input"] += inp
            bucket["output"] += out
            bucket["messages"] += 1
        totals["cost"] += cost
        totals["input"] += inp
        totals["output"] += out
        totals["messages"] += 1
        ts = rec.get("_ts")
        if ts:
            day = time.strftime("%Y-%m-%d", time.localtime(ts / 1000))
            days[day] += cost
    return providers, models, days, totals


def main() -> int:
    ap = argparse.ArgumentParser(description="OpenCode token and spend report")
    ap.add_argument("--days", type=int, default=30, help="window in days (default 30)")
    ap.add_argument("--log", default=DEFAULT_LOG, help="token-tracker JSONL path")
    ap.add_argument("--routing", default=DEFAULT_ROUTING, help="routing.json path (budgets, prepaid list)")
    ap.add_argument("--budget", type=float, default=None, help="DeepSeek monthly budget in USD")
    ap.add_argument("--warn-at", type=float, default=80.0, help="warn when spend reaches this %% of budget")
    ap.add_argument("--json", action="store_true", help="print JSON instead of a table")
    args = ap.parse_args()

    routing = load_routing(args.routing)
    policy = routing.get("cost_policy") or {}
    budgets = policy.get("monthly_budgets") or {}
    budget = args.budget if args.budget is not None else float(budgets.get("deepseek") or 0)
    prepaid = {k for k, v in (routing.get("cost_table") or {}).items() if isinstance(v, dict) and v.get("prepaid")}

    cutoff = int((time.time() - args.days * 86400) * 1000)
    events = load_events(args.log, cutoff)
    providers, models, days, totals = aggregate(events)

    prepaid_providers = {m.split("/", 1)[0] for m in prepaid if "/" in m}
    billable = {k: v for k, v in providers.items() if k not in prepaid_providers}
    prepaid_value = sum(v["cost"] for k, v in providers.items() if k in prepaid_providers)
    billable_cost = sum(v["cost"] for v in billable.values())

    deepseek = providers.get("deepseek", {"cost": 0.0})
    ds_spent = round(float(deepseek["cost"]), 4)
    ratio = (ds_spent / budget) if budget > 0 else 0.0
    over = budget > 0 and ds_spent >= budget

    if args.json:
        print(json.dumps({
            "days": args.days,
            "since": time.strftime("%Y-%m-%d", time.localtime(cutoff / 1000)),
            "log": os.path.expanduser(args.log),
            "total_cost": round(totals["cost"], 4),
            "billable_cost": round(billable_cost, 4),
            "prepaid_value": round(prepaid_value, 4),
            "prepaid_providers": sorted(prepaid_providers),
            "tokens": {"input": totals["input"], "output": totals["output"]},
            "messages": totals["messages"],
            "providers": {k: {kk: (round(vv, 4) if isinstance(vv, float) else vv) for kk, vv in v.items()}
                          | {"prepaid": k in prepaid_providers}
                          for k, v in sorted(providers.items(), key=lambda kv: -kv[1]["cost"])},
            "models": {k: {kk: (round(vv, 4) if isinstance(vv, float) else vv) for kk, vv in v.items()}
                       for k, v in sorted(models.items(), key=lambda kv: -kv[1]["cost"])},
            "daily": {k: round(v, 4) for k, v in sorted(days.items())},
            "deepseek": {"spent": ds_spent, "budget": budget, "ratio": round(ratio, 3), "over_budget": over},
            "prepaid_models": sorted(prepaid),
        }, indent=2))
        return 1 if over else 0

    print(f"AI usage — last {args.days} day(s), since {time.strftime('%Y-%m-%d', time.localtime(cutoff / 1000))}")
    if not events:
        print(f"  no token records in {os.path.expanduser(args.log)}")
        return 0
    print(f"\n  {'provider':<26} {'cost $':>9} {'input':>12} {'output':>12} {'msgs':>7}")
    for name, row in sorted(providers.items(), key=lambda kv: -kv[1]["cost"]):
        tag = " (prepaid)" if any(m.startswith(name + "/") for m in prepaid) else ""
        print(f"  {name + tag:<26} {row['cost']:>9.4f} {row['input']:>12,} {row['output']:>12,} {row['messages']:>7}")
    print(f"  {'TOTAL':<26} {totals['cost']:>9.4f} {totals['input']:>12,} {totals['output']:>12,} {totals['messages']:>7}")
    print(f"\n  Billable spend: ${billable_cost:.4f}   Plan value covered: ${prepaid_value:.4f}")

    if budget > 0:
        pct = ratio * 100
        state = "OVER BUDGET" if over else ("WARNING" if pct >= args.warn_at else "ok")
        print(f"\n  DeepSeek (pay-as-you-go): ${ds_spent:.4f} / ${budget:.2f}  ({pct:.1f}%)  [{state}]")
    else:
        print("\n  DeepSeek budget: not configured (cost_policy.monthly_budgets.deepseek)")
    if prepaid:
        print(f"  Prepaid routes (no marginal cost): {len(prepaid)} model(s)")
    return 1 if over else 0


if __name__ == "__main__":
    sys.exit(main())
