set -euxo pipefail

git config user.name 'Kevin Amado'
git config user.email kamadorueda@gmail.com
git pull --autostash --progress --rebase --stat origin main
git add "${@:2}"
git commit -m "${1}" --allow-empty
git push
