# Tooling Guide and Daily Practices

## Shell and package management

Use Homebrew for machine-level tools and a checked-in `Brewfile` for reproducibility. Use language package managers only inside projects. Run `brew bundle check --file Brewfile` to audit a machine and `brew bundle` to converge it.

The supplied shell configuration intentionally stays small. Large plugin frameworks can slow startup and make failures hard to debug. Put machine-only customizations in `~/.config/dev-workstation/local.zsh`; do not commit that file.

Useful shell commands:

```bash
rg 'pattern' src/             # fast text search
fd '\.json$' .               # find files
fzf                          # interactive fuzzy selection
jq '.items[] | .name' a.json # query JSON
yq '.services | keys' a.yml  # query YAML
jget response.json           # pretty JSON helper
jget https://api.example.com/health
```

## Command-line productivity tools

These replace or complement everyday POSIX commands. Scripts should keep using the standard commands (`ls`, `find`, `cat`, `grep`) for portability; use the modern tools interactively.

```bash
bat README.md                        # cat with syntax highlighting and line numbers
eza --tree --level=2                 # ls replacement; ll/la/lt aliases already wrap it
fd '\.log$' .                        # fast, friendlier find
fzf                                  # fuzzy-pick from stdin, e.g. vim $(fzf)
history | fzf                        # fuzzy search shell history
z projectname                        # zoxide: jump to a frecently-used directory
zi                                   # zoxide: interactive pick among matches
tmux new -s work                     # persistent, multi-pane terminal session
tmux attach -t work
```

Enable `git-delta` as git's diff/show pager once per machine:

```bash
git config --global core.pager delta
```

Security and diagnostics tools:

```bash
mkcert -install                      # trust a local CA, once per machine
mkcert localhost 127.0.0.1           # issue a locally-trusted TLS cert
gpg --full-generate-key              # for commit signing or secret encryption
git config --global commit.gpgsign true
sops --encrypt --in-place secrets.yaml
sops secrets.yaml                    # decrypt and open in $EDITOR
shellcheck install.sh                # lint a shell script
nmap -sV localhost                   # scan only hosts you're authorized to test
trivy image myapp:latest             # scan a container image for vulnerabilities
trivy fs .                           # scan a filesystem/project for vulnerabilities
```

`aws-vault` stores AWS credentials in the macOS keychain and injects short-lived session credentials instead of writing plaintext keys:

```bash
aws-vault add company-dev
aws-vault exec company-dev -- aws sts get-caller-identity
```

## Git and GitHub

Set identity once, use SSH or GitHub's credential flow, and protect the main branch on the server.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@company.com"
git config --global init.defaultBranch main
git config --global pull.ff only
git config --global fetch.prune true
gh auth login
gh auth status
git lfs install
```

Keep commits focused, use pull requests, and never commit generated secrets, `.env`, cloud credentials, database dumps, or personal editor state. Add `.env.example` with placeholder values.

## Node.js

`fnm` installs and selects Node versions without tying projects to the Homebrew Node release.

```bash
fnm install --lts
fnm default lts-latest
node --version
corepack enable                 # enables project-pinned pnpm/Yarn
echo "$(node --version)" > .node-version
npm ci                          # CI/reproducible install for npm projects
npm audit
```

Commit the lockfile. Do not install project CLIs globally; run them through package scripts or `npx`/`pnpm exec`. Set `engines` and `packageManager` in `package.json`.

## PHP and Composer

Homebrew PHP is suitable when a single current PHP version is enough. Teams supporting several versions should standardize on Docker or adopt one agreed PHP version manager.

```bash
php --version
composer diagnose
composer install
composer audit
./vendor/bin/phpunit
```

Commit `composer.lock` for applications. Use PSR-12 formatting, static analysis (PHPStan/Psalm), and PHPUnit. Never run Composer as root. Pin PHP and extension requirements in `composer.json`.

## Python with uv

Use `uv` for new Python projects. It manages Python versions, isolated environments, dependencies, and lockfiles without modifying macOS system Python.

```bash
uv python install 3.13
uv init my-project
cd my-project
uv add requests
uv add --dev pytest ruff
uv run pytest
uv run ruff check .
uv sync --frozen              # reproducible CI install
```

Commit `pyproject.toml` and `uv.lock`. Never use `sudo pip`, and do not install application dependencies globally. Use type hints, Ruff, tests, and a supported Python version. Use `pipx` or `uv tool` for isolated Python command-line applications.

## Claude Code and AI development

AI tools are opt-in because they may send prompts, code, and context to external services and may create API or subscription costs. Review your organization's data policy before installation.

```bash
./install.sh --ai
claude doctor
claude                       # start inside the intended repository
ollama list
ollama serve                 # local model service, when needed
```

Claude Code uses an interactive account login. Never put Anthropic API keys in `.zshrc` or Git; use a secret manager or temporary environment injection.

Good AI engineering practices:

1. Treat generated code as an untrusted draft: review diffs, test, lint, type-check, and scan dependencies.
2. Grant the smallest necessary repository and tool permissions.
3. Require confirmation for destructive commands, deployments, installation, credential access, and external messages.
4. Do not send secrets, personal data, production logs, or proprietary code to unapproved services.
5. Record design decisions in the repository; chat history is not durable documentation.
6. Put deterministic validation around AI outputs instead of relying on subjective spot checks.
7. Review model licenses, costs, retention policies, and regional requirements.

Ollama supports local model inference, but local execution does not automatically make every model, dataset, or use case permissible.

## Future-ready platform tools

The optional `--future` profile installs these. Install the profile when a project actually needs them rather than making every workstation heavy by default.

```bash
go run .                             # Go
go build ./...
go test ./...

rustup default stable                # Rust
cargo new my-project
cargo build --release

kubectl config get-contexts          # Kubernetes
kubectl config current-context
kubectl get pods -n default
helm repo add stable https://charts.helm.sh/stable
helm install my-release stable/chart-name
k9s                                  # interactive cluster dashboard

grpcurl -plaintext localhost:50051 list   # gRPC
protoc --go_out=. service.proto           # Protocol Buffers

act -l                               # list GitHub Actions workflows/jobs
act pull_request                     # run the pull_request event locally

pre-commit install                   # install git hooks for this repo
pre-commit run --all-files

echo 'export API_URL=http://localhost:3000' > .envrc   # direnv
direnv allow

age-keygen -o key.txt                # age: simple modern file encryption
age -r <public-key> -o secret.age secret.txt
age -d -i key.txt secret.age

sqlite3 app.db                       # SQLite
sqlite3 app.db '.tables'
```

Review every `.envrc` before running `direnv allow`, because it executes shell code. Keep Kubernetes contexts clearly named, check `kubectl config current-context` before changes, and never commit kubeconfig files or cluster tokens. Treat `age`/`sops` private keys like any other credential: never commit them, and store them in a password manager or secret store.

## Docker and Compose

Use Compose to run project dependencies. Pin image versions (for example `redis:7.4`, not `latest`), add health checks, persist only required data in named volumes, and set CPU/memory limits for heavy services.

```bash
docker compose up -d
docker compose ps
docker compose logs -f --tail=100 service-name
docker compose exec service-name sh
docker compose down              # keeps named volumes
docker system df                 # inspect disk use before cleanup
```

Do not bake credentials into images. Use multi-stage builds, a `.dockerignore`, a non-root runtime user, and vulnerability scanning (`trivy image IMAGE`). Avoid `docker system prune --volumes` unless you have reviewed what will be deleted.

## MySQL and MongoDB

Prefer a version-pinned container per project. Keep migration files in source control; do not manually change shared schemas. Use least-privilege application users and TLS outside localhost.

```bash
mysql --host=127.0.0.1 --user=app --password database
mongosh 'mongodb://127.0.0.1:27017/app'
```

Use parameterized queries, indexes based on measured query plans, automated backups, and restore tests. Do not pass passwords directly on a command line in shared environments; use a protected client config or secret provider.

## Redis

Use Redis for cache, rate limiting, coordination, or ephemeral state—not as a default primary database. Set TTLs deliberately and use namespaced keys.

```bash
redis-cli -u redis://localhost:6379 PING
redis-cli --scan --pattern 'myapp:*' | head
```

Never run `KEYS *` on production. Prefer `SCAN`. Configure authentication/TLS and eviction policy consciously; monitor memory, hit rate, latency, and evictions.

## Kafka and Amazon MSK

Design topics around domain events, choose partition keys carefully, and treat ordering as partition-local. Use schemas and compatibility rules. Producers should be idempotent where possible; consumers must tolerate retries and duplicates.

```bash
kcat -b localhost:9092 -L
kcat -b localhost:9092 -t events -C -o end
aws kafka list-clusters-v2 --region ap-south-1
```

For MSK, use TLS/IAM authentication as required by the cluster and obtain bootstrap brokers through AWS CLI. Do not expose broker endpoints publicly. Monitor consumer lag, under-replicated partitions, throughput, and disk capacity.

## OpenSearch

Run OpenSearch locally in Docker because it is resource-heavy. Define mappings and index templates instead of relying on dynamic mapping for production data. Use aliases for zero-downtime reindexing and lifecycle policies for retention.

```bash
curl --fail --silent 'http://localhost:9200/_cluster/health?pretty'
curl --fail --silent 'http://localhost:9200/_cat/indices?v'
```

Avoid unrestricted wildcard searches and oversized shards. Secure production clusters with private networking, encryption, authentication, and least-privilege roles.

## AWS CLI and credentials

Prefer IAM Identity Center (SSO) or `aws-vault`; never store long-lived keys in shell files or repositories.

```bash
aws configure sso --profile company-dev
aws sso login --profile company-dev
AWS_PROFILE=company-dev aws sts get-caller-identity
aws configure list-profiles
```

Always specify a profile and region in automation. Check identity before mutations. Use least-privilege roles, MFA, CloudTrail, budgets, and resource tags.

## Terraform

Pin Terraform and provider versions, use a remote encrypted state backend with locking, and separate environments through distinct state—not fragile variable switches.

```bash
terraform fmt -recursive -check
terraform init
terraform validate
tflint --recursive
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
```

Review plans in CI before apply. Never commit `.terraform/`, state files, plan files, or secrets. Avoid `-auto-approve` for production. Keep modules small and versioned.

## APIs, curl, HTTPie, Postman, JSON, and YAML

Use `curl` in portable scripts, HTTPie for readable interactive calls, and Postman for shared exploratory collections and examples.

```bash
curl --fail-with-body --silent --show-error \
  --header 'Accept: application/json' \
  'https://api.example.com/v1/items' | jq .

http GET https://api.example.com/v1/items Accept:application/json
jq -e '.status == "ok"' response.json
```

Set timeouts and retries consciously, validate status codes and schemas, redact tokens from examples, and keep environment-specific base URLs in variables. In Postman, use secret variables and avoid syncing real credentials in shared environments.

## VS Code

Install the `code` command from VS Code if the cask has not provided it. Keep repository-specific settings in `.vscode/settings.json` only when they benefit everyone.

`./install.sh --desktop` (and `--all`) installs these extensions automatically if missing. To install them manually instead:

```bash
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension bmewburn.vscode-intelephense-client
code --install-extension ms-azuretools.vscode-docker
code --install-extension hashicorp.terraform
code --install-extension redhat.vscode-yaml
code --install-extension editorconfig.editorconfig
```

Use format-on-save only with a project-pinned formatter. Do not rely on an editor extension for checks that CI does not also run.

## A healthy daily workflow

```bash
git pull --ff-only
fnm use                         # when working in Node projects
docker compose up -d            # project dependencies
dev-doctor                      # diagnose PATH/tool availability

# Before pushing
git status
# Run the project's format, lint, static-analysis, and test commands.
git diff --check
gh pr create --fill
```

Periodically run `brew update`, `brew upgrade`, `composer audit`, `npm audit`, `trivy`, and dependency updates through reviewed pull requests.

## Official references

- [Homebrew Bundle documentation](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [uv installation and documentation](https://docs.astral.sh/uv/getting-started/installation/)
- [Claude Code setup](https://docs.anthropic.com/en/docs/claude-code/getting-started)
