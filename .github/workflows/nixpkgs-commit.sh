set -euxo pipefail

curl -L https://nixos.org/nix/install | sh
source ~/.nix-profile/etc/profile.d/nix.sh

mkdir -p data/nixpkgs/commits
jq -er .[] < data/nixpkgs/commits.json | sort > tmp
mapfile -t commits < tmp
count=0
for commit in "${commits[@]}"; do
  target="data/nixpkgs/commits/${commit}.json"

  if ! test -e "${target}"; then
    src="https://github.com/nixos/nixpkgs/archive/${commit}.tar.gz"
    if nix-env -qaf "${src}" --json > tmp; then
      jq -er 'to_entries|map({(.key):.value.version})|add' < tmp > "${target}"
    else
      echo "{}" > "${target}"
    fi

    if test "${count}" = 25; then
      break
    else
      count="$((count + 1))"
    fi
  fi
done

bash .github/workflows/push.sh "feat(conf): add more nixpkgs commits" data
