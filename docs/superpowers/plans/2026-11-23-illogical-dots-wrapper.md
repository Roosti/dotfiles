# Illogical-dots Wrapper Installer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Install end4's latest illogical-dots through its official setup, then apply Roosti's active Hyprland Lua customizations and Kitty-related files without overwriting upstream base configuration.

**Architecture:** A root Bash wrapper owns upstream checkout/update orchestration and an explicit personal-file allowlist. The personal repository stores active Hyprland Lua overrides under `.config/hypr/custom/`; the old `.conf` snapshot is retained only as non-installed legacy material.

**Tech Stack:** Bash, Git, rsync or shell file copying, end4's existing `./setup install`.

**Spec:** `docs/superpowers/specs/2026-11-23-illogical-dots-wrapper-design.md`

## Global Constraints

- Use end4's official `dotfiles/dots-hyprland/setup install` as the dependency and base-config installer.
- Do not replace end4's upstream-owned base Hyprland files.
- Back up replaced user files under `~/.local/state/roosti-dotfiles/backups/<timestamp>/`.
- Preserve existing repository changes; do not reset, stash, or delete them.
- Do not install the older `.conf` snapshot as active Hyprland configuration.

## Review Focus

- Existing user config file: backup before replacement; test in a temporary HOME.
- Missing upstream checkout: clone it; test with a stub Git/setup environment.
- Existing upstream checkout with local changes: do not reset or discard them; test update refusal/message.
- Intentional repository deletion of `.config/kitty/kitty.conf`: do not restore it automatically; test against the index/worktree state.
- Upstream base/custom filename overlap: custom layer must be applied after upstream setup and only from the explicit allowlist.

### Task 1: Migrate active Hyprland customization into the custom layer

**Files:**
- Create/modify: `.config/hypr/custom/*.lua`
- Move: `.config/hypr/hyprland/scripts/*` to `.config/hypr/custom/scripts/`
- Move: old `.config/hypr/hyprland/*.conf` snapshot to `.config/hypr/custom/legacy-conf/`
- Modify: `.gitignore` if needed for the nested upstream checkout

**Interfaces:**
- Consumes: current active files under `/home/roosti/.config/hypr/custom/` and `/home/roosti/.config/hypr/hyprland/general.lua`.
- Produces: a tracked `.config/hypr/custom/` tree that the wrapper can copy after upstream setup.

- [ ] Copy the current active Lua custom files into the repository, including the customized `general.lua` with `DP-1` at `2560x1440@480`.
- [ ] Move personal Hyprland scripts from the old tracked base directory into the custom scripts directory.
- [ ] Move the old `.conf` snapshot into a clearly named non-loaded legacy directory rather than deleting it.
- [ ] Confirm no active custom Lua file references a repository-only absolute path.
- [ ] Run a file inventory and `git diff --stat` review.

### Task 2: Implement the wrapper installer

**Files:**
- Create: `install.sh`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: upstream URL, nested checkout path, and explicit personal-file allowlist.
- Produces: `./install.sh [--dry-run] [--update-upstream]`.

- [ ] Add argument parsing and root/path validation; refuse root execution.
- [ ] Add clone/reuse logic for `dotfiles/dots-hyprland`; only pull when `--update-upstream` is supplied.
- [ ] Run upstream `./setup install` from its checkout.
- [ ] Back up existing personal target files, then apply `.config/hypr/custom`, Kitty, lock, shader, and other explicitly personal assets.
- [ ] Ensure the script never copies `.config/hypr/hyprland/` or the legacy directory.
- [ ] Add dry-run output for every planned operation.

### Task 3: Verify the installer

**Files:**
- Test: shell syntax and temporary-HOME harness commands

- [ ] Run `bash -n install.sh`.
- [ ] Run a dry-run with a temporary HOME and confirm no writes occur.
- [ ] Run a mocked install with fake upstream setup and confirm upstream setup runs before personal files are applied.
- [ ] Confirm backup creation when a target already exists.
- [ ] Review `git diff`, preserving the pre-existing Kitty deletion.
