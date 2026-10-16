# Update GitHub Copilot CLI on Termux with a single command.
# Usage: bash update.sh [version]

set -euo pipefail

if [ -z "${TERMUX_VERSION:-}" ]; then
  echo "Error: this script must be run in Termux." >&2
  exit 1
fi

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

case "$(uname -m)" in
  aarch64|arm64) CPU="arm64" ;;
  x86_64|amd64)  CPU="x64" ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

PKG_NAME="@github/copilot-linux-${CPU}"
INSTALL_DIR="$HOME/.copilot-termux"
PKG_JSON="$INSTALL_DIR/node_modules/$PKG_NAME/package.json"
BIN_PATH="$INSTALL_DIR/node_modules/$PKG_NAME/copilot"
WRAPPER="$PREFIX/bin/copilot"
TARGET="${1:-latest}"

# Migrate from the old ~/copilot-linux directory
if [ -d "$HOME/copilot-linux" ] && [ ! -e "$INSTALL_DIR" ]; then
  echo "Migrating ~/copilot-linux to $INSTALL_DIR"
  mv "$HOME/copilot-linux" "$INSTALL_DIR"
fi

if [ ! -d "$INSTALL_DIR" ]; then
  echo "Copilot is not installed in $INSTALL_DIR. Run this first: bash install.sh" >&2
  exit 1
fi

CURRENT="none"
if [ -f "$PKG_JSON" ]; then
  CURRENT="$(node -p "require('$PKG_JSON').version")"
fi

if [ "$TARGET" = "latest" ]; then
  WANTED="$(npm view "$PKG_NAME" version)"
else
  WANTED="$TARGET"
fi

echo "Installed version: $CURRENT"
echo "Target version: $WANTED"

if [ "$CURRENT" != "$WANTED" ]; then
  cd "$INSTALL_DIR"
  npm install "$PKG_NAME@$WANTED" --force --os=linux --cpu="$CPU" --libc=glibc
  chmod +x "$BIN_PATH"
else
  echo "Already up to date."
fi

# Check that the 'copilot' command includes the TLS certificates, and recreate it if not
# (useful if it was deleted or replaced).
if ! grep -q "SSL_CERT_FILE" "$WRAPPER" 2>/dev/null || ! grep -qF "$BIN_PATH" "$WRAPPER" 2>/dev/null; then
  echo "Recreating the 'copilot' command."
  [ -L "$WRAPPER" ] && rm -f "$WRAPPER"
  cat > "$WRAPPER" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
export SSL_CERT_FILE=$PREFIX/etc/tls/cert.pem
export SSL_CERT_DIR=$PREFIX/etc/tls/certs
exec grun $BIN_PATH "\$@"
EOF
  chmod +x "$WRAPPER"
fi

echo
echo "Current version:"
"$WRAPPER" --version || echo "Verification failed: run 'copilot --version' again to see the error."
