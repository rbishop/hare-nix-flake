{
  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hare = 
      let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;
        makeWrapper = pkgs.makeWrapper;
        binutils-unwrapped = pkgs.binutils-unwrapped;
        stdenv = pkgs.stdenv;
        fetchFromSourcehut = pkgs.fetchFromSourcehut;
      in
        stdenv.mkDerivation {
          pname = "hare";
          version = "unstable-2023-09-23";

          src = fetchFromSourcehut {
            owner = "~sircmpwn";
            repo = "hare";
            rev = "HEAD";
            hash = "sha256-5/ObckDxosqUkFfDVhGA/0kwjFzDUxu420nkfa97vqM=";
          };

          nativeBuildInputs = [
            binutils-unwrapped
            makeWrapper
            pkgs.harePackages.harec
            pkgs.qbe
            pkgs.scdoc
          ];

          buildInputs = [
            binutils-unwrapped
            pkgs.harePackages.harec
            pkgs.qbe
          ];

          strictDeps = true;

          configurePhase = 
            let
              arch = "x86_64";
              platform = "linux";
              hareflags = "";
              config-file = pkgs.substituteAll {
                src = ./config-template.mk;
                inherit arch platform hareflags;
              };
            in
              ''
                runHook preConfigure

                export HARECACHE="$NIX_BUILD_TOP/.harecache"
                export BINOUT="$NIX_BUILD_TOP/.bin"
                cat ${config-file} > config.mk

                runHook postConfigure
              '';

          makeFlags = [
            "PREFIX=${placeholder "out"}"
          ];

          doCheck = true;

          postInstall =
            let
              binPath = lib.makeBinPath [
                binutils-unwrapped
                pkgs.harePackages.harec
                pkgs.qbe
              ];
            in
              ''
                wrapProgram $out/bin/hare --prefix PATH : ${binPath}
              '';

          setupHook = ./setup-hook.sh;
        };
  };
}
