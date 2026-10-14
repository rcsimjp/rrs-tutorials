---
title: 開発リソース
description: RoboCup Rescue Simulation の公式リポジトリ、開発基盤、ツール、コミュニティへのリンク
---

# 開発リソース

RoboCup Rescue Simulation（RCRS）の開発・参加で参照するリンクを集めます。競技の要件は年度ごとに変わるため、参加前には必ず公式ルールを確認してください。

## まず参照するもの

| リンク | 用途 |
| --- | --- |
| [RoboCup Rescue Simulation 公式サイト](https://rescuesim.robocup.org/) | 大会、研究、各種リソースの入口 |
| [RoboCupRescue GitHub Organization](https://github.com/roborescue) | 公式リポジトリの一覧 |
| [RCRS Server](https://github.com/roborescue/rcrs-server) | シミュレータ、地図、ログ、付属ツール |
| [RCRS Rules](https://github.com/roborescue/rcrs-rules) | 公開済みの競技規則。参加年と版を確認する |

## 公式の開発基盤

| リンク | 用途 |
| --- | --- |
| [Open Source Code](https://rescuesim.robocup.org/resources/open-source-code/) | 公式サイトからたどれる公開ソースの一覧 |
| [RCRS Server](https://github.com/roborescue/rcrs-server) | サーバのビルドと実行。`gmlEditor`、`scenarioEditor`、`logViewer`、`osm2gml` などのツールも含む |
| [Server Manual](https://github.com/roborescue/rcrs-server/blob/master/docs/rcrs-server/rcrs-server-manual.adoc) | サーバ、地図、シナリオ、ログの仕組みを調べるためのマニュアル |
| [RCRS Rules](https://github.com/roborescue/rcrs-rules) | Agent Simulation を含む競技規約。大会向けの実装・提出前に確認する |
| [RCRS Templates](https://github.com/roborescue/rcrs-templates) | Team Description Paper（TDP）や発表用テンプレート |

## エージェント開発

### Java

| リンク | 用途 |
| --- | --- |
| [ADF Core (Java)](https://github.com/roborescue/adf-core-java) | 公式の Agent Development Framework 本体 |
| [ADF Sample Agent (Java)](https://github.com/roborescue/adf-sample-agent-java) | ADF を用いる Java のサンプルチーム |
| [RCRS Sample Agent (Java)](https://github.com/roborescue/rcrs-sample-agent-java) | RCRS 向け Java サンプルエージェント |

### Python

このチュートリアルでは、Python 開発コミュニティが保守する ADF 実装を利用します。公式の Python リポジトリも参照できますが、実際にこのチュートリアルを進める場合は、まず以下の 3 つを参照してください。

| リンク | 用途 |
| --- | --- |
| [ADF Core Python](https://github.com/adf-python/adf-core-python) | Python 向け ADF の実装 |
| [ADF Core Python Documentation](https://adf-python.github.io/adf-core-python/ja/) | API と実装方法のドキュメント |
| [RCRS Core Python](https://github.com/adf-python/rcrs-core-python) | RCRS の通信・エンティティを扱う Python クライアント基盤 |

## 地図・シナリオ・ログ

これらは RCRS Server に同梱されています。地図やシナリオを新たに用意する場合は、Server Manual と合わせて利用してください。

| ツール | 用途 |
| --- | --- |
| `gmlEditor` | GML 形式の地図を編集する |
| `scenarioEditor` | シナリオを作成・編集する |
| `randomScenario` | ランダムなシナリオを生成する |
| `logViewer` | サーバが出力したログを確認する |
| `osm2gml` | OpenStreetMap のデータを GML 地図へ変換する |
| [SimScope](https://github.com/shima004/SimScope) | コミュニティ製 RCRS ビューア。ログの再生に加え、Docker 起動時はカーネルへリアルタイム接続できる |
| [ringo-viewer](https://github.com/ringo-ringo-ringo/ringo-viewer) | ログをブラウザで確認するためのコミュニティ製ビューア |


## 研究・相談先

| リンク | 用途 |
| --- | --- |
| [Research](https://rescuesim.robocup.org/research/) | RCRS で扱われてきた研究テーマの概要 |
| [Agent Simulation Publications](https://rescuesim.robocup.org/research/publications/agent-competition/) | Agent Simulation の論文・TDP 等のアーカイブ |
| [Mailing Lists](https://rescuesim.robocup.org/resources/mailing-lists/) | 公式メーリングリスト。競技運営や技術的な問い合わせ先 |
| [RCRS Server Issues](https://github.com/roborescue/rcrs-server/issues) | サーバの不具合・改善提案の確認と報告 |
