{ __nixpkgs__
, makeScript
, ...
}:
let

in
makeScript {
  name = "update";
  entrypoint = ./entrypoint.sh;
  searchPaths.bin = [
    __nixpkgs__.git
    __nixpkgs__.nix
  ];
}
