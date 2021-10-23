{
  inputs = {
    flakeUtils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
  };
  outputs = { self, ... } @ inputs:
    inputs.flakeUtils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        nixpkgs = inputs.nixpkgs.legacyPackages.${system};
      in
      {
        packages = inputs.flakeUtils.lib.flattenTree
          {

            nixpkgs =
              let
                attrsContent = builtins.readFile ./data/nixpkgs/attrs.json;
                attrs = builtins.fromJSON attrsContent;

                commitsContent = builtins.readFile ./data/nixpkgs/commits.json;
                commits = builtins.fromJSON commitsContent;

                commitsToEvaluate = nixpkgs.lib.lists.take 1
                  (builtins.filter
                    (commit: !builtins.pathExists
                      "${self.sourceInfo.outPath}/data/nixpkgs/commits/${commit}.json")
                    (commits));

                getDataForCommit = commit:
                  let
                    nixpkgsToTrack = import
                      (builtins.fetchTarball {
                        url = "https://github.com/nixos/nixpkgs/archive/${commit}.tar.gz";
                      })
                      { };
                  in
                  builtins.foldl'
                    (data: attr:
                      let
                        attrPath = nixpkgs.lib.strings.splitString "." attr;
                      in
                      if nixpkgs.lib.attrsets.hasAttrByPath attrPath nixpkgsToTrack
                      then
                        let
                          pkg = nixpkgs.lib.attrsets.attrByPath attrPath { } nixpkgsToTrack;
                          drvName = builtins.parseDrvName pkg.drvAttrs.name;
                        in
                        data // { "${attr}" = drvName.version; }
                      else data)
                    { }
                    attrs;
              in
              nixpkgs.linkFarm "nixpkgs"
                (builtins.map
                  (commit: {
                    name = "data/nixpkgs/commits/${commit}.json";
                    path = nixpkgs.stdenv.mkDerivation {
                      builder = builtins.toFile "builder.sh" ''
                        source $stdenv/setup
                        jq < $dataPath > $out
                      '';
                      buildInputs = [ nixpkgs.jq ];
                      data = builtins.toJSON (getDataForCommit commit);
                      name = commit;
                      passAsFile = [ "data" ];
                    };
                  })
                  commitsToEvaluate);
          };

        apps = { };
      });
}
