---
sidebar_position: 1
title: Tutorial 1 — 導入
description: RoboCup Rescue Simulation の全体像、救助活動、評価指標を理解する
---

import useBaseUrl from '@docusaurus/useBaseUrl';

# Tutorial 1 — 導入

RoboCup Rescue Simulation（RCRS）は、地震後の都市と災害救助部隊の活動を再現するマルチエージェントシミュレーションです。この章では、以降の実装・評価に必要となる基本概念を確認します。

## この章で学ぶこと

- RCRS における災害、救助部隊、シミュレーションの流れ
- 都市を構成する主なエンティティ
- スコアと戦略の関係

## RoboCup Rescue Simulation とは

RCRS では、地震後の都市で起こる建物の倒壊、道路閉塞、市民の負傷・埋没と、救助部隊による対応をシミュレーションします。開発者は、限られた情報のもとで行動する救助エージェントの戦略を実装し、救助成果を比較します。

RCRS は、動的で部分的にしか観測できない環境で、複数の自律エージェントが協調するマルチエージェントシステムです。タスク割り当て、探索、情報共有、経路探索、チーム形成は、いずれも RCRS が扱う代表的な研究課題です。

## RCRSが生まれた背景

RCRS は、1995 年の阪神・淡路大震災をきっかけに始まった教育・研究プロジェクトです。大規模災害では、被害状況が不完全なまま、多数の組織が時間制約の下で判断しなければなりません。RCRS は、この難しさを共有可能なシミュレータと評価課題に置き換え、救助計画を比較・議論できる場をつくることを目的としてきました。

RoboCup では 2000 年にデモ競技として始まり、2001 年から正式競技になりました。RoboCup Soccerで培われた自律エージェントと協調の研究を、より複雑な災害救助へ広げた位置付けです。

## 救助活動の基本

地震後の被害と、それに対応する部隊の関係を次の図に示します。

<figure className="doc-figure">
  <a href={useBaseUrl('/img/tutorial/tutorial-1/disaster-and-rescue-force-overview.png')} target="_blank" rel="noopener">
    <img src={useBaseUrl('/img/tutorial/tutorial-1/disaster-and-rescue-force-overview.png')} alt="被害、救助部隊、救助活動の関係" />
  </a>
  <figcaption>救助活動では、部隊ごとの役割をつなげて被害へ対応します。</figcaption>
</figure>

RCRS では、地震後の都市で次のような被害が発生します。

| 被害 | 影響 |
| --- | --- |
| 道路閉塞 | 瓦礫が道路を塞ぎ、部隊と市民の移動を妨げます。 |
| 市民の埋没 | 倒壊した建物の下敷きになり、市民は移動できなくなります。 |
| 市民の負傷 | HP が時間とともに減少し、救助が遅れると死亡します。 |

この被害に対応するため、RCRS では 3 種類の救助部隊が活動します。3 種類の救助部隊は役割が異なります。1 つの部隊が他部隊の役割を代替することはできないため、連携が重要です。

| 部隊 | 主な役割 |
| --- | --- |
| 土木隊（Police Force） | 瓦礫を除去し、道路を通行可能にします。 |
| 消防隊（Fire Brigade） | 埋没した市民やエージェントを救助します。 |
| 救急隊（Ambulance Team） | 救助された負傷市民を避難所へ搬送します。 |

## シミュレーションの流れ

RCRS はステップ単位で進む離散シミュレーションです。各ステップで、環境が更新され、エージェントは知覚・判断・行動を 1 回行います。終了ステップはシナリオ設定で決まり、終了後に救助成果が評価されます。

| ステップ | 状態 |
| --- | --- |
| 開始時 | シナリオに定義された地図、部隊、市民を読み込む |
| 各ステップ | 環境を更新し、各エージェントが 1 つの行動を選ぶ |
| 終了時 | 設定された終了ステップに達すると、スコアを算出する |

## 都市を構成する要素

### 都市マップ

RCRS の都市マップは、実在する都市を基に作られます。図は愛知県名古屋市栄地区をモデルにした `sakae` マップと、対応する OpenStreetMap です。また、RCRS では、都市マップの道路や建物の形状を OpenStreetMap から自動生成する機能も提供しています。

<div className="doc-media-grid">
  <figure>
    <a href={useBaseUrl('/img/tutorial/tutorial-1/sakae-city-map.png')} target="_blank" rel="noopener">
      <img src={useBaseUrl('/img/tutorial/tutorial-1/sakae-city-map.png')} alt="RCRS の都市マップ（sakae）" />
    </a>
    <figcaption>RCRS の都市マップ（sakae）</figcaption>
  </figure>
  <figure>
    <a href={useBaseUrl('/img/tutorial/tutorial-1/sakae-openstreetmap.png')} target="_blank" rel="noopener">
      <img src={useBaseUrl('/img/tutorial/tutorial-1/sakae-openstreetmap.png')} alt="対応する OpenStreetMap" />
    </a>
    <figcaption>対応する OpenStreetMap</figcaption>
  </figure>
</div>

マップと後述するエンティティの構成は、災害シナリオとして提供されます。次の動画は、アイントホーフェンの一地区におけるシミュレーションの記録です。

<figure className="doc-figure">
  <video controls loop src={useBaseUrl('/img/tutorial/tutorial-1/score-transition-simulation.webm')}></video>
  <figcaption>シミュレーションの進行とスコアの遷移</figcaption>
</figure>

ここで紹介する道路、建物、市民、救助部隊などは、すべて**エンティティ**です。エンティティは、シミュレーション空間に存在するオブジェクトの総称です。

### 災害に関するエンティティ

| 表現 | 名称 | 概要 |
| --- | --- | --- |
| ![建物の被害度](/img/tutorial/tutorial-1/building-damage-level-1.png)<br />↓<br />![建物の被害度](/img/tutorial/tutorial-1/building-damage-level-2.png)<br />↓<br />![建物の被害度](/img/tutorial/tutorial-1/building-damage-level-3.png) | 建物 | 色の濃さは倒壊の度合いを表します。建物内にいるエージェントは、倒壊時に埋没することがあります。 |
| ![道路](/img/tutorial/tutorial-1/road.png) | 道路 | エージェントが移動する多角形の領域です。瓦礫により通行不能になることがあります。 |
| ![瓦礫](/img/tutorial/tutorial-1/road-blockade.png) | 瓦礫 | 道路上の通行を妨げます。土木隊が撤去するまで通行できません。 |
| ![市民の体力状態](/img/tutorial/tutorial-1/civilian-health-level-1.png)<br />↓<br />![市民の体力状態](/img/tutorial/tutorial-1/civilian-health-level-2.png)<br />↓<br />![市民の体力状態](/img/tutorial/tutorial-1/civilian-health-level-3.png) | 市民 | 倒壊により負傷・埋没することがあります。体力が減るにつれて表示色は暗くなり、体力が 0 になると死亡します。 |

### 災害救助エージェント

救助エージェントも倒壊によりダメージを受けます。死亡または埋没している間は移動できず、行動できる場合も実行できる操作は役割ごとに異なります。

| 表現 | 名称 | 行動 |
| --- | --- | --- |
| <img src={useBaseUrl('/img/tutorial/tutorial-1/police-force-icon.png')} alt="土木隊" /> | 土木隊 | 道路上の瓦礫を撤去します。 |
| <img src={useBaseUrl('/img/tutorial/tutorial-1/fire-brigade-icon.png')} alt="消防隊" /> | 消防隊 | 埋没した市民やエージェントを救助します。 |
| <img src={useBaseUrl('/img/tutorial/tutorial-1/ambulance-team-icon.png')} alt="救急隊" /> | 救急隊 | 負傷市民を避難所へ搬送します。 |

| 表現 | 状態 |
| --- | --- |
| ![土木隊の啓開](/img/tutorial/tutorial-1/police-force-clearing.png) | 土木隊が瓦礫を除去しています。 |
| ![消防隊の救助](/img/tutorial/tutorial-1/fire-brigade-rescuing.png) | 消防隊が救助しています。 |
| ![救急隊の搬入](/img/tutorial/tutorial-1/ambulance-team-loading.png) | 救急隊が市民を搬入しています。 |
| ![救急隊の搬送](/img/tutorial/tutorial-1/ambulance-team-transporting.png) | 救急隊が市民を搬送しています。 |
| ![救急隊の搬出](/img/tutorial/tutorial-1/ambulance-team-unloading.png) | 救急隊が市民を搬出しています。 |

各部隊は 1 ステップに 1 つのアクションだけを実行します。たとえば救急隊は、移動、搬入、搬送、搬出をそれぞれ別のステップで行います。

### 避難所と司令所

| 表現 | 名称 | 概要 |
| --- | --- | --- |
| ![避難所](/img/tutorial/tutorial-1/refuge-icon.png) | 避難所 | 救急隊が負傷市民を搬送する建物です。滞在中はダメージが 0 になり、HP は回復しません。病床数などの容量はシナリオ設定に依存します。 |
| <img src={useBaseUrl('/img/tutorial/tutorial-1/ambulance-centre-icon.png')} width="32" height="32" alt="救急司令所"　/><br /><img src={useBaseUrl('/img/tutorial/tutorial-1/fire-station-icon.png')} width="32" height="32" alt="消防司令所" /><br /><img src={useBaseUrl('/img/tutorial/tutorial-1/police-office-icon.png')} width="32" height="32" alt="土木司令所" /> | 司令所 | 対応する救助部隊を通信を介して統括します。 |

## エージェントの評価

RCRS では、エージェントの行動を評価するために `RSL21ScoreFunction` を使用します。スコアは市民の生存数と残存 HP から計算され、死亡者の増加や HP の低下により減少します。

`スコア = 市民の生存数 × e^(-5 × (1 - 市民の総残存体力 / 市民の総最大体力))`

ここで `e` はネイピア数です。

![スコアの遷移](/img/tutorial/tutorial-1/score-transition-chart.png)

高いスコアを得るには、次の両方が必要です。

- 市民の生存数を維持する
- 負傷市民を早く避難所へ搬送し、残存体力を保つ

スコアは戦略の比較に有用ですが、探索、通信、タスク割り当てなど個別の働きを直接説明する指標ではありません。研究や開発では、目的に応じて追加の評価指標も用意します。

## 戦略による行動の違い

エージェントの戦略は、探索範囲、瓦礫除去の順序、部隊間の連携を変えます。ここでは、同じ地域に部隊を集める**集中救助**と、都市全体へ広げる**分散救助**を比較します。

| 戦略 | 強み | 注意点 |
| --- | --- | --- |
| 集中救助 | 瓦礫除去、救助、搬送の連携を作りやすい | 他地域の発見が遅れることがある |
| 分散救助 | 広い範囲を早く探索できる | 部隊が離れ、救助から搬送までに時間がかかることがある |

以下の動画では、同じステップ範囲の集中救助と分散救助を比較できます。

### ステップ 0–20

<div className="doc-media-grid">
  <figure>
    <video src={useBaseUrl('/img/tutorial/tutorial-1/centralized-strategy-steps-00-20.mov')} controls></video>
    <figcaption>集中救助</figcaption>
  </figure>
  <figure>
    <video src={useBaseUrl('/img/tutorial/tutorial-1/distributed-strategy-steps-00-20.mov')} controls></video>
    <figcaption>分散救助</figcaption>
  </figure>
</div>

### ステップ 30–50

<div className="doc-media-grid">
  <figure>
    <video src={useBaseUrl('/img/tutorial/tutorial-1/centralized-strategy-steps-30-50.mov')} controls></video>
    <figcaption>集中救助</figcaption>
  </figure>
  <figure>
    <video src={useBaseUrl('/img/tutorial/tutorial-1/distributed-strategy-steps-30-50.mov')} controls></video>
    <figcaption>分散救助</figcaption>
  </figure>
</div>

### ステップ 60–80

<div className="doc-media-grid">
  <figure>
    <video src={useBaseUrl('/img/tutorial/tutorial-1/centralized-strategy-steps-60-80.mov')} controls></video>
    <figcaption>集中救助</figcaption>
  </figure>
  <figure>
    <video src={useBaseUrl('/img/tutorial/tutorial-1/distributed-strategy-steps-60-80.mov')} controls></video>
    <figcaption>分散救助</figcaption>
  </figure>
</div>

### 終了時の状態

<div className="doc-media-grid">
  <figure>
    <a href={useBaseUrl('/img/tutorial/tutorial-1/centralized-strategy-final-state.jpg')} target="_blank" rel="noopener">
      <img src={useBaseUrl('/img/tutorial/tutorial-1/centralized-strategy-final-state.jpg')} alt="集中救助の終了時" />
    </a>
    <figcaption>集中救助の終了時</figcaption>
  </figure>
  <figure>
    <a href={useBaseUrl('/img/tutorial/tutorial-1/distributed-strategy-final-state.jpg')} target="_blank" rel="noopener">
      <img src={useBaseUrl('/img/tutorial/tutorial-1/distributed-strategy-final-state.jpg')} alt="分散救助の終了時" />
    </a>
    <figcaption>分散救助の終了時</figcaption>
  </figure>
</div>

戦略には常にトレードオフがあります。以降の章では、対象の選び方や移動方法をモジュールとして実装し、観察と評価を繰り返して改善します。

## 研究としての見どころ

RCRS では、「誰が、どの情報を根拠に、どの対象へ向かうか」を小さな実装変更として試せます。たとえば、次の問いはそのまま研究・開発の出発点になります。

- 部隊を分散させると、発見の早さと救助の確実さはどう変わるか。
- 通信が限られるとき、どの情報を共有すべきか。
- 近い市民と重症の市民のどちらを先に救助すべきか。

このように、RCRS は災害救助の研究課題を、シミュレーションと評価指標に置き換え、戦略の比較・議論を可能にします。

次章からは、RCRS のエージェントを実装するための環境構築と、最初の戦略を作る手順を紹介します。

## 参考文献・資料

- [RoboCup Rescue Simulation — About](https://rescuesim.robocup.org/home/about-robocup-rescue-simulation/)
- [RoboCup Rescue Simulation — Research](https://rescuesim.robocup.org/research/)
- [Agent Simulation Publications](https://rescuesim.robocup.org/research/publications/agent-competition/)
- [2022 Workshop Programme](https://rescuesim.robocup.org/past-events/workshops/2022-workshop/2022-workshop-schedule/)
- [Infrastructure Competition](https://rescuesim.robocup.org/competitions/infrastructure-competition/)
- [Agent Simulation Competition Rules: RoboCup 2025](https://github.com/roborescue/rcrs-rules/blob/master/rcrs-agent-rules.adoc)
- [RCRS Server Manual](https://github.com/roborescue/rcrs-server/blob/master/docs/rcrs-server/rcrs-server-manual.adoc)
- [RSL21ScoreFunction.java](https://github.com/roborescue/rcrs-server/blob/master/modules/standard/src/rescuecore2/standard/score/RSL21ScoreFunction.java)
