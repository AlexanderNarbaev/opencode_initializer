#!/usr/bin/env python3
"""OpenCode SDK — Python wrapper for non-interactive agent use.

Usage:
    python3 -c "from oc_sdk import OpenCode; oc = OpenCode(); print(oc.ask('fix this bug'))"
    ./oc-sdk.py '<prompt>'
"""
import json
import os
import subprocess
import sys
import urllib.request as urllib_req


class OpenCode:
    def __init__(self, model=None, api_key=None, workdir=None):
        self.model = model or os.environ.get(
            "OPENCODE_MODEL", "deepseek/deepseek-v4-pro"
        )
        self.api_key = api_key or os.environ.get("DEEPSEEK_API_KEY", "")
        self.workdir = workdir or os.getcwd()
        self.cmd = ["opencode", "--model", self.model]
        if self.api_key:
            os.environ["DEEPSEEK_API_KEY"] = self.api_key

    def _run(self, prompt, timeout=300):
        args = self.cmd + ["--non-interactive", prompt]
        result = subprocess.run(
            args,
            capture_output=True,
            text=True,
            cwd=self.workdir,
            timeout=timeout,
        )
        return result

    def ask(self, prompt, files=None, timeout=300):
        """Ask OpenCode to perform a task. Returns structured response."""
        args = self.cmd + ["--non-interactive", prompt]
        if files:
            args.extend(["--files"] + files)
        result = subprocess.run(
            args,
            capture_output=True,
            text=True,
            cwd=self.workdir,
            timeout=timeout,
        )
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError:
            return {
                "status": "success" if result.returncode == 0 else "error",
                "output": result.stdout,
                "stderr": result.stderr,
            }

    def review(self, filepath, timeout=300):
        """Review a file for bugs, security issues, and style problems."""
        return self.ask(
            f"Review {filepath} for bugs, security issues, and style problems",
            timeout=timeout,
        )

    def generate(self, spec, output_file, timeout=600):
        """Generate code from spec and write to file."""
        return self.ask(
            f"Generate code for: {spec}. Write the result to {output_file}",
            timeout=timeout,
        )

    def list_models(self):
        """List available models from the local API gateway."""
        try:
            with urllib_req.urlopen(
                "http://localhost:4000/v1/models", timeout=10
            ) as resp:
                data = json.load(resp)
                return [m.get("id", "") for m in data.get("data", [])]
        except Exception:
            return ["deepseek/deepseek-v4-pro"]


def main():
    if len(sys.argv) < 2:
        print("Usage: oc-sdk.py '<prompt>' [--model MODEL] [--workdir DIR]")
        sys.exit(1)

    prompt = sys.argv[1]
    model = os.environ.get("OPENCODE_MODEL", "deepseek/deepseek-v4-pro")
    workdir = os.getcwd()

    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--model" and i + 1 < len(sys.argv):
            model = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--workdir" and i + 1 < len(sys.argv):
            workdir = sys.argv[i + 1]
            i += 2
        else:
            i += 1

    oc = OpenCode(model=model, workdir=workdir)
    result = oc.ask(prompt)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
