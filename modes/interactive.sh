#!/usr/bin/env bash
# modes/interactive.sh — interactive component-by-component selection
# Sources: lib/helpers.sh, lib/00-core.sh must be sourced before
set -euo pipefail

echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}     Ultimate Dev Machine Bootstrap v34.0 — INTERACTIVE${NC}"
echo -e "${GREEN}============================================================${NC}"
echo

# Collect required params first
if [ -z "${PROJECT_DIR:-}" ]; then
  read -r -p "Project directory [~/projects]: " input
  PROJECT_DIR="${input:-$HOME/projects}"
  export PROJECT_DIR
  mkdir -p "$PROJECT_DIR" 2>/dev/null || true
fi

if [ -z "${GIT_NAME:-}" ]; then
  read -r -p "Git user name: " GIT_NAME
fi
if [ -z "${GIT_EMAIL:-}" ]; then
  read -r -p "Git email: " GIT_EMAIL
fi

if [ -z "${DEEPSEEK_KEY:-}" ]; then
  read -r -p "DeepSeek API key (from https://platform.deepseek.com/): " DEEPSEEK_KEY
  export DEEPSEEK_API_KEY="${DEEPSEEK_KEY:-}"
fi

if [ -z "${API_KEY:-}" ]; then
  read -r -p "OpenCode Go API key (from https://opencode.ai/auth, Enter to skip): " API_KEY
fi

# Component selection
echo
echo -e "${CYAN}Select components to install (y/n):${NC}"
echo

DO_SYSTEM="y"; DO_DOCKER="y"; DO_CHROME="y"; DO_ZSH="y"
DO_JAVA="y";  DO_NODE="y";   DO_PYTHON="y"
DO_GO="y";    DO_RUST="y";   DO_DOTNET="y"
DO_OPENCODE="y"; DO_MCP="y"; DO_CHROMA="y"
DO_SHOKUNIN="y"; DO_TRIVY="y"; DO_PROJECT="y"; DO_LLM="y"

read -r -p "System packages (apt)? [Y/n]: " input; [ "$input" = "n" ] && DO_SYSTEM="n"
read -r -p "Docker? [Y/n]: " input; [ "$input" = "n" ] && DO_DOCKER="n"
read -r -p "Google Chrome (for Playwright/browser)? [Y/n]: " input; [ "$input" = "n" ] && DO_CHROME="n"
read -r -p "Zsh + Oh My Zsh + P10k? [Y/n]: " input; [ "$input" = "n" ] && DO_ZSH="n"
read -r -p "Java 25 + Gradle + Maven? [Y/n]: " input; [ "$input" = "n" ] && DO_JAVA="n"
read -r -p "Node.js 24 + npm? [Y/n]: " input; [ "$input" = "n" ] && DO_NODE="n"
read -r -p "Python 3.14 + uv? [Y/n]: " input; [ "$input" = "n" ] && DO_PYTHON="n"
read -r -p "Go (latest)? [Y/n]: " input; [ "$input" = "n" ] && DO_GO="n"
read -r -p "Rust? [Y/n]: " input; [ "$input" = "n" ] && DO_RUST="n"
read -r -p ".NET 10? [Y/n]: " input; [ "$input" = "n" ] && DO_DOTNET="n"
read -r -p "OpenCode CLI + Bun? [Y/n]: " input; [ "$input" = "n" ] && DO_OPENCODE="n"
read -r -p "MCP servers + LSP (13+10)? [Y/n]: " input; [ "$input" = "n" ] && DO_MCP="n"
read -r -p "ChromaDB + Muninn memory? [Y/n]: " input; [ "$input" = "n" ] && DO_CHROMA="n"
read -r -p "Shokunin ecosystem + Superpowers (62+ skills)? [Y/n]: " input; [ "$input" = "n" ] && DO_SHOKUNIN="n"
read -r -p "Trivy security scanner? [Y/n]: " input; [ "$input" = "n" ] && DO_TRIVY="n"
read -r -p "Local LLM runtimes (Ollama, vLLM, Open WebUI)? [Y/n]: " input; [ "$input" = "n" ] && DO_LLM="n"
read -r -p "Generate project files (AGENTS.md, WAL, docker-compose)? [Y/n]: " input; [ "$input" = "n" ] && DO_PROJECT="n"

echo
echo -e "${CYAN}Summary:${NC}"
echo "  Project:    $PROJECT_DIR"
echo "  Git:        ${GIT_NAME:-<not set>} <${GIT_EMAIL:-<not set>}>"
echo "  DeepSeek:   ${DEEPSEEK_KEY:+configured}${DEEPSEEK_KEY:-NOT SET}"
echo "  System:     $([ "$DO_SYSTEM" = "y" ] && echo "✓" || echo "✗")    Docker:     $([ "$DO_DOCKER" = "y" ] && echo "✓" || echo "✗")"
echo "  Chrome:     $([ "$DO_CHROME" = "y" ] && echo "✓" || echo "✗")    Zsh:        $([ "$DO_ZSH" = "y" ] && echo "✓" || echo "✗")    Java:       $([ "$DO_JAVA" = "y" ] && echo "✓" || echo "✗")"
echo "  Node:       $([ "$DO_NODE" = "y" ] && echo "✓" || echo "✗")    Python:     $([ "$DO_PYTHON" = "y" ] && echo "✓" || echo "✗")"
echo "  Go:         $([ "$DO_GO" = "y" ] && echo "✓" || echo "✗")    Rust:       $([ "$DO_RUST" = "y" ] && echo "✓" || echo "✗")    .NET: $([ "$DO_DOTNET" = "y" ] && echo "✓" || echo "✗")"
echo "  OpenCode:   $([ "$DO_OPENCODE" = "y" ] && echo "✓" || echo "✗")    MCP+LSP:    $([ "$DO_MCP" = "y" ] && echo "✓" || echo "✗")"
echo "  ChromaDB:   $([ "$DO_CHROMA" = "y" ] && echo "✓" || echo "✗")    Shokunin:   $([ "$DO_SHOKUNIN" = "y" ] && echo "✓" || echo "✗")"
echo "  Trivy:      $([ "$DO_TRIVY" = "y" ] && echo "✓" || echo "✗")    Project:    $([ "$DO_PROJECT" = "y" ] && echo "✓" || echo "✗")"
echo "  LLM:        $([ "$DO_LLM" = "y" ] && echo "✓" || echo "✗")"
echo
read -r -p "Proceed? [Y/n]: " confirm
[ "$confirm" = "n" ] && { warn "Aborted by user"; exit 0; }

# Set MODE to full for the actual execution
MODE="full"
# But guard each section with the selection flags
INTERACTIVE_DO_SYSTEM="$DO_SYSTEM"
INTERACTIVE_DO_DOCKER="$DO_DOCKER"
INTERACTIVE_DO_CHROME="$DO_CHROME"
INTERACTIVE_DO_ZSH="$DO_ZSH"
INTERACTIVE_DO_JAVA="$DO_JAVA"
INTERACTIVE_DO_NODE="$DO_NODE"
INTERACTIVE_DO_PYTHON="$DO_PYTHON"
INTERACTIVE_DO_GO="$DO_GO"
INTERACTIVE_DO_RUST="$DO_RUST"
INTERACTIVE_DO_DOTNET="$DO_DOTNET"
INTERACTIVE_DO_OPENCODE="$DO_OPENCODE"
INTERACTIVE_DO_MCP="$DO_MCP"
INTERACTIVE_DO_CHROMA="$DO_CHROMA"
INTERACTIVE_DO_SHOKUNIN="$DO_SHOKUNIN"
INTERACTIVE_DO_TRIVY="$DO_TRIVY"
INTERACTIVE_DO_PROJECT="$DO_PROJECT"
INTERACTIVE_DO_LLM="$DO_LLM"

# Do NOT exit — return to orchestrator to continue with step execution
