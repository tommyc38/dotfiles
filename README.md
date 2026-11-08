# dotfiles

Set up a new Mac — tools, apps, shell, editor/IDE settings, SSH keys, work credentials and every repo
I work on — with one command, and keep an existing Mac converged with the same command.

```bash
git clone https://github.com/tommyc38/dotfiles.git ~/dotfiles   # HTTPS: no SSH key on a new machine yet
cd ~/dotfiles
./bin/preflight.sh        # optional: checks disk, network, Xcode CLT, Homebrew, conflicts
./install.sh              # prompts for the vault password
exec zsh
./bin/validate-install.sh # confirms everything, including logins
```

After the first run, switch the remote to SSH: `git remote set-url origin git@github.com:tommyc38/dotfiles.git`.

## What `install.sh` does

Each step is idempotent: a failed step is reported, the rest continue, and you re-run just what failed.

| Step            | What it does                                                                          |
| --------------- | ------------------------------------------------------------------------------------- |
| `xcode`         | Xcode Command Line Tools (exits so you can finish the dialog, then re-run)            |
| `brew`          | Homebrew, trusts the third-party taps, `brew bundle` the [`Brewfile`](Brewfile)        |
| `vault`         | Decrypts `vault/` → `vault-key/` (SSH keys, `.npmrc`, env files, repo lists)          |
| `symlinks`      | Links dotfiles, vim, Karabiner, Cursor, then everything in `vault-key/symlinks.txt`   |
| `ssh`           | Loads the keys in `vault-key/ssh-keys.txt` into the agent + macOS keychain            |
| `node`          | nvm + Node 18/20/22/24 (+ yarn, pnpm); repos get their `.nvmrc` version on demand     |
| `python`        | pyenv + Python 3.11–3.13; 3.13's virtualenv is Neovim's `nvim-provider`               |
| `vault-install` | `vault-key/install.sh` — private, machine-specific extras                             |
| `fonts`         | Google, Nerd and Powerline fonts ([`bin/fonts.sh`](bin/fonts.sh))                      |
| `macos`         | macOS defaults ([`install/osx.sh`](install/osx.sh))                                    |
| `shell`         | Homebrew zsh as the login shell (sudo for `/etc/shells`)                              |
| `base16`        | base16-shell themes                                                                   |
| `repos`         | Clones every `vault-key/**/*.repos.txt` into `~/dev/...` and installs packages        |
| `auth`          | Logs in to GitHub, Tungsten GHE, Jira, Bitbucket, Azure DevOps ([below](#logins-gh-jira-bitbucket-azure-devops)) |

```bash
./install.sh --list                 # the steps
./install.sh --only brew,symlinks   # just these
./install.sh --skip fonts,repos     # everything but these
VAULT_PASSWORD=... ./install.sh     # non-interactive
```

Never run it with `sudo`. It asks for your password when it needs it: the Homebrew installer, some cask installers, `/etc/shells`, and `chsh`.

## Layout

```
Brewfile                 every formula, cask and tap (brew bundle)
install.sh               orchestrator (above)
install/                 brew.sh, node.sh, python.sh, osx.sh, vagrant.sh (optional, not run by install.sh)
bin/                     on PATH via zshrc
  dev-auth.sh            check / log in to gh, acli (Jira), Bitbucket, az (Azure DevOps)
  vault                  encrypt/decrypt vault/ <-> vault-key/
  symlink.sh             create/restore symlinks (*.symlink, vim, karabiner, cursor, --file lists)
  repo.sh                clone repo lists, install the right Node + package manager per repo
  ssh-setup.sh           load SSH keys into the agent/keychain
  workenv.sh             switch work environments (`workenv <name>`)
  jetbrains-backup.sh    snapshot WebStorm settings into webstorm/settings/
  preflight.sh, validate-install.sh, fonts.sh, e
shell/                   shared by zsh AND bash: env.sh (PATH, Homebrew, node, JAVA_HOME, ...),
                         git.sh / tmux.sh / functions.sh (aliases + helpers)
zsh/                     zshrc.symlink → ~/.zshrc, plus zsh-only *.zsh (options, prompt, colours)
bash/                    bash_profile.symlink / bashrc.symlink → ~/.bash_profile, ~/.bashrc
git/                     gitconfig (included by a local ~/.gitconfig), gitignore_global
vim/                     .vimrc, init.vim, plugins, coc settings, darcula theme
karabiner/               → ~/.config/karabiner (caps lock = esc on tap, ctrl on hold)
cursor/                  → ~/Library/Application Support/Cursor/User/{settings,keybindings}.json
webstorm/                ideavimrc.symlink → ~/.ideavimrc, settings/ (exported backup)
vscode/                  old VS Code settings, kept for reference — not linked
vault/                   encrypted secrets (committed)
vault-key/               decrypted secrets (gitignored — never commit)
```

Symlinks: any `*.symlink` file links to `~/.<name>` automatically. Existing files are moved to
`~/dotfiles_backup/` first, and `bin/symlink.sh --restore` puts them back.

## Vault (secrets in a public repo)

`vault/` holds AES-256 (`openssl -pbkdf2`) encrypted copies of everything in `vault-key/`. **File and
directory names are encrypted too**, so the public repo reveals nothing.

```bash
vault              # decrypt vault/ → vault-key/  (password from $VAULT_PASSWORD or vault-key/password.txt)
vault -e           # after editing vault-key/: re-encrypt with the same password, then commit vault/
vault --list       # decrypted names of what's in vault/
read -rs P; vault -e "$P"   # rotate the password (old one is kept with the backup)
```

- Every run moves the previous target contents to `vault-key/vault_backups/{vault,vault-key}/YYYYMMDD_HHMMSS/`.
- Every encrypt produces new filenames (random salt), so git shows all of `vault/` as deleted + added. That's expected.
- `validate-install.sh` warns when `vault-key/` has changes you haven't encrypted yet.
- The password is **not** exported into your shell. Before, every process you ran (including npm postinstall scripts)
  could read `$VAULT_PASSWORD`. `vault` now reads `vault-key/password.txt` itself.

What's in `vault-key/`:

| File                                 | Used for                                                                 |
| ------------------------------------ | ------------------------------------------------------------------------ |
| `symlinks.txt`                       | `source \| target` pairs linked by the `symlinks` step (full target paths) |
| `ssh-keys.txt`                       | key names (in `~/.ssh`) to load into the agent, one per line             |
| `config`                             | `~/.ssh/config` — one Host block per code host                           |
| `main`, `gotomconley/`, `kofax/`, `tungsten-cloud/`, `azure-devops/` | SSH keys, `.env` files, repo lists per org   |
| `npmrc`                              | `~/.npmrc` — auth for Printix Azure Artifacts, GitHub Packages, Tungsten GHE |
| `tungsten-cloud/tungsten-ca-chain.pem` | `~/.certs/` — CA chain for the Tungsten Artifactory npm mirror         |
| `tungsten-cloud/gitconfig`, `kofax/gitconfig` | work git identities, included for repos under `~/dev/tungsten-cloud/` and `~/dev/printix/` |
| `*.repos.txt`                        | `<ssh-url> <parent-dir>` lines cloned by the `repos` step                |
| `workrc`                             | `~/.workrc` — which `.env` is active (managed by `workenv`)              |
| `install.sh`                         | private extras for the `vault-install` step                              |

## Logins: gh, Jira, Bitbucket, Azure DevOps

```bash
dev-auth.sh            # check everything; opens a browser login for anything that isn't authenticated
dev-auth.sh --check    # report only (validate-install.sh runs this)
dev-auth.sh --only github,jira
```

| Service | Tool | Auth |
| --- | --- | --- |
| GitHub (`tommyc38`, printix org) | `gh` | `gh auth login --hostname github.com --git-protocol ssh --web` |
| Tungsten Cloud GHE | `gh` | same, `--hostname tungstencloud.ghe.com` (SSH user is `tungstencloud`, not `git`) |
| Jira (`tungstenautomation.atlassian.net`) | `acli` (Atlassian's official CLI) | `acli jira auth login --web`, or set `JIRA_API_TOKEN` (+ `JIRA_EMAIL`) for a token login |
| Bitbucket (`tom-conley`) | git over SSH | Atlassian has no official Bitbucket CLI. For REST/API use, put `BITBUCKET_EMAIL` and `BITBUCKET_API_TOKEN` (an [Atlassian API token](https://id.atlassian.com/manage-profile/security/api-tokens) with Bitbucket scopes) in a `vault-key/*.env`; `dev-auth.sh` verifies it |
| Azure DevOps (kofaxcloud) | `az` + `azure-devops` extension | `az login`; the extension is installed automatically |

`gh` and `acli` keep their tokens in the macOS keychain, so they're per machine and nothing goes into the vault.
API tokens you choose to keep (Jira/Bitbucket) belong in a `vault-key/*.env` file, loaded with `workenv`.

## Work environments

`workenv` sources one `vault-key/**/<name>.env` at a time (npm tokens, API keys, ...) and remembers the
choice in `~/.workrc`:

```bash
workenv --list
workenv tungsten-cloud
workenv --env          # current
```

## Projects

| Org | Lives in | List |
| --- | --- | --- |
| Personal / old projects | `~/dev/old_projects`, `~/dotfiles` | `vault-key/main.repos.txt` |
| gotomconley (Bitbucket) | `~/dev/gotomconley` | `vault-key/main.repos.txt` |
| Printix + Tungsten Automation PM (github.com) | `~/dev/printix` | `vault-key/kofax/kofax.repos.txt` |
| Tungsten Cloud (GHE) + Azure DevOps | `~/dev/tungsten-cloud` | `vault-key/tungsten-cloud/tungsten-cloud.repos.txt` |

`repo.sh` skips anything already cloned. It compares remotes loosely, so `user@host:` vs `host:` or `%20` vs a
space still count as the same repo. With `--npm-install` it installs the repo's `.nvmrc` Node and its package
manager (pnpm/yarn/npm, from the lockfile). After you start working in a new repo, add it to the right list
and run `vault -e`. Preview with `repo.sh --dry-run --file <list> -D ~/dev`.

**Tungsten Cloud repos** have their own setup, `pnpm dev:setup` (`tools/dev/setup.sh`, check with
`pnpm dev:doctor`). The vault already supplies the GHE token in `~/.npmrc` and the CA chain, and
`zsh/zshrc.symlink` carries the `# >>> tng dev:setup >>>` block. So on a new machine, `dev:setup` mostly adds
the AWS CodeArtifact profile that the Java backends need. `dev:setup` rewrites that block in place and
always moves it to the **end** of `~/.zshrc`, so keep it last and add nothing after it.

## Apps & IDE settings

- **WebStorm / IntelliJ:** **JetBrains Settings Sync** (JetBrains account, cross-IDE sync on) is the source
  of truth. Sign in on a new machine, choose "get settings from account", and keymaps, code style, colour
  scheme and plugins come back. `~/.ideavimrc` is linked from `webstorm/`. `bin/jetbrains-backup.sh` exports a
  non-secret snapshot (keymaps, code styles, colours, live templates, inspections, editor/font options,
  plugin list) to `webstorm/settings/`, for when you don't want to depend on the account. Re-run it after
  big settings changes and commit.
- **Karabiner:** the whole `~/.config/karabiner` directory links to `karabiner/`. Linking only
  `karabiner.json` doesn't survive, because Karabiner rewrites that file atomically and replaces the link.
- **Cursor:** `settings.json` and `keybindings.json` are linked from `cursor/`, so changes made in Cursor's
  UI land in the repo.
- **iTerm2, VS Code:** not managed yet (see TODO).

## Shell notes

- **zsh is the default shell; bash is fully supported** (e.g. a terminal profile that opens bash) and kept
  at parity. Both load `shell/env.sh` for the environment (Homebrew `shellenv`, GNU tools without the `g`
  prefix, default node, pyenv, `JAVA_HOME` → openjdk@25), and `shell/*.sh` for aliases and functions.
  They also both load `workenv`, SSH keys, nvm with `.nvmrc` switching on `cd`, and pyenv. Put new shared
  things in `shell/` and shell-specific things in `zsh/` or `bash/`.
- The Tungsten `dev:setup` block lives in `~/.zshrc`; bash evaluates it from there, so both shells get
  the npm mirror and CA chain. If you ever run `dev:setup` *from* bash, it appends its own copy to
  `~/.bashrc` instead. That's harmless; delete one of the two copies.
- IntelliJ sources `~/.zshrc` with `INTELLIJ_ENVIRONMENT_READER` set to harvest PATH, `JAVA_HOME` and
  node. Anything interactive or slow is skipped in that case.
- nvm loads with `--no-use`, and the default Node goes on PATH directly (saves ~1.5s per shell). On `cd`, a
  directory's `.nvmrc` version is switched to. If it isn't installed, you get a hint instead of an
  automatic source build.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `vault` says getopt is too old | `brew install gnu-getopt` (the `brew` step does this) |
| A step failed | `./install.sh --only <step>` |
| `ssh -T git@github.com` fails | `bin/ssh-setup.sh`, then check `vault-key/ssh-keys.txt` and `~/.ssh/config` |
| GHE clone fails with `git@` | GHE uses `tungstencloud@tungstencloud.ghe.com:Org/repo.git` |
| Tungsten `pnpm install` TLS errors | `~/.certs/tungsten-ca-chain.pem` missing → re-run the `symlinks` step, or `pnpm dev:setup` |
| Brew refuses a tap formula | `brew trust <tap>`; the `brew` step trusts everything in `TRUSTED_TAPS` |
| Undo the symlinks | `bin/symlink.sh --restore --include-vim --include-karabiner --include-editors` |

## TODO

- iTerm2 preferences (`defaults` export or iTerm's "load preferences from a folder").
- Decide whether `vscode/` is still wanted. It's from an old Windows machine and isn't linked.
- Claude Code / Codex config (`~/.claude/settings.json`, `CLAUDE.md`, ...).
