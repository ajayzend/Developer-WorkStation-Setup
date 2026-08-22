#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
profile="core"
link_shell=true
dry_run=false
assume_yes=false

usage() {
  cat <<'USAGE'
Usage: ./install.sh [PROFILE] [--no-link] [--dry-run] [--yes]

  --core      Install CLI essentials (default)
  --desktop   Install core and desktop applications
  --data      Install core and local data services
  --ai        Install core and AI tools (Claude Code and Ollama)
  --future    Install core and optional cloud-native/polyglot tools
  --all       Install all groups
  --no-link   Do not add the managed source block to ~/.zshrc
  --dry-run   Print actions without making changes
  --yes       Skip confirmation (intended for automation)

Already-installed software is detected by Homebrew and skipped. Existing
packages are not upgraded by this installer.
USAGE
}

profile_flags=()
for argument in "$@"; do
  case "$argument" in
    --core) profile="core"; profile_flags+=("$argument") ;;
    --desktop) profile="desktop"; profile_flags+=("$argument") ;;
    --data) profile="data"; profile_flags+=("$argument") ;;
    --ai) profile="ai"; profile_flags+=("$argument") ;;
    --future) profile="future"; profile_flags+=("$argument") ;;
    --all) profile="all"; profile_flags+=("$argument") ;;
    --no-link) link_shell=false ;;
    --dry-run) dry_run=true ;;
    -y|--yes) assume_yes=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$argument" >&2; usage >&2; exit 2 ;;
  esac
done

if (( ${#profile_flags[@]} > 1 )); then
  printf 'Only one profile flag may be given at a time, got: %s\n' "${profile_flags[*]}" >&2
  usage >&2
  exit 2
fi

run() {
  printf '+ '
  printf '%q ' "$@"
  printf '\n'
  "$dry_run" || "$@"
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This bootstrap currently supports macOS only.\n' >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  printf '%s\n' 'Homebrew is required. Install it from https://brew.sh, then rerun this script.' >&2
  exit 1
fi

manifests=("$REPO_DIR/Brewfile")

case "$profile" in
  desktop) manifests+=("$REPO_DIR/Brewfile.desktop") ;;
  data) manifests+=("$REPO_DIR/Brewfile.data") ;;
  ai) manifests+=("$REPO_DIR/Brewfile.ai") ;;
  future) manifests+=("$REPO_DIR/Brewfile.future") ;;
  all)
    manifests+=(
      "$REPO_DIR/Brewfile.desktop"
      "$REPO_DIR/Brewfile.data"
      "$REPO_DIR/Brewfile.ai"
      "$REPO_DIR/Brewfile.future"
    )
    ;;
esac

if [[ "$profile" == "ai" || "$profile" == "all" ]] && ! command -v npm >/dev/null 2>&1; then
  printf '\nWarning: the ai profile installs Claude Code via npm, but npm is not on PATH yet.\n' >&2
  printf 'fnm is installed by the core profile but does not install a Node.js version by itself.\n' >&2
  printf 'Install one first, then re-run this installer:\n\n' >&2
  printf '  fnm install --lts && fnm default lts-latest && exec zsh\n\n' >&2
  if ! "$dry_run"; then
    exit 4
  fi
  printf 'Continuing preview since --dry-run was given.\n' >&2
fi

printf '\nDeveloper Workstation Setup\n'
printf 'Profile: %s\n\n' "$profile"
printf 'The following manifests will be applied:\n'
for manifest in "${manifests[@]}"; do
  printf '\n  %s\n' "$(basename "$manifest")"
  sed -nE 's/^(brew|cask|npm|tap) "([^"]+)".*/    - \1: \2/p' "$manifest"
done

printf '\nSafety behavior:\n'
printf '  - Already-installed packages will be skipped.\n'
printf '  - Installed packages will not be upgraded.\n'
printf '  - No database or background service will be started.\n'
if "$link_shell"; then
  printf '  - ~/.zshrc will be backed up before adding the managed source block.\n'
else
  printf '  - ~/.zshrc will not be changed.\n'
fi

if ! "$dry_run" && ! "$assume_yes"; then
  if [[ ! -t 0 ]]; then
    printf '\nConfirmation is required in an interactive terminal. Use --yes only after review.\n' >&2
    exit 3
  fi
  printf '\nContinue with installation? [y/N] '
  read -r reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *) printf 'Installation cancelled. No changes were made.\n'; exit 0 ;;
  esac
fi

for manifest in "${manifests[@]}"; do
  run brew bundle --no-upgrade --file "$manifest"
done

if "$link_shell"; then
  target="$HOME/.zshrc"
  config_dir="$HOME/.config/dev-workstation"
  begin_marker='# >>> developer-workstation >>>'
  end_marker='# <<< developer-workstation <<<'
  source_line="source \"$REPO_DIR/zshrc\""

  if "$dry_run"; then
    printf '+ update %s to source %s\n' "$target" "$REPO_DIR/zshrc"
  else
    mkdir -p "$config_dir/backups"
    touch "$target"

    if ! grep -Fq "$source_line" "$target"; then
      backup="$config_dir/backups/zshrc.$(date +%Y%m%d-%H%M%S)"
      cp "$target" "$backup"
      {
        printf '\n%s\n' "$begin_marker"
        printf '%s\n' "$source_line"
        printf '%s\n' "$end_marker"
      } >> "$target"
      printf 'Backed up existing shell config to %s\n' "$backup"
    else
      printf '%s already sources the workstation config.\n' "$target"
    fi
  fi
fi

if "$dry_run"; then
  printf '\nPreview complete. No changes were made.\n'
else
  printf '\nSetup complete. Open a new terminal or run: exec zsh\n'
  printf 'Then verify with: dev-doctor\n'
fi
