# Troubleshooting

## A command is installed but not found

Open a new terminal, run `exec zsh`, and then `dev-doctor`. Verify Homebrew with `brew --prefix`. Apple Silicon normally uses `/opt/homebrew`; Intel Macs normally use `/usr/local`.

## Shell startup is slow

Measure it with `time zsh -i -c exit`. Keep network calls and package updates out of `.zshrc`. The provided completion cache and small configuration should start quickly.

## Docker reports that the daemon is unavailable

Start Docker Desktop and wait for it to report that the engine is running. Check `docker context show` and `docker info`.

## Port already in use

```bash
lsof -nP -iTCP:3306 -sTCP:LISTEN
lsof -nP -iTCP:6379 -sTCP:LISTEN
docker ps --format 'table {{.Names}}\t{{.Ports}}'
```

Stop only the service you recognize. Do not kill an unknown process without checking its owner and purpose.

## "Refusing to load formula/cask from untrusted tap"

Homebrew 6.x refuses to load formulae or casks from any non-core tap until you explicitly trust it. This repository uses `hashicorp/tap` (for `terraform`) and `terraform-linters/tap` (for `tflint`). Trust each one, then re-run `./install.sh`:

```bash
brew trust --tap hashicorp/tap
brew trust --tap terraform-linters/tap
```

## A single package download fails and blocks the whole install

`brew bundle` aborts the entire batch if even one package fails to fetch — packages before and after it in the manifest are never installed, even though nothing is wrong with them. If the error is a connection timeout or reset (not a 404), check whether your network/proxy blocks the specific CDN host in the URL (for example `release-assets.githubusercontent.com`, GitHub's newer release-asset domain, is not yet allow-listed on some corporate networks even when `github.com` itself works fine). Confirm with `curl -v <url>`, then either get the host allow-listed or install everything else directly with `brew install <packages...>`, omitting the blocked one, and add it later once network access is fixed.

## Homebrew package conflicts

Run `brew doctor`, `brew update`, and `brew bundle check --file Brewfile`. Avoid mixing Intel and Apple Silicon Homebrew installations in one shell.

## AWS authentication fails

```bash
aws configure list --profile company-dev
aws sso login --profile company-dev
AWS_PROFILE=company-dev aws sts get-caller-identity
```

Confirm the profile, region, system clock, VPN/network access, and role permissions. Do not solve authentication failures by creating unrestricted long-lived keys.

## Resetting this shell integration

Remove only the block between `developer-workstation` markers in `~/.zshrc`. Backups are stored under `~/.config/dev-workstation/backups/`. The repository's installer never removes packages or data.

