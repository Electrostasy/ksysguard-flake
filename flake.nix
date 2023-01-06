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

          toPackage = program:
            let
              inherit (builtins.parseDrvName (builtins.elemAt (builtins.split "/[0-9a-df-np-sv-z]{32}-" program.outPath) 2)) name;
            in
              prev.runCommand name { } ''
                mkdir -p $out/bin
                ln -s ${program} $out/bin/.
              '';

          afterInstallScript = prev.writeShellScript "after-install.sh" ''
            ${prev.libcap}/bin/setcap "cap_net_raw+ep" "$out/libexec/ksysguard/.ksgrd_network_helper-wrapped"
          '';

          customControl = prev.writeText "custom-control.txt" ''
            Package: ksysguard-standalone
            Version: 1.0
            License: unknown
            Vendor: none
            Architecture: amd64
            Maintainer: <@localhost>
            Installed-Size: 0
            Section: default
            Priority: extra
            Homepage: http://example.com/no-uri-given
            Description: no description given
          '';
        in
          (prev.callPackage ./bundle-deb.nix { inherit nix-utils; })
            (toPackage ksysguard-wrapped)
            "--deb-custom-control ${customControl} --after-install ${afterInstallScript}";
    };
  };
}
