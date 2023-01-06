{
  description = "Last working Nixpkgs revision for Ksysguard";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/60632718c063ad4d1bd1e2b82ba2f490fa64bbd8";
    nix-utils = {
      url = "github:juliosueiras-nix/nix-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = {
    self,
    nixpkgs,
    nix-utils
  }:
  let
    inherit (nixpkgs) lib;
  in
  {
    packages =
      lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
        lib.fix self.overlays.default nixpkgs.legacyPackages.${system});

    overlays.default = final: prev: {
      inherit (prev.plasma5Packages) libksysguard;

      ksysguard-standalone =
        let
          bundle = nix-utils.bundlers.deb {
            inherit (prev) system;
            program = prev.ksysguard.outPath;
          };
        in
          bundle.overrideAttrs (old: {
            postInstall =
              let
                debPostInstall = prev.writeShellScript "after-install.sh" ''
                  ${prev.libcap}/bin/setcap "cap_net_raw+ep" "$out/libexec/ksysguard/.ksgrd_network_helper-wrapped"
                '';
              in ''
                ${prev.fpm}/bin/fpm -s deb -t dev --name ksysguard-standalone --after-install ${debPostInstall} "$out/*.deb"
              '';
          });
    };
  };
}
