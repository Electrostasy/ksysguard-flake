{
  description = "Standalone ksysguard flake";

  inputs = {
    # Last nixpkgs rev that contained the ksysguard derivation
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
          # Bundled graphical programs don't work on other distros without nixGL,
          # but software rendering is fine.
          ksysguard-wrapped = prev.ksysguard.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ [ prev.makeWrapper ];
            postInstall = ''
              wrapProgram $out/bin/ksysguard --set QT_XCB_GL_INTEGRATION none
            '';
          });

          # Create a bundle as with github:NixOS/bundlers#toDEB.
          bundle = nix-utils.bundlers.deb {
            inherit (prev) system;
            program = ksysguard-wrapped.outPath;
          };
        in
          # Add a post installation script for the *.deb package, to be run
          # when installed by dpkg or apt.
          bundle.overrideAttrs (old: {
            postInstall =
              let
                debPostInstall = prev.writeShellScript "after-install.sh" ''
                  ${prev.libcap}/bin/setcap "cap_net_raw+ep" "$out/libexec/ksysguard/.ksgrd_network_helper-wrapped"
                '';
              in ''
                ${prev.fpm}/bin/fpm -s deb -t deb --name ksysguard-standalone --after-install ${debPostInstall} "$out/*.deb"
              '';
          });
    };
  };
}
