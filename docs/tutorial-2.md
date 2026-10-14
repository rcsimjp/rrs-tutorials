---
sidebar_position: 2
title: Tutorial 2 — 環境構築
description: RCRS の開発環境を準備し、シミュレーションを実行する
---

import useBaseUrl from '@docusaurus/useBaseUrl';

# Tutorial 2 — 環境構築

この章では、RCRS Server と Python agent を準備し、シミュレーションを起動・停止します。

## この章の完了条件

- `rcrs-server` をビルドできる
- 新しいエージェントチームを作成できる
- サーバとエージェントを別々のターミナルで起動できる

## 事前準備

この手順は Bash が使える macOS、Linux、Windows の WSL2 を対象とします。次のツールが利用できることを確認してください。すでに導入済みであれば、再インストールは不要です。環境構築の詳細は[開発環境を整える](./development-environment.md)を参照してください。

- Git
- OpenJDK 21
- Python 3.13 以上
- [uv](https://docs.astral.sh/uv/)
- curl
- unzip

次のコマンドで、導入済みか確認できます。

```sh
git --version
java -version
python --version
uv --version
```

:::note

必要なツールがない場合は、利用している OS の公式パッケージ管理方法で導入してください。Java は OpenJDK 21、Python は 3.13 以上を使用します。Python パッケージの管理には `pip` ではなく `uv` を使用します。これは現行の `rcrs-server` と `adf-core-python` の導入手順に合わせたものです。

:::

:::tip ターミナルを 2 つ用意する

以降では、サーバを実行する端末を**サーバ側ターミナル**、エージェントを実行する端末を**エージェント側ターミナル**と呼びます。両方を開いておいてください。

:::

## 環境を準備する

### 1. 作業用ディレクトリを作成する

RCRS 関連のファイルを置く任意のディレクトリを作成します。以降、このディレクトリを `WORKING_DIR` と表記します。

##### サーバ側ターミナル

```sh
mkdir WORKING_DIR
cd WORKING_DIR
```

### 2. サーバを準備する

サーバのソースコードを取得します。

##### サーバ側ターミナル

```sh
git clone https://github.com/roborescue/rcrs-server.git
cd rcrs-server
```

`WORKING_DIR/rcrs-server` が作成されたことを確認してください。

この章では、RCRS Server に同梱された公式のテストマップ `maps/test` を使用します。追加のマップをダウンロードする必要はありません。

続けてサーバをビルドします。初回は時間がかかることがあります。

##### サーバ側ターミナル

```sh
./gradlew completeBuild
```

`BUILD SUCCESSFUL` と表示されれば成功です。出力例の `...` は省略した行、`?` は環境により変わる値を表します。

```text
> Task :rcrs-server:compileJava
...
BUILD SUCCESSFUL in ?s
```

### 3. エージェントチームを作成する

エージェント側ターミナルで `WORKING_DIR` に移動し、雛形作成コマンドを実行します。`uvx` は一度だけコマンドを実行するため、グローバル環境を汚しません。

##### エージェント側ターミナル

```sh
cd WORKING_DIR
uvx --from git+https://github.com/adf-python/adf-core-python.git adf-core-python
```

チーム名を尋ねられたら、任意の名前を入力してください。以降、この名前を `TEAM_NAME` と表記します。実行後、`WORKING_DIR/TEAM_NAME` に次のような雛形が作成されます。

```text
TEAM_NAME
├── config
│   ├── development.json
│   ├── launcher.yaml
│   └── module.yaml
├── main.py
└── src
    └── TEAM_NAME
        ├── __init__.py
        └── module
            ├── __init__.py
            └── complex
                ├── __init__.py
                ├── sample_human_detector.py
                ├── sample_road_detector.py
            └── sample_search.py
```

続けて、チーム専用の仮想環境と依存関係を作成します。`uv.lock` は依存パッケージの実体を記録するファイルです。チームのリポジトリに必ずコミットしてください。

```sh
cd TEAM_NAME
uv init --bare --python 3.13
uv python pin 3.13
uv add git+https://github.com/adf-python/rcrs-core-python --tag v0.2.3
uv add "adf_core_python @ git+https://github.com/adf-python/adf-core-python.git"
uv add --dev ruff pytest
```

`uv python pin 3.13` は `.python-version` を作成し、`uv run` で使う Python を 3.13 系に固定します。

作成された `pyproject.toml` に、次を追記します。Ruff の設定をチームで共有し、Python 3.13 を対象に静的解析と整形を行います。

```toml title="pyproject.toml"
[tool.ruff]
line-length = 88
indent-width = 2
target-version = "py313"

[tool.ruff.lint]
select = ["E4", "E7", "E9", "F", "N8"]
```

これで、依存関係の同期と品質確認は次のコマンドで行えます。詳細は[開発環境を整える](./development-environment.md)を参照してください。

```sh
uv sync
uv run ruff check .
uv run ruff format --check .
```

## シミュレーションを実行する

サーバ、次にエージェントの順で起動します。

### 1. サーバを起動する

##### サーバ側ターミナル

```sh
cd WORKING_DIR/rcrs-server/scripts
./start-comprun.sh -m ../maps/test/map -c ../maps/test/config
```

起動に成功すると、次の 5 つのウィンドウが開きます。

<figure className="doc-figure">
  <a href={useBaseUrl('/img/tutorial/tutorial-2/server-startup-windows.png')} target="_blank" rel="noopener">
    <img src={useBaseUrl('/img/tutorial/tutorial-2/server-startup-windows.png')} alt="サーバ起動時に開くウィンドウ" />
  </a>
  <figcaption>サーバ起動時に開く 5 つのウィンドウ。</figcaption>
</figure>

- **kernelGUI**: シミュレーションの設定と進行状況
- **Traffic simulator**: エージェントの移動状況
- **Collapse simulator**: 建物の倒壊と瓦礫の発生状況
- **Misk simulator**: 体力、埋没度、ダメージの原因
- **Viewer**: シミュレーションの表示

### 2. エージェントを起動する

##### エージェント側ターミナル

```sh
cd WORKING_DIR/TEAM_NAME
uv run python main.py
```

Viewer 内のエージェントが動き始めれば、サーバへの接続に成功しています。

## シミュレーションを停止する

シミュレーションが終了するとエージェントは停止します。サーバは起動したままなので、サーバ側ターミナルで次を実行してください。

```sh
./kill.sh
```

5 つのウィンドウがすべて閉じれば停止完了です。

途中で止める場合は、エージェント側ターミナルで `Ctrl+C` を押してエージェントを停止します。続けてサーバ側ターミナルで `Ctrl+C` を押し、`./kill.sh` を実行してください。

## 参考資料

- [rcrs-server README](https://github.com/roborescue/rcrs-server/blob/master/README.adoc)
- [adf-core-python — 環境構築](https://adf-python.github.io/adf-core-python/ja/install/environment/environment.html)
- [adf-core-python — インストール](https://adf-python.github.io/adf-core-python/ja/install/install/install.html)
- [uv — Documentation](https://docs.astral.sh/uv/)
- [Ruff — Documentation](https://docs.astral.sh/ruff/)
