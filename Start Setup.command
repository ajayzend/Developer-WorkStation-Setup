#!/usr/bin/env bash
set -Eeuo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_dir"

clear
printf '%s\n' '=================================================='
printf '%s\n' '        Developer Workstation Setup'
printf '%s\n' '=================================================='
printf '%s\n' 'Nothing is installed until you review the list and confirm.'
printf '\n%s\n' 'Choose a profile:'
printf '%s\n' '  1) Core       CLI, PHP, Node, Python, AWS, Terraform'
printf '%s\n' '  2) Desktop    Core + Docker Desktop, Postman, VS Code'
printf '%s\n' '  3) Data       Core + MySQL, MongoDB, Kafka, OpenSearch'
printf '%s\n' '  4) AI         Core + Claude Code and local Ollama'
printf '%s\n' '  5) Future     Core + Go, Rust, Kubernetes, Helm, gRPC'
printf '%s\n' '  6) Everything All profiles'
printf '%s\n' '  7) Preview    Show everything without changing the system'
printf '%s\n' '  q) Quit'
printf '\nSelection: '
read -r selection

case "$selection" in
  1) arguments=(--core) ;;
  2) arguments=(--desktop) ;;
  3) arguments=(--data) ;;
  4) arguments=(--ai) ;;
  5) arguments=(--future) ;;
  6) arguments=(--all) ;;
  7) arguments=(--all --dry-run) ;;
  q|Q) printf 'No changes made.\n'; exit 0 ;;
  *) printf 'Invalid selection. No changes made.\n' >&2; exit 2 ;;
esac

./install.sh "${arguments[@]}"
printf '\nPress Enter to close this window...'
read -r _

