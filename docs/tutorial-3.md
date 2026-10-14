---
sidebar_position: 3
title: Tutorial 3 — 動作原理とモジュール
description: 生成されたエージェントチームの設定とコードを対応付け、変更するモジュールを選べるようにする
---

import useBaseUrl from '@docusaurus/useBaseUrl';

# Tutorial 3 — 動作原理とモジュール

この章では、Tutorial 2 で作成したチームの設定と雛形コードを読みます。目標は、戦略を変えたいときに「どのモジュールを変えるべきか」「設定ファイルのどこを直すべきか」を判断できるようになることです。

## この章の完了条件

- `module.yaml` から、消防隊が使うモジュールをたどれる
- `HumanDetector`、`Search`、`ExtendAction` の役割の違いを説明できる
- `ModuleManager` が取得するサブモジュールと設定の対応を説明できる
- 自作モジュールを登録する手順を把握している

以降の `TEAM_NAME` は、Tutorial 2 で作成したチーム名に置き換えてください。

## エージェントは 1 ステップで何をするか

RCRS のエージェントは、各シミュレーションステップで次の処理を繰り返します。

1. 知覚と通信で得た情報を受け取り、内部の世界情報を更新する
2. 行動対象と、対象に対して行うアクションを決める
3. 救助・搬送・瓦礫除去・移動のいずれか 1 つを実行する

<figure className="doc-figure">
  <a href={useBaseUrl('/img/tutorial/tutorial-3/agent-operation-principle.png')} target="_blank" rel="noopener">
    <img src={useBaseUrl('/img/tutorial/tutorial-3/agent-operation-principle.png')} alt="エージェントの動作原理" />
  </a>
  <figcaption>知覚・判断・行動を 1 ステップごとに繰り返します。</figcaption>
</figure>

たとえば消防隊は、埋没した市民を対象として選び、対象の位置や状態に応じて移動または救助を行います。移動と救助を同じステップに同時実行することはできません。

## まず雛形の全体像を見る

チームの主要なファイルは次の 3 つです。

```text
TEAM_NAME
├── config
│   ├── launcher.yaml       # 起動するエージェントの設定
│   └── module.yaml         # 使用するモジュールの対応表
├── main.py                 # エージェントを起動する入口
└── src
    └── TEAM_NAME
        └── module
            └── complex
                ├── sample_human_detector.py
                ├── sample_road_detector.py
                └── sample_search.py
```

戦略を変更するときの基本的な流れは、次のとおりです。

```text
module.yaml で役割とクラスを対応付ける
        ↓
対応する Python クラスが対象・経路などを決める
        ↓
Tactics がその結果を使って、実行する Action を決める
```

`main.py` を書き換えて毎ステップの制御を書くのではなく、通常は `src/` 以下のモジュールを実装し、`module.yaml` で差し替えます。

## `module.yaml` を読む

`config/module.yaml` は、役割を表すキーと、実際に使う Python クラスの import パスを対応付けるファイルです。まず、生成直後の雛形から、消防隊に関係する部分を見てください。

```yaml title="config/module.yaml（抜粋）"
DefaultTacticsFireBrigade:
  HumanDetector: src.TEAM_NAME.module.complex.sample_human_detector.SampleHumanDetector
  Search: src.TEAM_NAME.module.complex.sample_search.SampleSearch
  ExtendActionRescue: adf_core_python.implement.action.default_extend_action_rescue.DefaultExtendActionRescue
  ExtendActionMove: adf_core_python.implement.action.default_extend_action_move.DefaultExtendActionMove
  CommandExecutorFire: adf_core_python.implement.centralized.default_command_executor_fire.DefaultCommandExecutorFire
  CommandExecutorScout: adf_core_python.implement.centralized.default_command_executor_scout.DefaultCommandExecutorScout

SampleHumanDetector:
  Clustering: adf_core_python.implement.module.algorithm.k_means_clustering.KMeansClustering

SampleSearch:
  PathPlanning: adf_core_python.implement.module.algorithm.a_star_path_planning.AStarPathPlanning
  Clustering: adf_core_python.implement.module.algorithm.k_means_clustering.KMeansClustering
```

実際のファイルでは `TEAM_NAME` の箇所にチーム名が入ります。たとえばチーム名が `sample` なら、`src.sample.module...` です。

この設定は、次の関係を表します。

```text
DefaultTacticsFireBrigade
├── HumanDetector → SampleHumanDetector
│   └── Clustering → KMeansClustering
├── Search → SampleSearch
│   ├── PathPlanning → AStarPathPlanning
│   └── Clustering → KMeansClustering
├── ExtendActionRescue → 標準の救助・移動判断
└── ExtendActionMove → 標準の移動判断
```

上段の `DefaultTacticsFireBrigade` は、消防隊の意思決定の順序を管理します。下段の `SampleHumanDetector` や `SampleSearch` は、その中から呼び出される実装です。つまり、対象を選ぶ戦略を変えたい場合は `HumanDetector`、探索先を変えたい場合は `Search` を変更します。

:::caution キー名は変えない

`HumanDetector` や `Search` のように `Tactics` から参照されるキーの名前は変更しません。自作クラスへ切り替えるときは、値の import パスだけを置き換えます。同じキーを複数回書くと、最後の値で上書きされます。

:::

## 消防隊の意思決定をたどる

標準の消防隊用 `Tactics` は、概ね次の順序で行動を選びます。

1. 司令所からの命令があれば、対応する `CommandExecutor` で実行する
2. `HumanDetector` が救助対象を返せば、`ExtendActionRescue` で救助または移動を決める
3. 対象がなければ、`Search` が探索先を返し、`ExtendActionMove` で移動を決める
4. いずれも決められなければ待機する

<figure className="doc-figure">
  <a href={useBaseUrl('/img/tutorial/tutorial-3/agent-decision-flow.png')} target="_blank" rel="noopener">
    <img src={useBaseUrl('/img/tutorial/tutorial-3/agent-decision-flow.png')} alt="消防隊の意思決定フロー" />
  </a>
  <figcaption>標準の意思決定では、命令、救助、探索の順に行動を検討します。</figcaption>
</figure>

ここで重要なのは、**対象を選ぶこと**と、**実行するアクションを選ぶこと**を分けている点です。

| 変更したいこと | 主に確認・実装するモジュール |
| --- | --- |
| どの埋没市民を救助するか | `HumanDetector` |
| どの道路を啓開するか | `RoadDetector` |
| 次にどの建物・道路を探索するか | `Search` |
| 対象へどう移動するか、救助を実行するか | `ExtendActionMove`、`ExtendActionRescue` など |
| 経路の計算方法 | `PathPlanning` |
| 担当領域の分け方 | `Clustering` |

Tutorial 4 では `HumanDetector` を実装します。救助アクションそのものは標準の `ExtendActionRescue` を使うため、まずは「誰を対象にするか」に集中できます。

## `SampleHumanDetector` を読む

`src/TEAM_NAME/module/complex/sample_human_detector.py` を開いてください。このクラスは `HumanDetector` を継承し、最終的に救助対象の `EntityID` を返します。

```python title="sample_human_detector.py（要点）"
class SampleHumanDetector(HumanDetector):
    def __init__(self, ..., module_manager: ModuleManager, ...) -> None:
        ...
        self._clustering = module_manager.get_module(
            "SampleHumanDetector.Clustering",
            "adf_core_python.implement.module.algorithm.k_means_clustering.KMeansClustering",
        )
        self.register_sub_module(self._clustering)
        self._result = None

    def calculate(self) -> HumanDetector:
        self._result = self._select_target()
        return self

    def get_target_entity_id(self) -> Optional[EntityID]:
        return self._result
```

実際の雛形には、すでに対象が有効かを確認する処理や、担当クラスタ内の市民を優先する処理も含まれています。最初は次の 3 点だけを追ってください。

1. `get_module()` の最初の引数 `SampleHumanDetector.Clustering` は、`module.yaml` の同名キーを参照する。
2. `register_sub_module()` は、親モジュールのライフサイクル呼び出しをクラスタリングへ渡すために登録する。
3. `calculate()` は対象の `EntityID` を `self._result` に保存し、`get_target_entity_id()` がその値を返す。

`get_module()` の第 2 引数は、`module.yaml` に設定がない場合に使う標準実装です。設定を変更する場合は、通常、第 1 引数と同じキーを `module.yaml` に書きます。

```yaml title="config/module.yaml"
SampleHumanDetector:
  Clustering: adf_core_python.implement.module.algorithm.k_means_clustering.KMeansClustering
```

`register_sub_module()` を呼ぶと、親モジュールから子モジュールへ `precompute()`、`resume()`、`prepare()`、`update_info()` が順に渡されます。ただし、登録しただけで毎ステップ再計算されるわけではありません。雛形で使う `KMeansClustering` は、事前計算または最初の `prepare()` でクラスタを作り、その結果を使います。自作モジュールから `PathPlanning` や `Clustering` を使うときは、取得後に登録してください。

## 登録によって何が変わるか

次章では、消防隊用の `FireBrigadeHumanDetector` を作成し、`module.yaml` の `HumanDetector` をそのクラスへ差し替えます。ここでは設定の意味だけを確認します。実際の複製・コードの置換・起動確認は Tutorial 4 で行います。

```yaml title="config/module.yaml"
DefaultTacticsFireBrigade:
  HumanDetector: src.TEAM_NAME.module.complex.fire_brigade_human_detector.FireBrigadeHumanDetector
```

この変更で、消防隊が対象を選ぶ場面だけが自作実装に切り替わります。`ExtendActionRescue`、`Search`、`PathPlanning` は引き続き既存の設定を使います。1 回の変更範囲を小さく保てるため、動作が変わった理由を追いやすくなります。

## モジュール構成を意識して開発する

モジュールを増やす前に、変更したい判断を 1 文で説明してから対応する役割を選びます。

| 目的 | 最初に変更を検討する場所 |
| --- | --- |
| 「近い市民ではなく、危険度が高い市民を救助する」 | `HumanDetector` |
| 「未探索の建物を優先して巡回する」 | `Search` |
| 「瓦礫を避けた経路を選ぶ」 | `PathPlanning` |
| 「エージェントごとに担当地区を分ける」 | `Clustering` |

主モジュールが複雑になったら、経路計算や担当領域の計算をサブモジュールとして分けます。ただし、最初から独自の `PathPlanning` や `Clustering` を作る必要はありません。標準実装を使い、戦略の中心となる対象選択から小さく変更してください。

## 参考資料

- [Agent Simulation Competition Rules: RoboCup 2025](https://github.com/roborescue/rcrs-rules/blob/master/rcrs-agent-rules.adoc)
- [adf-core-python — Agent Control](https://adf-python.github.io/adf-core-python/en/tutorial/agent/agent_control.html)
- [adf-core-python の標準実装](https://github.com/adf-python/adf-core-python/tree/main/src/adf_core_python/implement)
