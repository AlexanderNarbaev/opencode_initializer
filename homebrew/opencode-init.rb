# Homebrew Formula for opencode_initializer
# https://docs.brew.sh/Formula-Cookbook

class OpencodeInit < Formula
  desc "AI-Native SDD Harness — one-command AI-enhanced development environment"
  homepage "https://github.com/AlexanderNarbaev/opencode_initializer"
  url "https://github.com/AlexanderNarbaev/opencode_initializer/archive/refs/tags/v8.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on "bash"
  depends_on "python@3.14"
  depends_on "docker"
  depends_on "git"
  depends_on "jq"
  depends_on "curl"

  def install
    # Install scripts
    libexec.install "src"
    libexec.install "tests"
    libexec.install "docs"
    libexec.install "setup.sh"
    libexec.install "apm.yml"
    libexec.install "mise.toml"

    # Create wrapper script
    (bin/"opencode-init").write <<~EOS
      #!/usr/bin/env bash
      export SCRIPT_DIR="#{libexec}/src/lib"
      export PROJECT_ROOT="#{libexec}"
      exec bash "#{libexec}/setup.sh" "$@"
    EOS

    # Install completions
    bash_completion.install "completions/opencode-init.bash"
    zsh_completion.install "completions/opencode-init.zsh"
    fish_completion.install "completions/opencode-init.fish"

    # Install man page
    # man1.install "docs/man/opencode-init.1"
  end

  def caveats
    <<~EOS
      To get started:
        opencode-init --full

      For health check:
        opencode-init --health

      Shell completions have been installed.
      Restart your shell or run:
        source ~/.bashrc  # bash
        source ~/.zshrc   # zsh
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode-init --version")
  end
end
