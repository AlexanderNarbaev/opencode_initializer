{
  description = "OpenCode Initializer — AI-Native SDD Harness";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Runtime dependencies
        runtimeDeps = with pkgs; [
          bash
          coreutils
          curl
          git
          gnutar
          gzip
          jq
          python3
          shellcheck
          shfmt
        ];

        # Development dependencies
        devDeps = with pkgs; [
          docker
          docker-compose
          gh
          nodejs
          go
          rustc
          cargo
        ];

      in
      {
        # Default package
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "opencode-initializer";
          version = "8.0.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = runtimeDeps;

          installPhase = ''
            mkdir -p $out/{bin,share/opencode-initializer}

            # Copy project files
            cp -r src tests docs scripts $out/share/opencode-initializer/
            cp setup.sh apm.yml mise.toml $out/share/opencode-initializer/
            cp -r completions $out/share/opencode-initializer/

            # Create wrapper script
            makeWrapper $out/share/opencode-initializer/setup.sh $out/bin/opencode-init \
              --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
              --set SCRIPT_DIR $out/share/opencode-initializer/src/lib \
              --set PROJECT_ROOT $out/share/opencode-initializer

            # Install completions
            mkdir -p $out/share/bash-completion/completions \
                     $out/share/zsh/site-functions \
                     $out/share/fish/vendor_completions.d

            cp completions/opencode-init.bash $out/share/bash-completion/completions/
            cp completions/opencode-init.zsh $out/share/zsh/site-functions/_opencode-init
            cp completions/opencode-init.fish $out/share/fish/vendor_completions.d/
          '';

          meta = with pkgs.lib; {
            description = "AI-Native SDD Harness — one-command AI-enhanced development environment";
            homepage = "https://github.com/AlexanderNarbaev/opencode_initializer";
            license = licenses.mit;
            maintainers = [ "Alexander Narbaev" ];
            platforms = platforms.unix;
          };
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = runtimeDeps ++ devDeps;

          shellHook = ''
            echo "OpenCode Initializer development shell"
            echo "Run './setup.sh --full' to install"
            echo "Run 'mise run test' to run tests"
          '';
        };

        # NixOS module
        nixosModules.default = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.services.opencode-init;
          in
          {
            options.services.opencode-init = {
              enable = mkEnableOption "OpenCode Initializer";

              user = mkOption {
                type = types.str;
                default = "opencode";
                description = "User to run opencode-init as";
              };

              configPath = mkOption {
                type = types.path;
                default = "/etc/opencode-init/config.toml";
                description = "Path to configuration file";
              };

              autoUpdate = mkOption {
                type = types.bool;
                default = true;
                description = "Enable automatic updates";
              };
            };

            config = mkIf cfg.enable {
              environment.systemPackages = [ self.packages.${system}.default ];

              systemd.services.opencode-init = {
                description = "OpenCode Initializer";
                wantedBy = [ "multi-user.target" ];
                after = [ "network.target" "docker.service" ];

                serviceConfig = {
                  Type = "oneshot";
                  User = cfg.user;
                  ExecStart = "${self.packages.${system}.default}/bin/opencode-init --health";
                  RemainAfterExit = true;
                };
              };

              systemd.timers.opencode-init-update = mkIf cfg.autoUpdate {
                description = "OpenCode Initializer auto-update timer";
                wantedBy = [ "timers.target" ];

                timerConfig = {
                  OnCalendar = "daily";
                  Persistent = true;
                };
              };
            };
          };
      });
}
