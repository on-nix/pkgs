{ attr
, commit
,
}:
let
  nixpkgs = import <nixpkgs> { };

  inherit (nixpkgs.lib.attrsets) getAttrFromPath;
  inherit (nixpkgs.lib.lists) init;
  inherit (nixpkgs.lib.strings) splitString;
  inherit (nixpkgs.stdenv) mkDerivation;

  pkg = getAttrFromPath (splitString "." attr) (import ../../nixpkgs { });

  getAttr = attrs: options: default:
    builtins.foldl'
      (result: option:
        if result == default && builtins.hasAttr option attrs
        then attrs.${option}
        else default)
      (default)
      (options);

  description = getAttr pkg.meta [ "longDescription" ] null;
  homepage = getAttr pkg.meta [ "homepage" ] null;
  maintainers = getAttr pkg.meta [ "maintainers" ] null;
  outputs = builtins.listToAttrs (builtins.map
    (output: {
      name = output;
      value = init (splitString "\n" (builtins.readFile (mkDerivation {
        name = "list";
        builder = builtins.toFile "builder.sh" ''
          source $stdenv/setup
          cd $path
          find . -type f | while read -r path;
          do echo "''${path:1}" >> $out
          done
        '';
        buildInputs = [ nixpkgs.findutils ];
        path = pkg.${output};
      })));
    })
    (getAttr pkg [ "outputs" ] [ ]));
  platforms = getAttr pkg.meta [ "platforms" ] null;
  summary = getAttr pkg.meta [ "description" ] null;
  version = (builtins.parseDrvName pkg.name).version;

  data = {
    inherit attr;
    inherit commit;
    inherit description;
    inherit homepage;
    inherit maintainers;
    inherit outputs;
    inherit platforms;
    inherit summary;
    inherit version;
  };
in
mkDerivation {
  builder = builtins.toFile "builder.sh" ''
    source $stdenv/setup
    mkdir $out
    jq < $dataPath > $out/$version
  '';
  buildInputs = [ nixpkgs.jq ];
  data = builtins.toJSON data;
  name = data.attr;
  passAsFile = [ "data" ];
  version = data.version;
}
