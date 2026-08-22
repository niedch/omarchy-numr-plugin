{
  description = "Development environment for omarchy-numr-plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    omarchy = {
      url = "github:basecamp/omarchy/quattro";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    omarchy,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          quickshell
          numr
          libqalculate
          cava
          upower
          wtype
          wl-clipboard
          cliphist
          libxkbcommon
          curl
          jq
          bluetui
          wiremix
          voxtype
          procps
          util-linux
          mise
          inotify-tools
          nodejs
          eslint
          prettier
          alejandra
          qt6.qtdeclarative
          # Python with dateutil for scripts
          (python3.withPackages (ps: [ps.python-dateutil]))
        ];

        shellHook = ''
          # Export the path of the upstream basecamp/omarchy repo from the Nix store
          export OMARCHY_PATH="${omarchy}"

          # Clean up the .dev directory when exiting the shell
          trap 'echo "Cleaning up .dev directory..."; rm -rf "$PWD/.dev"' EXIT

          echo ""
          echo -e "\033[1;32m=== omarchy-numr-plugin Dev Shell ===\033[0m"
          echo "Upstream basecamp/omarchy configuration loaded successfully!"
          echo ""

          # Run mise tasks ls to show available development commands
          mise tasks ls
          echo ""
        '';
      };
    });
  };
}
