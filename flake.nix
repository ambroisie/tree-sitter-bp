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
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
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
    in
    eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };

        bump-version = pkgs.writeShellScriptBin "bump-version" ''
          set -eu

          NEW_VERSION="''${1}"

          ${pkgs.jq}/bin/jq ".version = \"''${NEW_VERSION}\"" package.json > package.json.tmp
          mv package.json.tmp package.json
          ${pkgs.gnused}/bin/sed -i -e "s/version = \"[0-9.]\\+\"/version = \"''${NEW_VERSION}\"/" Cargo.toml

          git add Cargo.toml package.json
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

              tree-sitter = {
                enable = true;
                name = "tree-sitter tests";
                entry = "${tree-sitter-env}/bin/tree-sitter test --apply-all-captures";
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
              # FIXME: waiting on #301336
              # (tree-sitter.override { webUISupport = true; })
              tree-sitter
            ];

            inherit (checks.pre-commit) shellHook;
          };
        };

        packages = {
          default = packages.tree-sitter-blueprint;

          inherit (pkgs.tree-sitter.passthru.builtGrammars) tree-sitter-blueprint;

          inherit (pkgs) tree-sitter;
        };
      }) // {
      overlays = {
        default = final: prev: {
          tree-sitter = prev.tree-sitter.override {
            extraGrammars = {
              tree-sitter-blueprint = {
                src = ./.;
              };
            };
          };
        };
      };
    };
}
