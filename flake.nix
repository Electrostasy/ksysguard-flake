{
  description = "Last working Nixpkgs revision for Ksysguard";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/60632718c063ad4d1bd1e2b82ba2f490fa64bbd8";
  
  outputs = {
    self,
    nixpkgs
  }:
  let
    inherit (nixpkgs) lib;
  in
  {
    packages =
      lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
        lib.fix self.overlays.default nixpkgs.legacyPackages.${system});

    overlays.default = final: prev: {
      # For convenience
      inherit (prev.plasma5Packages) libksysguard;

      ksysguard-standalone = prev.ksysguard.overrideAttrs (old: {
        postFixup = ''
          ${prev.libcap}/bin/setcap "cap_net_raw+ep" "$out/libexec/ksysguard/.ksgrd_network_helper-wrapped"
        '';
      });
    };
  };
}
