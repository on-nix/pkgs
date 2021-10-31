set -euxo pipefail

curl -L https://nixos.org/nix/install | sh
source ~/.nix-profile/etc/profile.d/nix.sh
nix-env -iA nixpkgs.python39
nix-build -A projects.brotli.latest.python39.dev \
  https://github.com/on-nix/python/tarball/main
source result/setup

mkdir -p data/nixpkgs/outputs
python data/nixpkgs/outputs.py

bash .github/workflows/push.sh "feat(conf): fetch some nixpkgs outputs" data
