{
  description = "A tree-sitter grammar for Blueprint";

  inputs = {
    flake-utils = {
      type = "github";
      owner = "numtide";
      repo = "flake-utils";
      ref = "main";
    };

    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixpkgs-unstable";
    };

    pre-commit-hooks = {
      type = "github";
      owner = "cachix";
      repo = "pre-commit-hooks.nix";
      ref = "master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , pre-commit-hooks
    }:
    let
      inherit (flake-utils.lib) eachDefaultSystem;
      inherit (nixpkgs) lib;
    in
    eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };

        nvim-test-runner = pkgs.writeShellApplication {
          name = "nvim-test-runner";

          runtimeInputs = with pkgs; [
            highlight-assertions
            neovim
          ];

          text = ''
            export NVIM_PLENARY='${pkgs.vimPlugins.plenary-nvim}'
            export NVIM_TREESITTER='${pkgs.vimPlugins.nvim-treesitter}'
            export NVIM_TREESITTER_TEXTOBJECTS='${pkgs.vimPlugins.nvim-treesitter-textobjects}'
            export NVIM_TREESITTER_PARSER='${pkgs.vimPlugins.nvim-treesitter.grammarToPlugin self.packages.${system}.tree-sitter-bp}'

            # FIXME: not sure why, but I get different behaviour when left untouched
            XDG_CONFIG_HOME=$(mktemp -d)
            export XDG_CONFIG_HOME

            nvim --headless --noplugin -u ${scripts/minimal_init.lua} \
                -c "PlenaryBustedDirectory test/ { minimal_init = '${./scripts/minimal_init.lua}' }"
          '';
        };

        bump-version = pkgs.writeShellScriptBin "bump-version" ''
          set -eu

          NEW_VERSION="''${1}"

          ${pkgs.jq}/bin/jq ".version = \"''${NEW_VERSION}\"" package.json > package.json.tmp
          mv package.json.tmp package.json
          ${pkgs.jq}/bin/jq ".metadata.version = \"''${NEW_VERSION}\"" tree-sitter.json > tree-sitter.json.tmp
          mv tree-sitter.json.tmp tree-sitter.json
          ${pkgs.gnused}/bin/sed -i -e "s/version = \"[0-9.]\\+\"/version = \"''${NEW_VERSION}\"/" Cargo.toml
          ${pkgs.gnused}/bin/sed -i -e "s/version = \"[0-9.]\\+\"/version = \"''${NEW_VERSION}\"/" pyproject.toml

          make

          git add Cargo.toml package.json pyproject.toml tree-sitter.json src/parser.c
          echo "Release ''${NEW_VERSION}" | git commit -eF -
          git tag -a "v''${NEW_VERSION}" -m "Release ''${NEW_VERSION}"
        '';

        tree-sitter-env = pkgs.stdenv.mkDerivation {
          name = "tree-sitter-env";

          nativeBuildInputs = with pkgs; [
            makeWrapper
          ];

          dontUnpack = true;

          dontBuild = true;

          installPhase = ''
            mkdir -p $out/bin
            makeWrapper \
              ${pkgs.tree-sitter}/bin/tree-sitter \
              $out/bin/tree-sitter \
              --prefix PATH : "${with pkgs; lib.makeBinPath [stdenv.cc nodejs]}"
          '';
        };
      in
      rec {
        checks = {
          pre-commit = pre-commit-hooks.lib.${system}.run {
            src = ./.;

            hooks = {
              nixpkgs-fmt = {
                enable = true;
              };

              nvim-test-runner = {
                enable = true;
                name = "nvim tests";
                entry = "${lib.getExe nvim-test-runner}";
                pass_filenames = false;
              };

              tree-sitter = {
                enable = true;
                name = "tree-sitter tests";
                entry = "${tree-sitter-env}/bin/tree-sitter test";
                pass_filenames = false;
              };

              tree-sitter-files = {
                enable = true;
                name = "tree-sitter generated files";
                entry = "${tree-sitter-env}/bin/tree-sitter generate";
                pass_filenames = false;
              };
            };
          };
        };

        devShells = {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              bump-version
              nodejs
              nvim-test-runner
              # FIXME: waiting on #301336
              # (tree-sitter.override { webUISupport = true; })
              tree-sitter
            ];

            inherit (checks.pre-commit) shellHook;
          };
        };

        packages = {
          default = packages.tree-sitter-bp;

          inherit (pkgs.tree-sitter.passthru.builtGrammars) tree-sitter-bp;

          inherit (pkgs) tree-sitter;
        };
      }) // {
      overlays = {
        default = final: prev: {
          tree-sitter = prev.tree-sitter.override {
            extraGrammars = {
              tree-sitter-bp = {
                src = ./.;
              };
            };
          };
        };
      };
    };
}
