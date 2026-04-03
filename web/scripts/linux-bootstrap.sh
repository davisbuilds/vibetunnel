#!/usr/bin/env bash
set -euo pipefail

# Ubuntu-focused bootstrap for VibeTunnel web build on Linux

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "sudo required (or run as root)"
    exit 1
  fi
fi

${SUDO} apt-get update -qq
${SUDO} apt-get install -y -qq \
  curl \
  ca-certificates \
  xz-utils \
  python3 \
  make \
  g++ \
  git \
  libpam0g-dev \
  > /dev/null

# Node.js 24.x must be preinstalled by the caller
need_node=1
if command -v node >/dev/null 2>&1; then
  node_major="$(node -p 'process.versions.node.split(".")[0]')"
  node_minor="$(node -p 'process.versions.node.split(".")[1]')"
  if [ "$node_major" -gt 22 ] || { [ "$node_major" -eq 22 ] && [ "$node_minor" -ge 12 ]; }; then
    need_node=0
  fi
fi

if [ "$need_node" -eq 1 ]; then
  echo "Node.js >= 22.12 is required before running this bootstrap script"
  echo "Install it with your preferred trusted mechanism (for CI, use actions/setup-node)"
  exit 1
fi

# Zig 0.15.2 if missing
if ! command -v zig >/dev/null 2>&1; then
  ZIG_VERSION="0.15.2"
  arch="$(uname -m)"
  case "$arch" in
    aarch64|arm64) export ZIG_TARGET="aarch64-linux";;
    x86_64|amd64) export ZIG_TARGET="x86_64-linux";;
    *) echo "unsupported arch: $arch"; exit 1;;
  esac

  zig_url="https://ziglang.org/download/${ZIG_VERSION}/zig-${ZIG_TARGET}-${ZIG_VERSION}.tar.xz"

  if [ -z "$zig_url" ]; then
    echo "failed to resolve Zig download URL"
    exit 1
  fi

  zig_root="$HOME/.local/zig"
  zig_bin="$HOME/.local/bin"
  if [ -n "$SUDO" ]; then
    zig_root="/usr/local/zig"
    zig_bin="/usr/local/bin"
  fi

  ${SUDO} mkdir -p "$zig_root"
  ${SUDO} mkdir -p "$zig_bin"
  curl -sL "$zig_url" -o /tmp/zig.tar.xz
  ${SUDO} tar -xf /tmp/zig.tar.xz -C "$zig_root" --strip-components=1
  ${SUDO} ln -sf "$zig_root/zig" "$zig_bin/zig"
fi

node -v
npm -v
zig version

echo "\nNext steps:"
echo "  cd web"
echo "  corepack enable"
echo "  pnpm install --frozen-lockfile"
echo "  pnpm run build"
