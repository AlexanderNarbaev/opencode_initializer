# GitHub - MoonshotAI/kimi-code: Kimi Code CLI  —  The Starting Point for Next-Gen Agents · GitHub

> Source: https://github.com/moonshotai/kimi-code
> Cached: 2026-08-08T11:05:11.510Z

---

# Kimi Code CLI

[](#kimi-code-cli)
[](/MoonshotAI/kimi-code/blob/main/LICENSE) [](https://moonshotai.github.io/kimi-code/en/) 

[Documentation](https://moonshotai.github.io/kimi-code/en/) · [Issues](https://github.com/MoonshotAI/kimi-code/issues) · [中文](/MoonshotAI/kimi-code/blob/main/README.zh-CN.md)
[](/MoonshotAI/kimi-code/blob/main/docs/media/intro.gif)

## What is Kimi Code CLI

[](#what-is-kimi-code-cli)
Kimi Code CLI is an AI coding agent that runs in your terminal — it can read and edit code, run shell commands, search files, fetch web pages, and choose the next step based on the feedback it receives. It works out of the box with Moonshot AI’s Kimi models and can also be configured to use other compatible providers.

## Install

[](#install)
Install with the official script. No Node.js required.

- **macOS or Linux**:

curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash

- **Windows (PowerShell)**:

irm https://code.kimi.com/kimi-code/install.ps1 | iex
> 
On Windows, install [Git for Windows](https://gitforwindows.org/) before first launch because Kimi Code CLI uses the bundled Git Bash as its shell environment. If Git Bash is installed in a custom location, set `KIMI_SHELL_PATH` to the absolute path of `bash.exe`.

Then, run it with a new shell session:

kimi --version
For npm install, upgrade, uninstall, see [Getting Started](https://moonshotai.github.io/kimi-code/en/guides/getting-started).

## Quick Start

[](#quick-start)
Open a project and start the interactive UI:

cd your-project
kimi
On first launch, run `/login` inside Kimi Code CLI and choose either Kimi Code OAuth or a Moonshot AI Open Platform API key. After login, try your first task:

```
Take a look at this project and explain its main directories.

```

## Key Features

[](#key-features)

- **Single-binary distribution.** Install with one command: no Node.js setup, PATH gymnastics, or global module conflicts.

- **Blazing-fast startup.** The TUI is ready in milliseconds, so starting a session never feels heavy.

- **Purpose-built TUI.** A carefully tuned interface, optimized end to end for long, focused agent sessions.

- **Video input.** Drop a screen recording or demo clip into the chat and let the agent watch what is hard to describe in words — turn a reference clip into a LUT, a long video into a short, a screen recording into working code, and more.

- **AI-native MCP configuration.** Add, edit, and authenticate Model Context Protocol servers conversationally with `/mcp-config`, without hand-editing JSON.

- **Rich plugin ecosystem.** Install skills, MCP servers, and data sources from the marketplace or any GitHub repo, with each install's trust level surfaced up front.

- **Subagents for focused, parallel work.** Dispatch built-in `coder`, `explore`, and `plan` subagents in isolated contexts while keeping the main conversation clean.

- **Lifecycle hooks.** Run local commands at key points to gate risky tool calls, audit decisions, trigger desktop notifications, or connect to your own automation.

- **Editor & IDE integration (ACP).** Drive a Kimi Code CLI session straight from Zed, JetBrains, or any [Agent Client Protocol](https://agentclientprotocol.com/) client with `kimi acp`.

## Use it in your editor (ACP)

[](#use-it-in-your-editor-acp)
Kimi Code CLI speaks the [Agent Client Protocol](https://agentclientprotocol.com/), so ACP-compatible editors and IDEs (Zed, JetBrains, …) can drive a session over stdio. Log in once, then point your editor at the `kimi acp` subcommand — no extra login needed.

For Zed, add this to `~/.config/zed/settings.json`:

{
  "agent_servers": {
    "Kimi Code CLI": {
      "type": "custom",
      "command": "kimi",
      "args": ["acp"],
      "env": {}
    }
  }
}
Then open a new conversation in Zed's Agent panel. See [Using in IDEs](https://moonshotai.github.io/kimi-code/en/guides/ides) for JetBrains setup and troubleshooting, and the [`kimi acp` reference](https://moonshotai.github.io/kimi-code/en/reference/kimi-acp) for the full capability matrix.

## Docs

[](#docs)

- [Getting Started](https://moonshotai.github.io/kimi-code/en/guides/getting-started)

- [Interaction and approvals](https://moonshotai.github.io/kimi-code/en/guides/interaction)

- [Sessions](https://moonshotai.github.io/kimi-code/en/guides/sessions)

- [Using in IDEs (ACP)](https://moonshotai.github.io/kimi-code/en/guides/ides)

- [Configuration](https://moonshotai.github.io/kimi-code/en/configuration/config-files)

- [Command reference](https://moonshotai.github.io/kimi-code/en/reference/kimi-command)

## Develop

[](#develop)
Requirements: Node.js ≥ 24.15.0, pnpm 10.33.0.

git clone https://github.com/MoonshotAI/kimi-code.git
cd kimi-code
pnpm install
pnpm dev:cli    # run the CLI in dev mode
pnpm test       # run tests
pnpm typecheck  # TypeScript check
pnpm lint       # oxlint
pnpm build      # build all packages
See [CONTRIBUTING.md](/MoonshotAI/kimi-code/blob/main/CONTRIBUTING.md) for the full contribution guide.

## Community

[](#community)

- [Issues](https://github.com/MoonshotAI/kimi-code/issues)

- For security vulnerabilities, see [SECURITY.md](/MoonshotAI/kimi-code/blob/main/SECURITY.md).

## Acknowledgements

[](#acknowledgements)
Our TUI is built on top of [`pi-tui`](https://github.com/earendil-works/pi-mono/tree/main/packages/tui). We thank the authors of `pi-tui` for their valuable work.

## License

[](#license)
Released under the [MIT License](/MoonshotAI/kimi-code/blob/main/LICENSE).