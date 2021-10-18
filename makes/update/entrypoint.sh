# shellcheck shell=bash

function clone_nixpkgs {
  local url='https://github.com/NixOS/nixpkgs.git'

  if test -e nixpkgs; then
    git -C nixpkgs fetch origin refs/heads/master
  else
    git clone --branch master --single-branch "${url}" nixpkgs
  fi
}

function main {
  local attr="${1}"

  temp_file="$(mktemp)" \
    && info Cloning \
    && clone_nixpkgs \
    && info Computing commits \
    && git -C nixpkgs log --format=%H master --reverse > "${temp_file}" \
    && mapfile -t commits < "${temp_file}" \
    && mkdir -p "data/${attr}" \
    && if test -e "data/${attr}/last"; then
      last="$(cat "data/${attr}/last")"
    else
      last=f95b22c621323cab1e998fded8f749de9aaa271a
    fi \
    && count=0 \
    && for commit in "${commits[@]}"; do
      : \
        && if test -n "${last}"; then
          info Skipping "${commit}" \
            && if test "${last}" == "${commit}"; then last=""; fi \
            && continue
        fi \
        && if test "${count}" -ge 1; then break; else count=$((count + 1)); fi \
        && info Checking out "${commit}" \
        && git -C nixpkgs reset --hard "${commit}" \
        && git -C nixpkgs clean -dffx \
        && info Building "${attr}" \
        && if nix-build \
          --option sandbox true \
          --argstr attr "${attr}" \
          --argstr commit "${commit}" \
          ./makes/update/lib.nix; then
          version="$(ls -1 result)" \
            && cat < "result/${version}" > "data/${attr}/${version}.json"
        fi \
        && echo "${commit}" > "data/${attr}/last"
    done
}

main "${@}"
