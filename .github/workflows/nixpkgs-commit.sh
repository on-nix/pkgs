set -euxo pipefail

curl -L https://nixos.org/nix/install | sh
source ~/.nix-profile/etc/profile.d/nix.sh

mkdir -p data/nixpkgs/commits
jq -er .[] < data/nixpkgs/commits.json | sort > tmp
mapfile -t commits < tmp
count=0
for commit in "${commits[@]}"; do
  target="data/nixpkgs/commits/${commit}.json"

  # Skip this commit if we already processed it
  if test -e "${target}"; then continue; fi
  # Stop after processing 25 commits
  if test "${count}" -gt 25; then break; else count="$((count + 1))"; fi

  # Query available packages in this commit or save an empty set
  src="https://github.com/nixos/nixpkgs/archive/${commit}.tar.gz"
  query='to_entries|map({(.key):.value.version})|add'
  if ! nix-env -qaf "${src}" --json | jq -er "${query}" > "${target}"; then
    echo "{}" > "${target}"
  fi
done

bash .github/workflows/push.sh "feat(conf): add more nixpkgs commits" data
