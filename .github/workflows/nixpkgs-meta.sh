set -euxo pipefail

curl -L https://nixos.org/nix/install | sh
source ~/.nix-profile/etc/profile.d/nix.sh

mkdir -p data/nixpkgs/commits
query='to_entries|map({
  (.key): {
    desc: .value.meta.description,
    desc_long: .value.meta.longDescription,
    home: .value.meta.homepage,
    license: .value.meta.license,
    maintainers: .value.meta.maintainers,
  }
})|add'
src="https://github.com/nixos/nixpkgs/archive/master.tar.gz"
target="data/nixpkgs/meta.json"
nix-env -qaf "${src}" --json | jq -er "${query}" > "${target}"

bash .github/workflows/push.sh "feat(conf): update nixpkgs metadata" data
