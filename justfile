data ATTR:
  nix-build \
    --option sandbox true \
    --argstr attr nix \
    ./makes/update/lib.nix
  cat result/*
