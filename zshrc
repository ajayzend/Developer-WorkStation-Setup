# Developer workstation shell configuration.
# This file is sourced by ~/.zshrc; keep credentials in a secret manager, never here.

# Homebrew on Apple Silicon and Intel Macs.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# XDG locations keep tool state organized.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
if [[ -z "${EDITOR:-}" ]]; then
  if command -v code >/dev/null 2>&1; then
    export EDITOR="code --wait"
  else
    export EDITOR="vi"
  fi
fi
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-FRX"
export HOMEBREW_NO_ANALYTICS=1

# User scripts, Composer binaries, and MySQL client.
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.composer/vendor/bin"
  "/opt/homebrew/opt/mysql-client/bin"
  "/usr/local/opt/mysql-client/bin"
  $path
)
export PATH

# History: large, deduplicated, shared, and free of accidental leading-space secrets.
HISTFILE="$XDG_DATA_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
mkdir -p "${HISTFILE:h}"
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE INTERACTIVE_COMMENTS AUTO_CD

# Completion.
autoload -Uz compinit
mkdir -p "$XDG_CACHE_HOME/zsh"
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Version-managed Node.js. A project can pin Node in .node-version.
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# Optional local, untracked customization and secrets-provider initialization.
[[ -r "$XDG_CONFIG_HOME/dev-workstation/local.zsh" ]] && source "$XDG_CONFIG_HOME/dev-workstation/local.zsh"

# Modern interactive tools; scripts continue to use standard POSIX commands.
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

alias ll='eza -lah --group-directories-first --git'
alias la='eza -a --group-directories-first'
alias lt='eza --tree --level=2'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias g='git'
alias gs='git status --short --branch'
alias gl='git log --oneline --decorate --graph -20'
alias gd='git diff'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias tf='terraform'
alias awswho='aws sts get-caller-identity'
alias json='jq .'
alias py='python3'
alias venv='uv venv'

# Create a directory and enter it.
mkcd() {
  [[ $# -eq 1 ]] || { print -u2 'usage: mkcd <directory>'; return 2; }
  mkdir -p -- "$1" && cd -- "$1"
}

# Pretty-print JSON from a file, stdin, or URL.
jget() {
  if [[ $# -eq 0 ]]; then
    jq .
  elif [[ "$1" == http://* || "$1" == https://* ]]; then
    curl --fail-with-body --silent --show-error --location "$1" | jq .
  else
    jq . -- "$1"
  fi
}

# Show versions/availability without leaking credentials.
dev-doctor() {
  local tools=(
    git gh git-lfs delta gpg
    rg fd fzf bat eza zoxide starship shellcheck sops mkcert nmap
    node npm php composer python3 uv pipx ruff
    docker aws aws-vault terraform tflint trivy
    jq yq curl http kcat redis-cli mysql mongosh
    code tmux claude ollama
    go cargo protoc grpcurl kubectl helm k9s act direnv age sqlite3
  )
  local tool
  printf '%-14s %s\n' 'TOOL' 'LOCATION'
  printf '%-14s %s\n' '----' '--------'
  for tool in $tools; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '%-14s %s\n' "$tool" "$(command -v "$tool")"
    else
      printf '%-14s %s\n' "$tool" 'not installed'
    fi
  done
}
