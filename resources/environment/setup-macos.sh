#!/usr/bin/env bash

# RRS agent development prerequisites for macOS with Homebrew.
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew が見つかりません。https://brew.sh/ の手順で導入してから再実行してください。" >&2
  exit 1
fi

brew install git openjdk@21 python@3.13 uv

JDK_HOME="$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home"

cat <<EOF

導入が完了しました。現在のターミナルで RRS Server を使うには、次を実行してください。

export JAVA_HOME="$JDK_HOME"
export PATH="\$JAVA_HOME/bin:\$PATH"

永続化する場合は、上の 2 行を利用中のシェル設定ファイル（例: ~/.zshrc）に追加してください。
Python の依存関係は、チームのディレクトリで \`uv sync\` を実行して用意します。
EOF
