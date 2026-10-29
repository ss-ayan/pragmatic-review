#!/bin/sh
# Installs the ayan CLI into ~/.local/bin: the native release binary when one
# exists for this platform, otherwise a wrapper that runs the Docker image.
# AYAN_VERSION=vX.Y.Z pins a release; AYAN_BIN_DIR changes the target.
set -eu
dir=${AYAN_BIN_DIR:-$HOME/.local/bin}
mkdir -p "$dir"
os=$(uname -s | tr A-Z a-z)
arch=$(uname -m)
case $arch in x86_64) arch=amd64 ;; aarch64) arch=arm64 ;; esac
asset=ayan_${os}_${arch}.tar.gz
if [ -n "${AYAN_VERSION:-}" ]; then
  url=https://github.com/ss-ayan/ayan/releases/download/$AYAN_VERSION/$asset
else
  url=https://github.com/ss-ayan/ayan/releases/latest/download/$asset
fi

if curl -fsSL "$url" | tar -xz -C "$dir" ayan; then
  echo "installed native ayan to $dir/ayan"
elif command -v docker >/dev/null; then
  cat >"$dir/ayan" <<SH
#!/bin/sh
exec docker run --rm -i -v "\$PWD:/workspace" -w /workspace \\
  -e ANTHROPIC_API_KEY -e OPENAI_API_KEY -e OPENROUTER_API_KEY -e GITHUB_TOKEN \\
  ghcr.io/ss-ayan/ayan:${AYAN_VERSION:-latest} "\$@"
SH
  chmod +x "$dir/ayan"
  echo "no native binary for $os/$arch; installed a Docker wrapper at $dir/ayan"
else
  echo "no native binary for $os/$arch and no docker found" >&2
  exit 1
fi
case ":$PATH:" in *":$dir:"*) ;; *) echo "add $dir to PATH" ;; esac
