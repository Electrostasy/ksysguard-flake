# Based on https://github.com/juliosueiras-nix/nix-utils

{
  bundlerApp,
  nix-utils,
  stdenv,
  referencesByPopularity,
}:

pkg: extraFpmFlags:

let
  fpm = bundlerApp {
    pname = "fpm";
    gemdir = "${nix-utils}/utils/rpm-deb/fpm";
    exes = [ "fpm" ];
  };
in 

stdenv.mkDerivation {
  name = "deb-single-${pkg.name}";
  buildInputs = [
    fpm
  ];

  unpackPhase = "true";

  buildPhase = ''
    export HOME=$PWD
    mkdir -p ./nix/store/
    mkdir -p ./bin
    for item in "$(cat ${referencesByPopularity pkg})"
    do
      cp -r $item ./nix/store/
    done
    cp -r ${pkg}/bin/* ./bin/
    chmod -R a+rwx ./nix
    chmod -R a+rwx ./bin
    fpm -s dir -t deb --name ${pkg.name} ${extraFpmFlags} nix bin
  '';

  installPhase = ''
    mkdir -p $out
    cp -r *.deb $out
  '';
}
