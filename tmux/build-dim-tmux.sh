#!/usr/bin/env bash
# Build a patched tmux with inactive-pane dimming (colour_dim) and install the
# binary to ~/.local/bin/tmux. Re-run this after a `brew upgrade tmux` if brew
# relinks its own tmux (run `brew unlink tmux` afterward so this build wins).
#
# Source: anonymous.4open.science/r/chud-methodology-1477  (dim-inactive-panes.patch)
set -euo pipefail

VERSION=3.5a
PATCH="$HOME/.config/tmux/dim-inactive-panes.patch"
PREFIX="$HOME/.local"
BREW=/opt/homebrew
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo ">> build dir: $BUILD_DIR"
export PKG_CONFIG_PATH="$BREW/opt/ncurses/lib/pkgconfig:$BREW/opt/libevent/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

EXTRA=(--enable-sixel)   # match Homebrew tmux (you use sixel for yt-search/mpv)
if [ -d "$BREW/opt/utf8proc" ]; then
  EXTRA+=(--enable-utf8proc)
  export PKG_CONFIG_PATH="$BREW/opt/utf8proc/lib/pkgconfig:$PKG_CONFIG_PATH"
  echo ">> utf8proc: enabled"
else
  echo ">> utf8proc: not found, building without it"
fi

cd "$BUILD_DIR"
echo ">> downloading tmux $VERSION source"
curl -fsSL "https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz" -o tmux.tar.gz
tar xzf tmux.tar.gz
cd "tmux-${VERSION}"

echo ">> applying dim patch"
patch -p1 --forward < "$PATCH"

echo ">> configure"
./configure --prefix="$PREFIX" "${EXTRA[@]}" \
  CFLAGS="-I$BREW/opt/libevent/include -I$BREW/opt/ncurses/include" \
  LDFLAGS="-L$BREW/opt/libevent/lib -L$BREW/opt/ncurses/lib" >/dev/null

echo ">> make"
make -j"$(sysctl -n hw.ncpu)" >/dev/null

mkdir -p "$PREFIX/bin"
# Install atomically: write a fresh inode, re-sign ad-hoc, then rename over the
# target. Overwriting an in-use binary in place corrupts its code signature on
# Apple Silicon and the kernel SIGKILLs it ("Killed: 9"). A rename swaps the
# directory entry to a new inode, so a running tmux server keeps the old one.
cp -f tmux "$PREFIX/bin/tmux.new"
codesign --force --sign - "$PREFIX/bin/tmux.new" 2>/dev/null || true
mv -f "$PREFIX/bin/tmux.new" "$PREFIX/bin/tmux"
echo ">> installed: $("$PREFIX/bin/tmux" -V)  ->  $PREFIX/bin/tmux"
