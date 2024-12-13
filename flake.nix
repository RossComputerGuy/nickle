{
  description = "Dart compiled with Zig";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    systems.url = "github:nix-systems/default-linux";
    flake-utils.url = "github:numtide/flake-utils";
    zig = {
      url = "github:ziglang/zig?ref=pull/20511/head";
      flake = false;
    };
    zon2nix = {
      url = "github:MidstallSoftware/zon2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      flake-utils,
      zon2nix,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      defaultOverlay =
        pkgs: prev: with pkgs; {
          zig =
            (prev.zig.overrideAttrs (
              finalAttrs: p: {
                version = "0.14.0-git+${inputs.zig.shortRev or "dirty"}";
                src = inputs.zig;

                doInstallCheck = false;

                postBuild = "";
                postInstall = "";

                outputs = [ "out" ];
              }
            )).override
              {
                llvmPackages = llvmPackages_19;
              };

          nickle = stdenv.mkDerivation (finalAttrs: {
            pname = "nickle";
            version = self.shortRev or "dirty";

            src = lib.cleanSource self;

            nativeBuildInputs = [
              pkgs.zig
              pkgs.zig.hook
            ];
          });

          zon2nix = stdenv.mkDerivation {
            pname = "zon2nix";
            version = "0.1.2";

            src = lib.cleanSource inputs.zon2nix;

            nativeBuildInputs = [
              pkgs.zig
              pkgs.zig.hook
            ];

            zigBuildFlags = [
              "-Dnix=${lib.getExe nix}"
            ];

            zigCheckFlags = [
              "-Dnix=${lib.getExe nix}"
            ];
          };
        };
    in
    flake-utils.lib.eachSystem (import systems) (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
          defaultOverlay
        ];
      in
      {
        packages = {
          default = pkgs.nickle;
        };

        devShells = {
          default = pkgs.nickle.overrideAttrs (
            finalAttrs: p: {
              nativeBuildInputs = p.nativeBuildInputs ++ [
                pkgs.zon2nix
                pkgs.wasmtime
              ];
            }
          );
        };

        legacyPackages = pkgs;
      }
    )
    // {
      overlays = {
        default = defaultOverlay;
        nickle = defaultOverlay;
      };
    };
}
