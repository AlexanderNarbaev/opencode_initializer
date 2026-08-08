#!/usr/bin/env python3
# scripts/pii-guard.py — PII Sanitizer: 9 detectors, stdin→stdout redaction
# Used by: 45-pii-guard.sh (_pii_scan), 42-hooks.sh (pre-LLM-request gate), 24-websearch.sh (MCP sanitizer)
# Exit: 0 if no PII found, 1 if PII detected (gate usage)
# v3.0.0

import re
import sys
import json


# ── 9 PII detectors ─────────────────────────────────────────────────────────
PATTERNS = [
    # 1. Email
    (r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', 'email'),
    # 2. Russian phone (+7 or 8)
    (r'(?:\+7|8)[\s-]?\(?\d{3}\)?[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2}', 'phone_ru'),
    # 3. International phone (generic)
    (r'\+\d{1,3}[\s-]?\d{2,4}[\s-]?\d{3,4}[\s-]?\d{3,4}', 'phone_int'),
    # 4. INN (Russian tax ID: 10 or 12 digits)
    (r'\b\d{10}\b|\b\d{12}\b', 'inn'),
    # 5. SNILS (XXX-XXX-XXX XX or XXXXXXXXXXX)
    (r'\d{3}[\s-]?\d{3}[\s-]?\d{3}[\s-]?\d{2}', 'snils'),
    # 6. Russian passport (XX XX XXXXXX)
    (r'\d{2}\s?\d{2}\s?\d{6}', 'passport_ru'),
    # 7. Credit card (Luhn-validatable 13-19 digits with separator groups)
    (r'\b(?:\d{4}[\s-]?){3}\d{4}\b|\b\d{13,19}\b', 'credit_card'),
    # 8. IP address (IPv4)
    (r'\b(?:(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\b', 'ip_address'),
    # 9. API key leak (common prefixes: sk-, api-, key-, token, Bearer)
    (r'(?:sk-[a-zA-Z0-9]{20,}|api[_-]?key[=:]\s*["\']?[a-zA-Z0-9_-]{20,}["\']?|Bearer\s+[a-zA-Z0-9._-]{20,}|token[=:]\s*["\']?[a-zA-Z0-9_-]{20,}["\']?)', 'api_key'),
]


def pii_scan(text: str) -> tuple:
    """
    Scan text for PII patterns.
    Returns: (redacted_text, found_count, details)
    """
    found = []
    redacted = text

    for pattern, ptype in PATTERNS:
        matches = re.findall(pattern, redacted, re.IGNORECASE)
        if matches:
            for match in set(matches):  # unique matches
                placeholder = f'[REDACTED:{ptype}]'
                redacted = redacted.replace(str(match), placeholder)
            found.append({'type': ptype, 'count': len(matches), 'sample': str(matches[0])[:20]})

    return redacted, sum(f['count'] for f in found), found


def main():
    # Read from stdin
    raw = sys.stdin.read()

    if not raw.strip():
        print(json.dumps({'status': 'empty', 'pii_found': 0, 'redacted': ''}))
        sys.exit(0)

    # Detect mode: JSON input (for websearch sanitizer) vs text (for hook gate)
    try:
        data = json.loads(raw)
        is_json = True
    except (json.JSONDecodeError, ValueError):
        data = {'text': raw}
        is_json = False

    if is_json and isinstance(data, dict):
        # Recursive sanitize: scan all string values
        found_total = 0
        details_all = []
        redacted_data = {}

        for key, value in data.items():
            if isinstance(value, str):
                cleaned, count, details = pii_scan(value)
                redacted_data[key] = cleaned
                found_total += count
                details_all.extend(details)
            elif isinstance(value, (list, dict)):
                # Deep sanitize nested structures via re-serialization
                serialized = json.dumps(value, ensure_ascii=False)
                cleaned, count, details = pii_scan(serialized)
                redacted_data[key] = json.loads(cleaned) if count > 0 else value
                found_total += count
                details_all.extend(details)
            else:
                redacted_data[key] = value

        result = {
            'status': 'sanitized' if found_total > 0 else 'clean',
            'pii_found': found_total,
            'details': details_all[:20],  # cap at 20 details
            'redacted': redacted_data,
        }
    else:
        cleaned, count, details = pii_scan(raw)
        result = {
            'status': 'sanitized' if count > 0 else 'clean',
            'pii_found': count,
            'details': details[:20],
            'redacted': cleaned,
        }

    print(json.dumps(result, ensure_ascii=False))

    # Exit code: 1 if PII found (gate usage), 0 if clean
    sys.exit(1 if result['pii_found'] > 0 else 0)


if __name__ == '__main__':
    main()
