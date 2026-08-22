# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A macOS developer workstation bootstrapper: a set of Homebrew manifests, a small `zshrc`, and an idempotent installer script. There is no application code, build step, or test suite — changes are almost always edits to `Brewfile*`, `install.sh`, or `zshrc`, validated by running the script itself (with `--dry-run`) rather than by a test runner.

## Commands

```bash
./install.sh --dry-run          # preview any profile's actions with no changes made
./install.sh --core             # CLI essentials only (default)
./install.sh --all --dry-run    # preview the full install across every manifest
shellcheck install.sh           # lint the installer (shellcheck is in Brewfile)
brew bundle check --file Brewfile   # verify a manifest against installed state without installing
```

There is no build, test, or CI pipeline in this repo. Validate changes to `install.sh` by running it with `--dry-run` for each affected profile, and by running `shellcheck` on it. Validate `zshrc` changes with `zsh -n zshrc` (syntax check) or by sourcing it in a new shell.

## Architecture

**Profile system.** `install.sh` always applies the base `Brewfile`, then layers on zero or one additional manifest based on the `--core|--desktop|--data|--ai|--future|--all` flag (see the `manifests+=(...)` case statement in `install.sh`). Each additional manifest is a separate file at the repo root: `Brewfile.desktop`, `Brewfile.data`, `Brewfile.ai`, `Brewfile.future`. When adding a new package, decide which profile it belongs to (core vs. opt-in group) rather than always adding to the base `Brewfile` — the profile split exists specifically to keep the default install light and to keep costly/sensitive tools (AI, local databases, desktop apps) opt-in.

**Installer safety model.** `install.sh` is designed to be safe to re-run and never silently destructive:
- It always prints the resolved manifest list and prompts for confirmation before making changes, unless `--yes`/`-y` is passed (reserved for already-reviewed automation) or `--dry-run` is set.
- `brew bundle` always runs with `--no-upgrade`, so re-running never upgrades existing packages — it only fills in what's missing.
- Shell integration is additive and reversible: it appends a marker-delimited block (`# >>> developer-workstation >>>` / `# <<< developer-workstation <<<`) to `~/.zshrc` that sources this repo's `zshrc`, after first backing up the existing `~/.zshrc` to `~/.config/dev-workstation/backups/zshrc.<timestamp>`. It checks for the source line before appending, so running the installer repeatedly does not duplicate the block.
- `--no-link` skips touching `~/.zshrc` entirely.

Preserve this pattern (preview → confirm → non-destructive apply → reversible shell integration) for any change to the installer's flow.

**`zshrc` design constraint.** The shell config is deliberately minimal and fast — no plugin framework. Machine-specific customization and secrets-provider initialization are meant to live in the untracked `~/.config/dev-workstation/local.zsh`, sourced conditionally near the top of `zshrc`, not added directly to this file. `dev-doctor` (defined at the bottom of `zshrc`) is the diagnostic entry point; its `tools` array should be kept in sync when new CLIs are added to any Brewfile, since it's the primary way users verify an install worked.

**`Start Setup.command`** is a thin, double-clickable menu wrapper that maps numbered choices to `install.sh` flags — keep its option list in sync with `install.sh`'s profile flags.

**Docs split**: `docs/TOOLING.md` holds per-tool daily-usage guidance and practices (referenced from README); `docs/TROUBLESHOOTING.md` holds fixes for common setup problems. Both are prose reference docs, not code — update them when installer behavior or bundled tools change in a way that affects what a user would do day-to-day.

## Guiding constraints to respect when editing

- Never introduce plaintext secrets/API keys into `zshrc`, any `Brewfile*`, or `install.sh`.
- Keep new aliases/functions in `zshrc` non-destructive; don't alias over destructive commands or hide their flags.
- Data services (MySQL, MongoDB, Kafka, OpenSearch) are opt-in via `Brewfile.data` and must never be auto-started by the installer.
- AI tooling (Claude Code, Ollama) is opt-in via `Brewfile.ai`/`--ai` and must stay opt-in.
