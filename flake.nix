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

          # Create development import directory structure safely
          mkdir -p .dev/qml-imports/qs

          # Symlink Omarchy shell modules
          rm -f .dev/qml-imports/qs/Commons .dev/qml-imports/qs/Ui
          ln -sf "${omarchy}/shell/Commons" .dev/qml-imports/qs/Commons
          ln -sf "${omarchy}/shell/Ui" .dev/qml-imports/qs/Ui

          # Construct and export QML import paths
          export QML_IMPORT_PATH="${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.quickshell}/lib/qt-6/qml:$PWD/.dev/qml-imports"
          export QML2_IMPORT_PATH="${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.quickshell}/lib/qt-6/qml:$PWD/.dev/qml-imports"

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
