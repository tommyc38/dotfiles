# dotfiles

Set up a new Mac — tools, apps, shell, editor/IDE settings, SSH keys, work credentials and every repo
I work on — with one command, and keep an existing Mac converged with the same command.

## Getting started

Two ways to set up a new Mac. Both end in the same state, and both are safe to re-run.

**You'll need:** the vault password, an internet connection, the **Tungsten VPN** (for Tungsten repos and
npm installs), and time. The first run is long, mostly downloads: Homebrew apps, Node/Python builds, and
installing every repo's packages.

**Steps only you can do** (passwords, dialogs, browser logins), whichever path you take:

| Step | Why it needs you |
| --- | --- |
| `xcode` | macOS shows an install dialog for the Command Line Tools |
| `brew` | Homebrew's installer asks for your password and RETURN; the VirtualBox and Karabiner installers ask for an admin password |
| `vault` | the vault password (typed, never pasted into a chat) |
| `shell` | `sudo` for `/etc/shells`, and your password for `chsh` |
| `auth` | browser logins: GitHub, Tungsten GHE, Jira, Bitbucket |
| afterwards | approve Karabiner in System Settings → Privacy & Security; sign in to WebStorm (Settings Sync), Docker Desktop and Claude Code (`/mcp` → atlassian) |

Everything else (symlinks, SSH keys, Node, Python, Claude plugins/MCPs, fonts, macOS defaults, cloning and
installing every repo, validation) runs unattended.

### A. From nothing, by hand

```bash
# 1. Command Line Tools (gives you git). Finish the dialog before continuing.
xcode-select --install

# 2. Get the repo. HTTPS, because your SSH keys are still inside the vault.
git clone https://github.com/tommyc38/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 3. Optional sanity check: disk, network, Xcode CLT, conflicting files.
./bin/preflight.sh

# 4. Everything. Prompts for the vault password, your sudo password and browser logins as it goes.
#    Connect the VPN first, or add --skip repos and run `./install.sh --only repos` later on VPN.
./install.sh

# 5. Load the new shell and check the result.
exec zsh
./bin/validate-install.sh

# 6. Switch this repo to SSH now that the keys are in place.
git remote set-url origin git@github.com:tommyc38/dotfiles.git
```

Then do the "afterwards" items from the table above.
(Its `vault` step won't decrypt over local `vault-key/` edits you haven't encrypted yet. It lists them
and tells you to `vault -e` first.)
If a step fails, fix it and run `./install.sh --only <step>`. Nothing else re-runs.

### B. With an agent (Claude Code) doing the work

You do the few interactive steps in a terminal. The agent runs the long, unattended rest, reads the
output, and fixes or reports failures.

```bash
# 1. You, in Terminal: Command Line Tools, Claude Code itself, and the repo.
xcode-select --install                                  # finish the dialog first
curl -fsSL https://claude.ai/install.sh | bash          # official native installer → ~/.local/bin/claude
git clone https://github.com/tommyc38/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. You: the steps that need a password (Homebrew + apps, then the vault).
./install.sh --only xcode,brew,vault

# 3. You: start the agent here and sign in.
~/.local/bin/claude
```

Connect the VPN, then paste this prompt into Claude Code:

> Read README.md in this repo. Then run `./install.sh --skip xcode,brew,vault,shell,auth` (it can take a
> while; run it in the background and check on it). When it finishes, run `./bin/validate-install.sh` and
> `./bin/dev-auth.sh --check`. For each failed step, find the cause, fix it if it's a problem in this repo
> or a missing dependency, and re-run it with `./install.sh --only <step>`. Don't change git, npm or
> registry configuration to work around a failure, and never print the contents of `vault-key/`. Finish
> with a list of what passed, what you fixed, and what I still need to do myself.

```bash
# 4. You, in a terminal: the last two interactive steps.
./install.sh --only shell,auth
exec zsh
```

Then do the "afterwards" items. In Claude Code, run `/mcp` → atlassian → authenticate.

Why split it this way:
- **Password prompts need a real terminal.** The vault prompt reads from your terminal, which the
  agent's commands don't have. It's also a secret that shouldn't pass through a chat. You decrypt in
  step 2, and the agent's run skips the `vault` step, so it never needs the password.
- **Your Claude settings arrive mid-session.** The `symlinks` step links `~/.claude/settings.json` from
  the vault. Claude Code picks up the change without a restart, including the `ask` rules that make it
  prompt before reading secrets.

### Already set up? Keep a Mac current

```bash
cd ~/dotfiles && git pull
./install.sh --skip fonts       # converge: decrypt vault updates, new Brewfile entries, links, repos, plugins, ...
./bin/validate-install.sh
```

## What `install.sh` does

Each step is idempotent: a failed step is reported, the rest continue, and you re-run just what failed.

| Step            | What it does                                                                          |
| --------------- | ------------------------------------------------------------------------------------- |
| `xcode`         | Xcode Command Line Tools (exits so you can finish the dialog, then re-run)            |
| `brew`          | Homebrew, trusts the third-party taps, `brew bundle` the [`Brewfile`](Brewfile)        |
| `vault`         | Decrypts `vault/` → `vault-key/` (SSH keys, `.npmrc`, env files, repo lists)          |
| `symlinks`      | Links dotfiles, vim, Karabiner, VS Code, then everything in `vault-key/symlinks.txt` |
| `ssh`           | Loads the keys in `vault-key/ssh-keys.txt` into the agent + macOS keychain            |
| `node`          | nvm + Node 18/20/22/24 (+ yarn, pnpm); repos get their `.nvmrc` version on demand     |
| `python`        | pyenv + Python 3.11–3.13; 3.13's virtualenv is Neovim's `nvim-provider`               |
| `vault-install` | `vault-key/install.sh` — private, machine-specific extras                             |
| `fonts`         | Google, Nerd and Powerline fonts ([`bin/fonts.sh`](bin/fonts.sh))                      |
| `macos`         | macOS defaults ([`install/osx.sh`](install/osx.sh))                                    |
| `shell`         | Homebrew zsh as the login shell (sudo for `/etc/shells`)                              |
| `base16`        | base16-shell themes                                                                   |
| `repos`         | Clones every `vault-key/**/*.repos.txt` into `~/dev/...` and installs packages        |
| `auth`          | Logs in to GitHub, Tungsten GHE, Jira, Bitbucket ([below](#logins-gh-jira-bitbucket)) |

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
install/                 brew.sh, node.sh, python.sh, claude.sh, osx.sh, vagrant.sh (optional, not run by install.sh)
bin/                     on PATH in both shells (shell/env.sh)
  dev-auth.sh            check / log in to gh, acli (Jira), Bitbucket
  vault                  encrypt/decrypt vault/ <-> vault-key/
  symlink.sh             create/restore symlinks (*.symlink, vim, karabiner, vscode, --file lists)
  repo.sh                clone repo lists, install the right Node + package manager per repo
  ssh-setup.sh           load SSH keys into the agent/keychain
  workenv.sh             work environments: show/pin/unpin (`workenv --help`); folder switching is shell/workenv-auto.sh
  jetbrains-backup.sh    snapshot WebStorm settings into webstorm/settings/
  preflight.sh, validate-install.sh, fonts.sh, e
shell/                   shared by zsh AND bash: env.sh (PATH, Homebrew, node, JAVA_HOME, ...),
                         workenv-auto.sh (folder-based work environments),
                         git.sh / tmux.sh / functions.sh (aliases + helpers)
zsh/                     zshrc.symlink → ~/.zshrc, plus zsh-only *.zsh (options, prompt, colours)
bash/                    bash_profile.symlink / bashrc.symlink → ~/.bash_profile, ~/.bashrc
git/                     gitconfig (included by a local ~/.gitconfig), gitignore_global
vim/                     .vimrc, init.vim, plugins, coc settings, darcula theme
karabiner/               → ~/.config/karabiner (caps lock = esc on tap, ctrl on hold)
webstorm/                ideavimrc.symlink → ~/.ideavimrc, settings/ (exported backup)
vscode/                  settings.json → ~/Library/Application Support/Code/User/ (legacy/: old Windows settings, not linked)
vault/                   encrypted secrets (committed)
vault-key/               decrypted secrets (gitignored — never commit)
```

Symlinks: any `*.symlink` file links to `~/.<name>` automatically. Existing files are moved to
`~/dotfiles_backup/` first, at the same path relative to `$HOME`, so same-named files don't collide.
`bin/symlink.sh --restore` puts them back.

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
| `personal/`, `tungsten/`             | one folder per root: `<env>.env`, `<env>.repos.txt`, `<env>.gitconfig`, `ssh/<profile>` keys (linked as `~/.ssh/<root>-<profile>`) |
| `npmrc`                              | `~/.npmrc`: fallback only (the `${TUNGSTEN_PACKAGES_TOKEN}` line for Tungsten `dev:setup`); no tokens, no registry |
| `**/<env>.npmrc`                     | the env's whole npm/pnpm config: scopes, `${VAR}` credentials, `@registry-candidates` ([below](#npm--pnpm-registries-one-config-per-env-the-repos-npmrc-still-wins)) |
| `tungsten/tungsten-ca-chain.pem`     | `~/.certs/` — CA chain for the Tungsten Artifactory npm mirror           |
| `tungsten/*.gitconfig`               | work git identities (+ printix SSH key), included for repos under `~/dev/tungsten/tungsten-cloud/` and `~/dev/tungsten/printix/` |
| `*.repos.txt`                        | `<ssh-url> <parent-dir>` lines cloned by the `repos` step                |
| `workrc`                             | `~/.workrc` — the default work environment outside mapped folders (`workenv <name>` changes it) |
| `workenv-dirs.txt`                   | folder → work environment mapping (`workenv --dirs`)                     |
| `install.sh`                         | private extras for the `vault-install` step                              |
| `claude/settings.json`               | `~/.claude/settings.json`: personal Claude Code defaults                  |

## Logins: gh, Jira, Bitbucket

```bash
dev-auth.sh            # check everything; opens a browser login for anything that isn't authenticated
dev-auth.sh --check    # report only (validate-install.sh runs this)
dev-auth.sh --only github,jira
```

| Service | Tool | Auth |
| --- | --- | --- |
| GitHub (`tommyc38`: personal + printix org) | `gh` | `gh auth login --hostname github.com --git-protocol ssh --web` |
| Tungsten Cloud GHE (SSO `tom.conley@kofaxcloud.com` → `tom-conley`) | `gh` | same, `--hostname tungstencloud.ghe.com` (SSH user is `tungstencloud`, not `git`) |
| Jira (`tungstenautomation.atlassian.net`) | `acli` (Atlassian's official CLI) | `acli jira auth login --web`, or set `JIRA_API_TOKEN` (+ `JIRA_EMAIL`) for a token login |
| Bitbucket (`tom-conley`) | git over SSH via `ssh.bitbucket.org` (Atlassian moved SSH off `bitbucket.org` in 2026; `~/.ssh/config` routes old `git@bitbucket.org:` remotes there) | Atlassian has no official Bitbucket CLI. For REST/API use, put `BITBUCKET_EMAIL` and `BITBUCKET_API_TOKEN` (an [Atlassian API token](https://id.atlassian.com/manage-profile/security/api-tokens) with Bitbucket scopes) in a `vault-key/*.env`; `dev-auth.sh` verifies it |

`gh` and `acli` keep their tokens in the macOS keychain, so they're per machine and nothing goes into the vault.
API tokens you choose to keep (Jira/Bitbucket) belong in a `vault-key/*.env` file, loaded with `workenv`.

## Work environments (tokens, API keys)

Each org's secrets live in its own `vault-key/**/<name>.env` (`personal`, `printix`, `tungsten-cloud`).
Shells load **one** of them, chosen by folder:

| You're in | Loaded env |
| --- | --- |
| a folder listed in `vault-key/workenv-dirs.txt` (longest match wins) | that folder's env, e.g. `~/dev/tungsten/printix` → `printix` |
| anywhere else | the default named in `~/.workrc` |

- It switches automatically on every `cd`, in zsh and bash, and prints `workenv: old → new`. It unsets the old
  env's variables before loading the new one, so tokens never leak across orgs.
- WebStorm's environment harvest gets the env for the folder it reads from, so npm/pnpm run from the IDE
  get credentials too.
- `workenv <name>` sets the default for new shells **and pins the current shell** to `<name>` (e.g. to use
  Printix tokens from inside `~/dev/tungsten/tungsten-cloud`). `workenv --auto` unpins it.
- `workenv --env` shows the current one, `--dirs` the folder mapping, and `--list` every env.
- New folder or org: add a line to `vault-key/workenv-dirs.txt` (and a `.env` if needed), then `vault -e`.

### npm / pnpm registries: one config per env, the repo's `.npmrc` still wins

Every env has **one** npm/pnpm file, `vault-key/**/<env>.npmrc` next to `<env>.env`. It holds the env's
scopes and every credential it needs, written as `${VAR}`. The values live only in `<env>.env`, so nothing
leaks between orgs. `workenv` copies that file to `~/.cache/dotfiles/npmrc/<env>` (mode 600), adds a
default `registry=` for the network you're on, and exports `npm_config_userconfig`. npm and pnpm then use
that file **instead of** `~/.npmrc`. So when a project's docs say "add this to your ~/.npmrc", put the line
in that env's `.npmrc`. Projects with different registries never see each other's settings.

**Repos are never changed, and their own `.npmrc` wins.** npm and pnpm read it above the user config and
merge the two **key by key** (tested with npm 11 and pnpm 11.24):

| The repo's `.npmrc` has | What gets used |
| --- | --- |
| `registry=` / `@scope:registry=` only | the repo's registry + **the env's token for that host** |
| a `${VAR}` token, and the env exports `VAR` | the repo's line (npm always; pnpm for the default registry) |
| a `${VAR}` token for a scoped registry, under pnpm | pnpm ignores the repo line (and warns) → the env's token |
| a `${VAR}` the env does **not** export | the literal text `${VAR}` is sent → **401**, even though the env has a valid token |

That last row is the one rule: every variable a repo's `.npmrc` references must be exported by its folder's
env, under that exact name. If a repo uses its own name for a token you already have, export it as an
alias (`printix.env` does this for partner-portal-ui's `AZURE_NPM_TOKEN_B64`).
**`workenv --doctor`** scans every repo in the mapped folders. It reports missing variables, registries with
no credentials, and unreachable defaults. `validate-install.sh` runs it.

Only two variables are exported: `npm_config_userconfig`, a file path, and `COREPACK_NPM_REGISTRY`, which
only controls where Corepack downloads pnpm itself. Settings like `npm_config_registry` would override the
repo's own `.npmrc`, so they're never set.

**Default registry (per network).** Each env's `.npmrc` lists candidates in order, for example
`; @registry-candidates https://<artifactory>/… https://registry.npmjs.org/`. `workenv` uses the first one
that answers within 2 seconds, and caches the result for 15 minutes. Tungsten Cloud therefore gets the
mirror on VPN and public npm off it; personal gets public npm, or the mirror where npm is blocked.

- `workenv --refresh` re-probes, for example after connecting or disconnecting the VPN.
- `workenv --registry public|mirror|<url>` overrides it for this shell only (say, public npm to reproduce CI
  while you're on VPN). `--registry auto` or `workenv --auto` goes back to detection.
- `DOTFILES_NPM_REGISTRY=<same values>` in `~/.config/dotfiles/local.sh` sets a default for one machine.
  This replaces the old `~/.config/dotfiles/npmrc` layer, which is no longer read.
- `workenv --env` shows the chosen registry and why it was chosen.

**`~/.npmrc`** (`vault-key/npmrc`) is only a fallback for processes started outside a shell. It holds no
tokens and no `registry=`, just the `${TUNGSTEN_PACKAGES_TOKEN}` line that Tungsten's `dev:setup` looks for
there.

- **Edit the env's `.npmrc`, not the generated file.** `npm config set` and `npm login` write to the
  generated copy, which is rebuilt on the next switch.
- **Same machine, other folders:** `~/.config/dotfiles/workenv-dirs.txt` adds or overrides folder → env
  mappings just for that computer, and `~/.config/dotfiles/local.sh` holds any other machine-only shell setting.

Your default environment outside mapped folders is `personal`. `workenv <name>` changes it.

## Projects

| Org | Lives in | List |
| --- | --- | --- |
Two roots — **personal** (everything I own) and **tungsten** (work) — each grouped by brand/org, not by git host.

| Root | Org / brand | Lives in | List | Env |
| --- | --- | --- | --- | --- |
| personal | dotfiles | `~/dotfiles` | `vault-key/personal/personal.repos.txt` | `personal` |
| personal | AWS platform (bootstrap, shared infra) | `~/dev/personal/platform` | 〃 | 〃 |
| personal | shared libraries (`@gotomconley`) | `~/dev/personal/libs` | 〃 | 〃 |
| personal | gotomconley, umbrelo, vidtack | `~/dev/personal/<brand>` | 〃 | 〃 |
| personal | retired projects | `~/dev/personal/archive` | 〃 | 〃 |
| tungsten | Printix + Tungsten Automation PM (github.com, `tommyc38`) | `~/dev/tungsten/printix` | `vault-key/tungsten/printix.repos.txt` | `printix` |
| tungsten | Tungsten Cloud (GHE) | `~/dev/tungsten/tungsten-cloud` | `vault-key/tungsten/tungsten-cloud.repos.txt` | `tungsten-cloud` |

`repo.sh` skips anything already cloned. It compares remotes loosely, so `user@host:` vs `host:` or `%20` vs a
space still count as the same repo. With `--npm-install` it installs the repo's `.nvmrc` Node and its package
manager (pnpm/yarn/npm, from the lockfile). After you start working in a new repo, add it to the right list
and run `vault -e`. Preview with `repo.sh --dry-run --file <list> -D ~/dev`.

**Tungsten Cloud repos** have their own setup, `pnpm dev:setup` (`tools/dev/setup.sh`, check with
`pnpm dev:doctor`). It's the team's script, and these dotfiles adapt to it rather than change it. The vault
already supplies the GHE token (`${TUNGSTEN_PACKAGES_TOKEN}`, in `tungsten-cloud.npmrc` and `~/.npmrc`) and the CA chain, and
the mirror is picked automatically when it's reachable. So on a new machine, `dev:setup` mostly adds the AWS CodeArtifact profile that the
Java backends need. Run it from a tungsten-cloud folder as **`TNG_SETUP_REGISTRY=public pnpm dev:setup`**: otherwise it writes
a `registry=<mirror>` line into the shared `~/.npmrc`, which would follow you to machines that can't reach
the mirror. `workenv --doctor` (and so `validate-install.sh`) warns if that line appears. It also keeps a marked block at the **end** of
`~/.zshrc` (`NODE_EXTRA_CA_CERTS`), so keep that block last and add nothing after it.

## Apps & IDE settings

- **WebStorm / IntelliJ:** **JetBrains Settings Sync** (JetBrains account, cross-IDE sync on) is the source
  of truth. Sign in on a new machine, choose "get settings from account", and keymaps, code style, colour
  scheme and plugins come back. `~/.ideavimrc` is linked from `webstorm/`. `bin/jetbrains-backup.sh` exports a
  non-secret snapshot (keymaps, code styles, colours, live templates, inspections, editor/font options,
  plugin list) to `webstorm/settings/`, for when you don't want to depend on the account. Re-run it after
  big settings changes and commit.
- **Karabiner:** the whole `~/.config/karabiner` directory links to `karabiner/`. Linking only
  `karabiner.json` doesn't survive, because Karabiner rewrites that file atomically and replaces the link.
- **VS Code:** `settings.json` is linked from `vscode/`. The terminal defaults to zsh, and there's a
  `bash` profile in the terminal dropdown (both login shells, so they load the same config as a terminal tab).
- **iTerm2:** not managed yet (see TODO).

## Claude Code

| What | Where it lives | Synced how |
| --- | --- | --- |
| CLI | `~/.local/bin/claude` (native installer, auto-updates) | `claude` step (`install/claude.sh`) |
| Personal settings | `~/.claude/settings.json` → `vault-key/claude/settings.json` | vault (it holds internal auto-mode context) |
| Nx plugin (`nx@nx-claude-plugins`: skills, CI-monitor subagent, `nx-mcp`) | user scope | `claude` step + `enabledPlugins` in settings |
| MCP servers: `atlassian`, `playwright`, `context7` | user scope, in `~/.claude.json` | `claude` step (`claude mcp add --scope user`) |
| Project config | each repo's `.claude/settings.json` (committed) and `.claude/settings.local.json` (yours, git-ignored) | comes with the repos |

**Layering** (highest wins): managed → `--settings` → project `settings.local.json` → project `settings.json` →
your `~/.claude/settings.json`. Lists such as permission rules are **combined** across levels, so projects add
to your defaults rather than replacing them. `autoMode` can only be set at user level.

**What the personal defaults contain:**
- your model and auto-mode rules;
- `allow` rules for read-only `gh` / `acli` / `nx` / `npm` / `pnpm` / `brew` commands;
- `ask` rules before Claude reads the vault, `~/.ssh`, `~/.npmrc`, AWS credentials or `.env` files, and before
  force-pushes, `git reset --hard` and `git clean`;
- the Nx plugin.

`/model` and `/config` write through the link into the vault, so run `vault -e` afterwards; `validate-install.sh`
reminds you.

**Once per machine:** run `claude`, sign in, then `/mcp` → atlassian → authenticate.

**Never synced** (machine state): `~/.claude.json`, `~/.claude/projects/`, `history.jsonl`, `sessions/`,
`file-history/`, and credentials (in the macOS keychain).

**`npx` MCP servers** (`playwright`, the Nx plugin's `nx-mcp`) download through whatever registry the folder
you start Claude in resolves to (see "npm / pnpm registries"). On a machine whose default is the mirror,
they need the VPN and fail if the mirror can't serve a package. `claude mcp list` shows their health.

## Shell notes

- **zsh is the default shell; bash is fully supported** (e.g. a terminal profile that opens bash) and kept
  at parity. Both load `shell/env.sh` for the environment (Homebrew `shellenv`, GNU tools without the `g`
  prefix, default node, pyenv, `JAVA_HOME` → openjdk@25), and `shell/*.sh` for aliases and functions.
  They also both load `workenv`, SSH keys, nvm with `.nvmrc` switching on `cd`, and pyenv. Put new shared
  things in `shell/` and shell-specific things in `zsh/` or `bash/`.
- The Tungsten `dev:setup` block lives in `~/.zshrc`; bash evaluates it from there, so both shells get
  the CA chain. If you ever run `dev:setup` *from* bash, it appends its own copy to `~/.bashrc` instead.
  That's harmless; delete one of the two copies. Registries aren't set there; see "npm / pnpm registries".
- IntelliJ sources `~/.zshrc` with `INTELLIJ_ENVIRONMENT_READER` set to harvest PATH, `JAVA_HOME`, node,
  the Tungsten npm settings and the work environment for the folder it reads from. Anything interactive
  or slow is skipped in that case.
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
| Wrong tokens / 401 from a registry | `workenv --env` (is this shell pinned?), `workenv --dirs`; `workenv --auto` to follow folders again |
| npm/pnpm hits the wrong registry, or can't reach one | `workenv --env` shows the default registry and why; `workenv --refresh` after a VPN change; `workenv --registry public\|mirror` to override |
| 401 although the env has the token | `workenv --doctor`: usually the repo's `.npmrc` references a `${VAR}` the env doesn't export (add an alias) |
| Undo the symlinks | `bin/symlink.sh --restore` (`~/.gitconfig` is a local file — just remove its `[include]`) |

## TODO

- iTerm2 preferences (`defaults` export or iTerm's "load preferences from a folder").
- Decide whether anything in `vscode/legacy/` (old Windows settings: vim keybindings, Darcula colours) should
  move into `vscode/settings.json`.
- Optional personal `~/.claude/CLAUDE.md` (standing instructions for every project).
