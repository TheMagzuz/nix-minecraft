{ lib, stdenvNoCC, goreleaser, fetchFromGitHub, buildGoModule }:
let
  mrpack-install = let mrpackVersion = "0.18.2-beta"; in
    buildGoModule {
      pname = "mrpack-install";
      version = mrpackVersion;
      src = fetchFromGitHub {
        owner = "nothub";
        repo = "mrpack-install";
        rev = "v${mrpackVersion}";
        hash = "sha256-g0AfC9RRyXfhUDI5oCCFjHvkbUFgmqKyrVnMJ7jiPkM=";
      };
      vendorHash = "sha256-4FKt/IcmI1ev/eHzQpicWkYWAh8axUgDL7QxXRioTnc=";
      doCheck = false;
    };
  fetchMrpack =
    { pname ? "mrpack"
    , version ? ""
    , url
    , packHash ? lib.fakeHash
    ,
    }@args:
    stdenvNoCC.mkDerivation {
      inherit pname;
      name = pname;
      dontUnpack = true;
      buildPhase = ''
        ${mrpack-install}/bin/mrpack-install '${url}' --server-dir "$out"
      '';

      dontFixup = true;

      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = packHash;

      passthru =
        let
          drv = fetchMrpack args;
        in
        {
          # Adds an attribute set of files to the derivation.
          # Useful to add server-specific mods not part of the pack.
          addFiles = files:
            stdenvNoCC.mkDerivation {
              inherit (drv) pname version;
              src = null;
              dontUnpack = true;
              dontConfig = true;
              dontBuild = true;
              dontFixup = true;

              installPhase = ''
                cp -as "${drv}" $out
                chmod u+w -R $out
              '' + lib.concatLines (lib.mapAttrsToList
                (name: file: ''
                  mkdir -p "$out/$(dirname "${name}")"
                  cp -as "${file}" "$out/${name}"
                '')
                files
              );

              passthru = { inherit (drv) manifest; };
              meta = drv.meta or { };
            };
        };

    };
in
fetchMrpack
