#!/usr/bin/env bash

# RRS agent development prerequisites for Ubuntu on WSL.
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
  echo "このスクリプトは Ubuntu 系の WSL を対象にしています。" >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install --yes \
  build-essential \
  curl \
  git \
  libspatialindex-dev \
  openjdk-21-jdk \
  pkg-config \
  unzip

if ! command -v uv >/dev/null 2>&1; then
  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"
  curl --proto '=https' --tlsv1.2 -LsSf https://astral.sh/uv/install.sh | \
    env UV_INSTALL_DIR="$INSTALL_DIR" sh
  export PATH="$INSTALL_DIR:$PATH"
fi

uv python install 3.13

cat <<'EOF'

導入が完了しました。新しいターミナルでも uv を使えるよう、~/.local/bin が PATH に含まれることを確認してください。
Python の依存関係は、チームのディレクトリで `uv sync` を実行して用意します。
EOF
