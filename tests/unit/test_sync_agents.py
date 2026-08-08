#!/usr/bin/env python3
"""Fixture test for sync-agents.py — validates Kimi section removal on temp AGENTS.md."""
import os, re, tempfile, shutil

KIMI_PATTERN = re.compile(r'\n## Kimi/Moonshot Proxy.*?(?=\n## |\n---|\Z)', re.DOTALL)


def remove_kimi_section(filepath):
    """Replicate sync-agents.py logic on a single file."""
    with open(filepath) as f:
        content = f.read()
    new_content = KIMI_PATTERN.sub('', content)
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        return True
    return False


def test_removes_kimi_section():
    """Test: Kimi section is removed from AGENTS.md."""
    td = tempfile.mkdtemp()
    try:
        af = os.path.join(td, "AGENTS.md")
        with open(af, 'w') as f:
            f.write("""# Project AGENTS.md

## Kimi/Moonshot Proxy
Use Moonshot for fallback: `opencode-go/kimi-k3`
Proxy port: 11435

## Other Section
Nothing to remove here.
""")
        result = remove_kimi_section(af)
        assert result is True, "Should return True (section removed)"
        with open(af) as f:
            content = f.read()
        assert "Kimi/Moonshot Proxy" not in content, "Kimi section NOT removed"
        assert "Other Section" in content, "Other section wrongly removed"
        print("  PASS: test_removes_kimi_section")
    finally:
        shutil.rmtree(td, ignore_errors=True)


def test_noop_clean_file():
    """Test: no changes on clean AGENTS.md (no Kimi section)."""
    td = tempfile.mkdtemp()
    try:
        af = os.path.join(td, "AGENTS.md")
        original = "# Project AGENTS.md\n\n## Not Kimi\nJust regular content.\n"
        with open(af, 'w') as f:
            f.write(original)
        result = remove_kimi_section(af)
        assert result is False, "Should return False (no changes)"
        with open(af) as f:
            assert f.read() == original, "File content changed unnecessarily"
        print("  PASS: test_noop_clean_file")
    finally:
        shutil.rmtree(td, ignore_errors=True)


def test_removes_last_section():
    """Test: Kimi as the LAST section (edge case with \\Z)."""
    td = tempfile.mkdtemp()
    try:
        af = os.path.join(td, "AGENTS.md")
        with open(af, 'w') as f:
            f.write("""# Project AGENTS.md

## First Section
Some content.

## Kimi/Moonshot Proxy
Last section with Kimi/Moonshot stuff.
""")
        result = remove_kimi_section(af)
        assert result is True, "Should return True"
        with open(af) as f:
            content = f.read()
        assert "Kimi/Moonshot" not in content
        assert "## First Section" in content
        print("  PASS: test_removes_last_section")
    finally:
        shutil.rmtree(td, ignore_errors=True)


if __name__ == "__main__":
    test_removes_kimi_section()
    test_noop_clean_file()
    test_removes_last_section()
    print("\ntest_sync_agents: ALL 3 TESTS PASSED")
