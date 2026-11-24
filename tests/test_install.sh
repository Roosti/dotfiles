#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_root=$(mktemp -d)
trap 'rm -rf "$tmp_root"' EXIT

upstream="$tmp_root/upstream"
target_home="$tmp_root/home"
mkdir -p "$upstream" "$target_home"
cat > "$upstream/setup" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'upstream ran\n' > "$DOTFILES_HOME/upstream-ran"
EOF
chmod +x "$upstream/setup"
git -C "$upstream" init -q
git -C "$upstream" config user.email test@example.invalid
git -C "$upstream" config user.name test
git -C "$upstream" remote add origin https://github.com/end-4/dots-hyprland.git
git -C "$upstream" add setup
git -C "$upstream" commit -qm 'test upstream'

mkdir -p "$target_home/.config/hypr/custom"
printf 'existing user file\n' > "$target_home/.config/hypr/custom/general.lua"
DOTFILES_HOME="$target_home" \
DOTFILES_UPSTREAM_DIR="$upstream" \
  "$repo_root/install.sh" --dry-run --skip-upstream >/dev/null
test ! -d "$target_home/.local/state/roosti-dotfiles/backups"

dry_run_output=$(
  DOTFILES_HOME="$target_home" \
  DOTFILES_UPSTREAM_DIR="$upstream" \
  "$repo_root/install.sh" --dry-run --skip-upstream
)
grep -Fq 'custom/general.lua' <<<"$dry_run_output"
test ! -e "$target_home/upstream-ran"

DOTFILES_HOME="$target_home" \
DOTFILES_UPSTREAM_DIR="$upstream" \
  "$repo_root/install.sh" --skip-upstream

test -f "$target_home/.config/hypr/custom/general.lua"
grep -Fq 'DP-1' "$target_home/.config/hypr/custom/general.lua"

DOTFILES_HOME="$target_home" \
DOTFILES_UPSTREAM_DIR="$upstream" \
  "$repo_root/install.sh"
test -f "$target_home/upstream-ran"

DOTFILES_HOME="$target_home" \
DOTFILES_UPSTREAM_DIR="$upstream" \
  "$repo_root/install.sh" --skip-upstream
find "$target_home/.local/state/roosti-dotfiles/backups" \
  -type f -path '*/.config/hypr/custom/general.lua' -print -quit | grep -q .

rm -rf "$target_home/.config/hypr/hypridle.conf"
mkdir -p "$target_home/.config/hypr/hypridle.conf"
DOTFILES_HOME="$target_home" \
DOTFILES_UPSTREAM_DIR="$upstream" \
  "$repo_root/install.sh" --skip-upstream >/dev/null
test -f "$target_home/.config/hypr/hypridle.conf"

printf 'installer tests passed\n'
