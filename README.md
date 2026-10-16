# GitHub Copilot CLI for Termux

Install or update [GitHub Copilot CLI](https://github.com/features/copilot/cli) on Termux with a single command.

> Unofficial: not affiliated with GitHub or Microsoft. The scripts only automate installing the official Linux binary.

## Before installation

Update Termux packages first:

```sh
pkg update -y
```

## Installation

```sh
curl -fsSL https://github.com/RivoLink/copilot-termux-installer/raw/main/install.sh | bash
```

To install a specific version:

```sh
curl -fsSL https://github.com/RivoLink/copilot-termux-installer/raw/main/install.sh | bash -s -- 1.0.98
```

## What the script does

1. **Installs dependencies** - `nodejs`, `glibc-repo`, `glibc-runner`, `ca-certificates` via pkg
2. **Installs the official binary** - `@github/copilot-linux-<arch>` via npm into `~/.copilot-termux`
3. **Creates the `copilot` command** - a wrapper in `$PREFIX/bin/copilot` that runs the binary through `grun` with Termux's TLS certificates
4. **Removes any old `copilot` alias** from `~/.bashrc`, since it would bypass the wrapper
5. **Checks the install** with `copilot --version`

## Why not `npm install -g @github/copilot`?

Termux reports its platform as `android`, and Copilot CLI only publishes binaries for darwin, linux, linuxmusl and win32. npm installs no binary, and the launcher fails with:

```
GitHub Copilot CLI: no platform package found.
```

The official `linux-arm64` binary is built for glibc, while Termux uses Bionic, so it runs through [glibc-runner](https://github.com/termux-pacman/glibc-packages) (`grun`).

The binary also looks for TLS certificates in `/etc/ssl/certs`, which does not exist on Termux. Without the wrapper's `SSL_CERT_FILE` and `SSL_CERT_DIR` settings, login fails with `unable to get local issuer certificate`.

## After installation

Open a new Termux session, then start Copilot and sign in:

```sh
copilot
```

Type `/login` and follow the instructions.

## Updating

```sh
curl -fsSL https://github.com/RivoLink/copilot-termux-installer/raw/main/update.sh | bash
```

To update to a specific version:

```sh
curl -fsSL https://github.com/RivoLink/copilot-termux-installer/raw/main/update.sh | bash -s -- 1.0.98
```

The script only reinstalls when the version differs, and recreates the `copilot` command if it is missing. Do not use `copilot update`: it may break this installation.

## Troubleshooting

- **`unrecognized option '--binary-version'`** printed by `grun`: harmless.
- **Sign-in or TLS errors** (`unable to get local issuer certificate`): run `type copilot`. It must answer `copilot is /data/data/com.termux/files/usr/bin/copilot`, not "aliased to ...". Then check that `cat $PREFIX/bin/copilot` shows the two `SSL_CERT_*` lines and that `$PREFIX/etc/tls/cert.pem` exists (`pkg install ca-certificates`).
- **`copilot: command not found`** right after install: open a new session or run `hash -r`.
- **No `/login`?** Export a fine-grained personal access token with the "Copilot Requests" permission as `GITHUB_TOKEN`. Keep it private.

## Uninstall

```sh
rm -f $PREFIX/bin/copilot
rm -rf ~/.copilot-termux
```

Your login and settings live in `~/.copilot`; delete it too only if you want to lose them.

## Requirements

- Termux on Android (`aarch64` or `x86_64`)
- Internet connection
- A GitHub account with a Copilot subscription
- About 200 MB of free storage (the binary alone is about 180 MB)

Tested on Termux 0.118.3 (android-arm64) with Copilot CLI 1.0.98.
