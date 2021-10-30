set -euxo pipefail

curl -L https://nixos.org/nix/install | sh
source ~/.nix-profile/etc/profile.d/nix.sh

git clone --branch master --single-branch https://github.com/nixos/nixpkgs src
git -C src log --format=%H --no-merges > tmp

mkdir -p data/nixpkgs
jq -erRS [inputs] < tmp > data/nixpkgs/commits.json

bash .github/workflows/push.sh "feat(conf): update nixpkgs commits list" data
