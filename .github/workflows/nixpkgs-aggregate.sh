set -euxo pipefail

curl -L https://nixos.org/nix/install | sh
source ~/.nix-profile/etc/profile.d/nix.sh
nix-env -iA nixpkgs.python39

rm -rf data/nixpkgs/attrs
mkdir -p data/nixpkgs/attrs
python data/nixpkgs/aggregate.py

bash .github/workflows/push.sh "feat(conf): condense nixpkgs data" data
