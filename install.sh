#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
UPSTREAM_URL=${DOTFILES_UPSTREAM_URL:-https://github.com/end-4/dots-hyprland.git}
UPSTREAM_DIR=${DOTFILES_UPSTREAM_DIR:-$ROOT_DIR/dotfiles/dots-hyprland}
TARGET_HOME=${DOTFILES_HOME:-$HOME}
DRY_RUN=false
UPDATE_UPSTREAM=false
SKIP_UPSTREAM=false
BACKUP_DIR=

usage() {
    cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Install end4's illogical-dots, then apply this repository's personal layer.

Options:
  --dry-run           Show actions without changing the system.
  --update-upstream   Fast-forward the existing end4 checkout before install.
  --skip-upstream     Skip clone/update/setup and apply personal files only.
  -h, --help          Show this help.
EOF
}

log() {
    printf '[dotfiles] %s\n' "$*"
}

die() {
    printf '[dotfiles] error: %s\n' "$*" >&2
    exit 1
}

while (($#)); do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        --update-upstream) UPDATE_UPSTREAM=true ;;
        --skip-upstream) SKIP_UPSTREAM=true ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
    shift
done

((EUID != 0)) || die "do not run as root; end4's setup expects a user session"
command -v git >/dev/null 2>&1 || die 'git is required'
[[ -d "$ROOT_DIR/.config" ]] || die "missing repository config directory: $ROOT_DIR/.config"
[[ "$TARGET_HOME" = /* && "$TARGET_HOME" != / ]] || die "DOTFILES_HOME must be an absolute non-root path: $TARGET_HOME"

if [[ "$SKIP_UPSTREAM" == false ]]; then
    [[ "$UPSTREAM_DIR" = /* && "$UPSTREAM_DIR" != / ]] || die "DOTFILES_UPSTREAM_DIR must be an absolute non-root path: $UPSTREAM_DIR"
fi

if [[ "$SKIP_UPSTREAM" == false ]]; then
    if [[ -e "$UPSTREAM_DIR" && ! -d "$UPSTREAM_DIR/.git" ]]; then
        die "upstream path exists but is not a Git checkout: $UPSTREAM_DIR"
    fi

    if [[ ! -e "$UPSTREAM_DIR" ]]; then
        log "clone $UPSTREAM_URL -> $UPSTREAM_DIR"
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$(dirname "$UPSTREAM_DIR")"
            git clone "$UPSTREAM_URL" "$UPSTREAM_DIR"
        fi
    elif [[ "$UPDATE_UPSTREAM" == true ]]; then
        log "fast-forward upstream checkout: $UPSTREAM_DIR"
        if [[ "$DRY_RUN" == false ]]; then
            git -C "$UPSTREAM_DIR" pull --ff-only
        fi
    fi

    upstream_origin=$(git -C "$UPSTREAM_DIR" remote get-url origin 2>/dev/null || true)
    case "$upstream_origin" in
        *end-4/dots-hyprland*|*end4/dots-hyprland*) ;;
        *) die "upstream checkout origin is not end4/dots-hyprland: ${upstream_origin:-<missing>}" ;;
    esac

    [[ "$DRY_RUN" == true || -x "$UPSTREAM_DIR/setup" ]] || die "missing executable upstream setup: $UPSTREAM_DIR/setup"
    log 'run end4 setup install'
    if [[ "$DRY_RUN" == false ]]; then
        (cd "$UPSTREAM_DIR" && ./setup install)
    fi
fi

backup_existing() {
    local source=$1
    local destination=$2
    local relative=$3

    if [[ -e "$destination" || -L "$destination" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log "would back up $relative"
        else
            if [[ -z "$BACKUP_DIR" ]]; then
                BACKUP_DIR="$TARGET_HOME/.local/state/roosti-dotfiles/backups/$(date +%Y%m%d-%H%M%S)-$$"
                mkdir -p "$BACKUP_DIR"
                log "backup existing files -> $BACKUP_DIR"
            fi
            mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
            cp -a -- "$destination" "$BACKUP_DIR/$relative"
            local source_is_dir=false
            local destination_is_dir=false
            [[ -d "$source" ]] && source_is_dir=true
            [[ -d "$destination" ]] && destination_is_dir=true
            if [[ "$source_is_dir" != "$destination_is_dir" ]]; then
                rm -rf -- "$destination"
            fi
        fi
    fi

    log "install $relative"
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$(dirname "$destination")"
        cp -a -- "$source" "$destination"
    fi
}

install_path() {
    local relative=$1
    local source="$ROOT_DIR/$relative"

    [[ -e "$source" || -L "$source" ]] || {
        log "skip missing personal path: $relative"
        return
    }

    if [[ -f "$source" || -L "$source" ]]; then
        backup_existing "$source" "$TARGET_HOME/$relative" "$relative"
        return
    fi

    while IFS= read -r -d '' file; do
        local file_relative=${file#"$ROOT_DIR/"}
        backup_existing "$file" "$TARGET_HOME/$file_relative" "$file_relative"
    done < <(find "$source" \( -type f -o -type l \) -print0)
}

# Explicitly personal paths. Upstream-owned .config/hypr/hyprland is excluded.
personal_paths=(
    .config/hypr/custom
    .config/hypr/hypridle.conf
    .config/hypr/hyprlock.conf
    .config/hypr/hyprlock
    .config/hypr/shaders
    .config/kitty
)

for path in "${personal_paths[@]}"; do
    install_path "$path"
done

log 'installation complete'
