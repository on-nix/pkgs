set -euxo pipefail

curl -L https://nixos.org/nix/install | sh
source ~/.nix-profile/etc/profile.d/nix.sh

mkdir -p data/nixpkgs/commits
jq -er .[] < data/nixpkgs/commits.json | sort > tmp
mapfile -t commits < tmp
for commit in "${commits[@]}"; do
  target="data/nixpkgs/commits/${commit}.json"

  if ! test -e "${target}"; then
    src="https://github.com/nixos/nixpkgs/archive/${commit}.tar.gz"
    nix-env -qaf "${src}" --json > tmp
    jq -er 'to_entries|map({(.key):.value.version})|add' < tmp > "${target}"
    break
  fi
done
