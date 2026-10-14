---
title: 開発環境を整える
description: uv、Ruff、pytest を用いて RCRS agent 開発をチームで再現可能にする
---

# 開発環境を整える

エージェントチームのリポジトリでは、Python の依存関係を `uv` で固定し、Ruff で基本的な静的解析と整形を行います。これにより、各自の環境差を小さくし、レビュー前に機械的に見つけられる問題を減らせます。

このページは、[Tutorial 2 — 環境構築](./tutorial-2.md)で作成した `TEAM_NAME` ディレクトリを対象にします。

## 役割分担

| ツール | 役割 |
| --- | --- |
| `uv` | Python のバージョン、仮想環境、依存関係、ロックファイルを管理する |
| Ruff | 構文上の問題や未使用の変数を検出し、コードを整形する。ADF Python の雛形に合わせて 2 スペースで整形する |
| pytest | モジュールの振る舞いを確認するテストを実行する |

Nix を利用する場合も、RCRS agent チームの Python 依存関係は `uv` に任せます。Nix は Java、Python、`uv` のような開発ツールを揃えるために使い、`uv.lock` はチーム固有のパッケージを揃えるために使う、という分担です。

## 開発ツールを用意する

以下は導入方法の一例です。チーム全員が同じ方法を使う必要はありません。必要なツールのバージョンを揃え、各チームの依存関係を `uv.lock` で共有できれば十分です。

### Nix

このリポジトリのルートで次を実行すると、RCRS agent 開発用のシェルを開けます。Java 21、Python 3.13、`uv`、Ruff、RCRS Core が利用する空間インデックス用ライブラリが含まれます。

```sh
nix develop .#rcrs
```

### macOS（Homebrew）

このリポジトリをクローン済みであれば、次の補助スクリプトで Git、Java 21、Python 3.13、`uv` を導入できます。

```sh
./resources/environment/setup-macos.sh
```

Java のパス設定は環境により異なるため、スクリプトの最後に表示される `JAVA_HOME` の設定を、案内に従ってシェル設定ファイルへ追加してください。

### WSL（Ubuntu）

Ubuntu 系の WSL では、次の補助スクリプトを使えます。APT でシステムパッケージを導入するため、途中で管理者パスワードを求めます。`uv` は公式インストーラから `~/.local/bin` へ導入します。

```sh
./resources/environment/setup-wsl-ubuntu.sh
```

スクリプトは Ubuntu 24.04 以降を想定しています。別のディストリビューションやバージョンでは、OS のパッケージ管理方法に従って Java 21、Git、curl、unzip、`libspatialindex` 相当を用意してください。

## 最初にコミットするファイル

チームを作成したら、次のファイルを Git に追加します。

- `pyproject.toml`: Python のバージョン、依存関係、ツール設定
- `.python-version`: `uv` が使用する Python のバージョン
- `uv.lock`: 実際に利用する依存パッケージの組合せ
- `src/`: エージェントの実装
- `tests/`: テスト

`.venv/` は各自のローカル環境なので、Git に追加しません。リポジトリの `.gitignore` に次の 2 行がなければ追加してください。

```gitignore title=".gitignore"
.venv/
.ruff_cache/
```

## 日常的な操作

リポジトリを取得した直後、または `pyproject.toml` や `uv.lock` が更新されたときは、次を実行します。

```sh
uv sync
```

実装を変更したら、コミット前に次を実行します。

```sh
uv run ruff check .
uv run ruff format --check .
```

自動修正できる問題は、次で反映できます。修正後は差分を確認してください。

```sh
uv run ruff check . --fix
uv run ruff format .
```

## 参考資料

- [uv Documentation](https://docs.astral.sh/uv/)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [pytest Documentation](https://docs.pytest.org/)
- [adf-core-python の pyproject.toml](https://github.com/adf-python/adf-core-python/blob/main/pyproject.toml)
