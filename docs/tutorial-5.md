---
sidebar_position: 5
title: Tutorial 5 — 救助優先度の設計
description: HumanDetector を改良し、仮説・実装・評価の開発サイクルを学ぶ
---

# Tutorial 5 — 救助優先度の設計

Tutorial 4 で実装した `FireBrigadeHumanDetector` を、距離と HP を考慮する選択器へ改良します。観察、仮説、実装、評価を一巡し、戦略を改善する基本的な進め方を身につけましょう。

## 前提条件

- Tutorial 4 の `FireBrigadeHumanDetector` が動作している
- サーバとエージェントを起動できる
- ログビューワで実行結果を確認できる

## 1. 現状を観察する

Tutorial 4 の `calculate()` は、生存していて埋没している市民のうち、最も近い 1 人を選びます。この戦略は単純で分かりやすい一方、HP やダメージを考慮しません。

まず、消防隊専用マップで現在の挙動を確認します。

##### サーバ側ターミナル

```sh
cd WORKING_DIR/rcrs-server/scripts
./start-comprun.sh -m ../maps/tutorial_fire_brigade_only/map -c ../maps/tutorial_fire_brigade_only/config
```

##### エージェント側ターミナル

```sh
cd WORKING_DIR/TEAM_NAME
uv run python main.py
```

ログビューワで、近くの軽症者と遠くの重症者がいる場面を探してください。距離だけで対象を決めることが、常に望ましい救助順序になるかを考えます。

## 2. 優先度の仮説を立てる

ここでは、**近く、かつ HP が低い市民を優先する**という仮説を試します。候補ごとに優先度スコアを計算し、最大の市民を救助対象にします。

マップの GML 座標は m で表され、サーバは内部座標へ 1,000 倍して扱います。したがって `WorldInfo.get_distance()` の値は mm として m に換算します。

```text
distance_m = distance_mm / 1000
priority = 1 / (distance_m / 100 + 1) × 1 / (hp + 1)
```

この式では、距離が短いほど、また HP が低いほど優先度が高くなります。`+ 1` は 0 除算を防ぐためのものです。

:::note

この式は唯一の正解ではありません。距離と HP のどちらを重視するかは、マップ、部隊数、目標とする評価指標によって変わります。とくに、この式は移動経路、埋没度、他部隊との連携を直接は扱いません。まずは比較可能な仮説として実装し、結果を確認してください。

:::

## 3. 優先度による対象選択を実装する

`src/TEAM_NAME/module/complex/fire_brigade_human_detector.py` の `calculate()` を置き換えます。

### 演習

次の処理を自分で実装してください。

1. 自分と各候補市民の距離を取得する
2. 市民の HP を取得する
3. 優先度を計算する
4. 最も優先度が高い市民を `self._result` に設定する

候補条件は Tutorial 4 と同じです。`Civilian` であり、HP と埋没度がともに 0 より大きい市民だけを対象にします。

### 実装例

<details>
<summary>実装例を開く</summary>

```python
def calculate(self) -> HumanDetector:
  me: EntityID = self._agent_info.get_entity_id()
  civilians: list[Entity] = self._world_info.get_entities_of_types([Civilian])

  highest_priority_civilian: EntityID | None = None
  highest_priority: float | None = None

  for civilian in civilians:
    if not isinstance(civilian, Civilian):
      continue
    hp = civilian.get_hp()
    if hp is None or hp <= 0:
      continue

    buriedness = civilian.get_buriedness()
    if buriedness is None or buriedness <= 0:
      continue

    position = civilian.get_position()
    if position is None:
      continue

    distance_mm = self._world_info.get_distance(me, position)
    distance_m = distance_mm / 1000.0
    priority = (1.0 / (distance_m / 100.0 + 1.0)) * (1.0 / (hp + 1.0))

    if highest_priority is None or priority > highest_priority:
      highest_priority_civilian = civilian.get_entity_id()
      highest_priority = priority

  self._result = highest_priority_civilian
  self._logger.info(f"Target: {self._result}, Priority: {highest_priority}")
  return self
```

ここでも距離の終点には市民自身ではなく、`get_position()` で得た所在 Area を使います。通信で存在だけを知り、所在が未確定の市民は `position is None` として除外します。

</details>

距離だけで選んでいた実装との違いは、比較対象です。以前は最小距離を探しましたが、今回は最大優先度を探します。

```python
# 以前: 最小距離を選ぶ
if nearest_distance is None or distance < nearest_distance:
    ...

# 今回: 最大優先度を選ぶ
if highest_priority is None or priority > highest_priority:
    ...
```

## 4. 実行して検証する

実装を保存したら、再度サーバとエージェントを起動します。

##### サーバ側ターミナル

```sh
cd WORKING_DIR/rcrs-server/scripts
./start-comprun.sh -m ../maps/tutorial_fire_brigade_only/map -c ../maps/tutorial_fire_brigade_only/config
```

##### エージェント側ターミナル

```sh
cd WORKING_DIR/TEAM_NAME
uv run python main.py
```

次の観点で確認してください。

- `Target` と `Priority` がログに出力されるか
- 同じ候補群で、距離だけの場合と対象が変わるか
- ログに表示された距離と HP から、優先度の大小を説明できるか
- ログビューワ上で、選んだ市民へ消防隊が向かうか

ログビューワは Tutorial 4 の手順で起動できます。

```sh
cd WORKING_DIR/rcrs-server
./gradlew logViewer --args="'-c' 'config/logviewer.cfg' 'logs/log/rescue.log.7z'"
```

## 5. 結果を比較する

結果を次の表に記録します。「改善した」と判断する前に、同じマップと条件で複数回比較してください。

| 観点 | 距離のみ | 距離と HP |
| --- | --- | --- |
| 対象の選び方 | 最も近い市民 | 優先度が最大の市民 |
| 重症者への配慮 | しない | HP を通じて行う |
| 観察する結果 | 救助順序、救助完了時刻、最終スコア | 救助順序、救助完了時刻、最終スコア |

## 6. 次の仮説を試す

実装が動いたら、1 つずつ変更して比較します。

- 距離と HP の重みを変える
- `get_damage()` を優先度に加える
- `get_buriedness()` を加え、救助に必要な時間を見積もる
- 遠すぎる候補を除外する
- 優先度計算をメソッドに切り出し、テストしやすくする

```python
def calculate_priority(self, distance_mm: float, hp: int) -> float:
    distance_m = distance_mm / 1000.0
    return (1.0 / (distance_m / 100.0 + 1.0)) * (1.0 / (hp + 1.0))
```

## まとめ

この章では、距離のみの対象選択を、距離と HP に基づく優先度選択へ変更しました。実装の改善は、次のサイクルで進めます。

1. 現状を観察する
2. 仮説を立てる
3. 最小限の変更を実装する
4. 同じ条件で実行・比較する
5. 結果を基に次の仮説を立てる

このサイクルを、ほかの選択器やチーム全体の戦略にも適用してみましょう。

## 参考資料

- [GMLCoordinates.java](https://github.com/roborescue/rcrs-server/blob/master/modules/maps/src/maps/gml/GMLCoordinates.java)
- [GMLWorldModelCreator.java](https://github.com/roborescue/rcrs-server/blob/master/modules/gis2/src/gis2/GMLWorldModelCreator.java)
