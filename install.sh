# Install GitHub Copilot CLI on Termux with a single command.
# Usage: bash install.sh [version]

set -euo pipefail

if [ -z "${TERMUX_VERSION:-}" ]; then
  echo "Error: this script must be run in Termux." >&2
  exit 1
fi

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

# Architecture -> official binary package name
case "$(uname -m)" in
  aarch64|arm64) CPU="arm64" ;;
  x86_64|amd64)  CPU="x64" ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

PKG_NAME="@github/copilot-linux-${CPU}"
VERSION="${1:-latest}"
INSTALL_DIR="$HOME/.copilot-termux"
BIN_PATH="$INSTALL_DIR/node_modules/$PKG_NAME/copilot"
WRAPPER="$PREFIX/bin/copilot"

echo "==> 1/5 Termux dependencies"
pkg update -y || echo "pkg update failed; continuing."
pkg install -y nodejs glibc-repo ca-certificates
pkg install -y glibc-runner

echo "==> 2/5 Installing $PKG_NAME@$VERSION dans $INSTALL_DIR"
# Migrate from the old ~/copilot-linux directory
if [ -d "$HOME/copilot-linux" ] && [ ! -e "$INSTALL_DIR" ]; then
  echo "Migrating ~/copilot-linux to $INSTALL_DIR"
  mv "$HOME/copilot-linux" "$INSTALL_DIR"
fi
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
[ -f package.json ] || npm init -y >/dev/null
npm install "$PKG_NAME@$VERSION" --force --os=linux --cpu="$CPU" --libc=glibc

if [ ! -f "$BIN_PATH" ]; then
  echo "Error: binary not found ($BIN_PATH)." >&2
  exit 1
fi
chmod +x "$BIN_PATH"

echo "==> 3/5 Creating the 'copilot' command"
# If an old npm command (a symlink to npm-loader.js) exists, remove it
# to avoid overwriting the file it points to.
if [ -L "$WRAPPER" ]; then
  rm -f "$WRAPPER"
fi
# Paths are hardcoded (expanded during installation), so the script does not depend
# pas de $PREFIX au lancement. Les certificats TLS de Termux sont nécessaires, car le
# glibc binary cannot find /etc/ssl/certs.
cat > "$WRAPPER" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
export SSL_CERT_FILE=$PREFIX/etc/tls/cert.pem
export SSL_CERT_DIR=$PREFIX/etc/tls/certs
exec grun $BIN_PATH "\$@"
EOF
chmod +x "$WRAPPER"

echo "==> 4/5 Removing the old alias"
# A 'copilot' alias in ~/.bashrc overrides the command and bypasses the certificates.
if [ -f "$HOME/.bashrc" ]; then
  sed -i '/alias copilot=/d' "$HOME/.bashrc"
fi

echo "==> 5/5 Verification"
# The "unrecognized option '--binary-version'" message from grun can be ignored.
"$WRAPPER" --version || echo "Verification failed: run 'copilot --version' again to see the error."

echo
echo "Done. Open a new Termux session (or run: unalias copilot 2>/dev/null; hash -r),"
echo "then run 'copilot' and /login."
echo "Update: bash update.sh"
