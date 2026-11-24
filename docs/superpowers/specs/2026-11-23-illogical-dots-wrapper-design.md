# Illogical-dots wrapper installer

## Intent

Make `Roosti/dotfiles` installable on a fresh machine while keeping end4's
`dots-hyprland` installer as the source of truth for dependencies, services,
and the base illogical-dots configuration. The personal repository owns the
user's Hyprland custom Lua layer, monitor settings, Kitty configuration, and
related files.

## Goals

- Clone or reuse end4's repository at `dotfiles/dots-hyprland`.
- Run end4's official `./setup install` from that checkout.
- Install this repository's tracked custom `.config` files after upstream
  setup, without replacing end4's base Hyprland files.
- Create timestamped backups before replacing existing user files.
- Be repeatable and safe to run again.
- Support a dry-run and an explicit upstream update path.
- Leave upstream files untouched so upstream fixes can be pulled and PRs can
  be made in the upstream checkout independently.

## Non-goals

- Reimplement end4's package/dependency installation.
- Automatically merge local changes into upstream files.
- Manage secrets, SSH keys, or unrelated home-directory files.
- Restore files that the user has intentionally removed from this repository.

## Approach

Use a Bash wrapper at the repository root. It will resolve its own directory,
verify required commands, clone `https://github.com/end-4/dots-hyprland` when
the nested checkout is absent, optionally fast-forward it when explicitly
requested, run `./setup install`, then copy an explicit personal `.config`
allowlist into `$HOME/.config` with per-file backups. The allowlist includes
`.config/hypr/custom/`, personal Hyprland shaders/lock files, and
`.config/kitty/`; it excludes the tracked legacy `.conf` snapshot and the
upstream-owned base Hyprland directory. Copying is preferred to symlinking so
the installed system remains usable if the repository is moved or unavailable.

The wrapper will default to the current upstream checkout without pulling
changes. `--update-upstream` will perform the explicit update. `--dry-run`
will show planned actions without changing the system.

## Safety and behavior

- Abort on command errors and unsafe paths.
- Refuse to run as root, matching end4's setup expectations.
- Backups go under `~/.local/state/roosti-dotfiles/backups/<timestamp>/`.
- The nested upstream checkout is ignored by the personal repository.
- Existing repository changes are not reset, stashed, or deleted.
- Older `.conf` files are retained under a non-loaded legacy directory while
  active Lua customizations are tracked under `.config/hypr/custom/`.

## Verification

The implementation will pass `bash -n`, a dry-run test in a temporary HOME,
and checks that the upstream setup command is invoked from the nested checkout
while personal config files are applied afterward.
