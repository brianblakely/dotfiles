{
  description = "Standalone Home Manager reconciliation layer for Omarchy";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      homeDirectory = builtins.getEnv "HOME";
      system = builtins.currentSystem;
      username = builtins.baseNameOf homeDirectory;
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system}.home-manager = home-manager.packages.${system}.default;

      checks.${system}.reconciliation = pkgs.runCommand "reconciliation-tests" {
        nativeBuildInputs = with pkgs; [ bash coreutils diffutils gawk gnugrep gnused ];
      } ''
        test_reconciler="$TMPDIR/reconcile-config-imports"
        cp ${./scripts/reconcile-config-imports} "$test_reconciler"
        chmod u+w "$test_reconciler"
        patchShebangs "$test_reconciler"
        RECONCILER="$test_reconciler" \
          bash ${./tests/reconcile-config-imports.test.sh}
        touch "$out"
      '';

      homeConfigurations.default =
        assert homeDirectory != "";
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit homeDirectory username; };
          modules = [ ./home.nix ];
        };
    };
}
