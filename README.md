# macOS Developer Workstation Setup

A reusable, team-friendly setup for backend, API, cloud, and data-platform development on Apple Silicon or Intel macOS.

It covers PHP, Node.js, MySQL, Docker, MongoDB, Git/GitHub, Terraform, AWS CLI, Postman, REST APIs, JSON/YAML, Kafka/MSK, Redis, OpenSearch, and Visual Studio Code.

## What this repository provides

- `Brewfile` — reproducible Homebrew packages and desktop applications.
- `zshrc` — fast, readable shell configuration with safe defaults and useful aliases/functions.
- `install.sh` — an idempotent bootstrap script that installs packages and links the shell config.
- `Start Setup.command` — friendly, double-clickable setup menu for macOS.
- `docs/TOOLING.md` — practical usage and best practices for every tool.
- `docs/TROUBLESHOOTING.md` — common macOS setup fixes.

## Quick start

Nothing is installed until the installer shows its plan and you confirm. Already-installed tools are skipped and existing packages are not upgraded.

For the easiest setup, double-click `Start Setup.command` in Finder. Choose a profile, review the package list, and confirm. If macOS blocks its first launch, right-click it, choose **Open**, and approve it.

For terminal setup:

```bash
git clone <this-repository-url> developer-workstation
cd developer-workstation
./install.sh
```

Choose an installation profile:

```bash
./install.sh --core       # CLI essentials only (default)
./install.sh --desktop    # core + VS Code, Docker Desktop, Postman
./install.sh --data       # core + MySQL, MongoDB, Kafka, Redis, OpenSearch
./install.sh --ai         # core + Claude Code and Ollama
./install.sh --future     # core + Go, Rust, Kubernetes, Helm, gRPC
./install.sh --all        # everything
./install.sh --dry-run    # print actions without changing the machine
```

Then open a new terminal or run:

```bash
exec zsh
dev-doctor
```

### Existing `.zshrc` files

The installer never silently destroys an existing setup. It creates a timestamped backup in `~/.config/dev-workstation/backups/`, then writes a small managed block that sources this repository's `zshrc`. Running the installer again is safe.

To install without changing your shell configuration:

```bash
./install.sh --all --no-link
```

## Recommended daily stack

| Need | Recommended tool | Why |
|---|---|---|
| Package installation | Homebrew + `Brewfile` | Repeatable machine setup |
| Node.js versions | `fnm` | Fast, per-project Node versions |
| Python | Python + `uv` | Fast environments, dependencies, and locked projects |
| PHP versions | Homebrew PHP; `phpenv` only for multi-version teams | Simple default; add complexity only when needed |
| Containers | Docker Desktop + Compose | Consistent local dependencies |
| Git hosting | Git + GitHub CLI (`gh`) | PR, issue, and auth workflows in terminal |
| Cloud | AWS CLI v2 + `aws-vault` | Short-lived credentials; no plaintext secrets |
| Infrastructure | Terraform + `tflint` | Reproducible infrastructure and linting |
| HTTP/API | `curl`, `httpie`, Postman | Scripts, readable manual calls, shared collections |
| JSON/YAML | `jq`, `yq` | Reliable structured-data queries |
| Databases | Native CLI clients; Docker for local servers | Keep host clean and versions pinned |
| Kafka/MSK | `kcat` + AWS CLI | Lightweight inspection and AWS authentication workflows |
| Search | OpenSearch in Docker | Avoid a heavy always-on host service |
| Editor | VS Code + `code` CLI | Shared extensions and workspace settings |
| AI coding | Claude Code (opt-in) | Repository-aware coding assistant |
| Local AI | Ollama (opt-in) | Run supported models locally |
| Cloud native | Kubernetes CLI, Helm, k9s | Optional future platform workflow |

## Guiding practices

1. Pin project runtime versions (`.node-version`, `.php-version`, Terraform constraints, container image tags).
2. Run databases, Kafka, Redis, and OpenSearch in project-specific Compose files instead of globally when possible. The `--data` profile's native MySQL/MongoDB/Kafka/OpenSearch packages exist for occasions when a Docker-free local server is genuinely preferable (e.g. constrained disk/CPU, or a quick one-off client/server pairing); reach for Docker Compose first.
3. Never put API keys, AWS keys, tokens, or passwords in `.zshrc`, Git, shell history, or Dockerfiles.
4. Use AWS SSO or `aws-vault`; use `.env.example` for variable names and an ignored `.env` for local values.
5. Commit lockfiles and run formatters, linters, tests, and security checks in CI.
6. Prefer aliases only for harmless shortcuts. Do not alias destructive commands or hide important flags.

See [docs/TOOLING.md](docs/TOOLING.md) for daily commands, Python, and responsible AI guidance.

## Installation safety

- Interactive installation always asks for confirmation after displaying the selected tools.
- Homebrew skips software that is already installed and satisfies the manifest.
- `--no-upgrade` prevents surprise upgrades to installed software.
- Data services are opt-in and are never automatically started.
- Claude Code and Ollama are opt-in through `--ai` or `--all`.
- The existing `.zshrc` is backed up before integration.
- `--yes` is available only for already-reviewed automation.

## Updating and removing

Update installed formulae from the manifest:

```bash
brew update
brew bundle --file ./Brewfile
brew upgrade
```

The installer adds a clearly marked block to `~/.zshrc`. To remove this setup, delete that block. Packages are intentionally not auto-uninstalled because other projects may use them.
