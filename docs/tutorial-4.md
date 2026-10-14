---
sidebar_position: 4
title: Tutorial 4 — HumanDetector の実装とログ解析
description: HumanDetector を実装し、エージェント情報の取得とログの確認を学ぶ
---

import useBaseUrl from '@docusaurus/useBaseUrl';

# Tutorial 4 — HumanDetector の実装とログ解析

消防隊が救助対象を選ぶ `HumanDetector` を実装します。あわせて、エージェントが利用できる情報と、ログから動作を検証する方法を確認します。

## この章の完了条件

- `FireBrigadeHumanDetector` を登録して起動できる
- 最も近い埋没市民を選ぶ `calculate()` を実装できる
- ログビューワで実行結果を確認できる

## HumanDetector を準備する

チームの `complex` ディレクトリで、雛形の `HumanDetector` を消防隊用モジュールとして複製します。元の `sample_human_detector.py` は比較用に残します。

```sh
cd WORKING_DIR/TEAM_NAME
cp src/TEAM_NAME/module/complex/sample_human_detector.py \
  src/TEAM_NAME/module/complex/fire_brigade_human_detector.py
```

`fire_brigade_human_detector.py` の内容を次の最小構成に置き換えてください。ここでクラス名を `FireBrigadeHumanDetector` に変更します。最初は自作クラスが実際に読み込まれることだけを確認するため、`calculate()` は対象を選ばず、起動時にログを出します。

```python
from typing import Optional

from rcrscore.entities import EntityID

from adf_core_python.core.agent.develop.develop_data import DevelopData
from adf_core_python.core.agent.info.agent_info import AgentInfo
from adf_core_python.core.agent.info.scenario_info import ScenarioInfo
from adf_core_python.core.agent.info.world_info import WorldInfo
from adf_core_python.core.agent.module.module_manager import ModuleManager
from adf_core_python.core.component.module.complex.human_detector import HumanDetector
from adf_core_python.core.logger.logger import get_agent_logger


class FireBrigadeHumanDetector(HumanDetector):
  def __init__(
    self,
    agent_info: AgentInfo,
    world_info: WorldInfo,
    scenario_info: ScenarioInfo,
    module_manager: ModuleManager,
    develop_data: DevelopData,
  ) -> None:
    super().__init__(
      agent_info, world_info, scenario_info, module_manager, develop_data
    )
    self._result: Optional[EntityID] = None
    self._has_logged_activation = False
    self._logger = get_agent_logger(
      f"{self.__class__.__module__}.{self.__class__.__qualname__}",
      self._agent_info,
    )

  def calculate(self) -> HumanDetector:
    if not self._has_logged_activation:
      self._logger.info("Custom FireBrigadeHumanDetector is active")
      self._has_logged_activation = True
    return self

  def get_target_entity_id(self) -> Optional[EntityID]:
    return self._result
```

## モジュールを登録する

`config/module.yaml` を開き、消防隊の `HumanDetector` を雛形から作成したクラスへ差し替えます。`TEAM_NAME` は実際のチーム名に置き換えてください。

```yaml
DefaultTacticsFireBrigade:
  HumanDetector: src.TEAM_NAME.module.complex.fire_brigade_human_detector.FireBrigadeHumanDetector
```

保存後、まず整形と静的解析を実行します。

```sh
uv run ruff format .
uv run ruff check .
```

次に、登録を確認するため、サーバとエージェントを起動します。

Tutorial 4・5 では、消防隊だけを配置したシナリオを使用します。まず `WORKING_DIR` 内に教材リポジトリを取得します。取得済みの場合、`git clone` は不要です。続けて、同梱のアーカイブを RCRS Server の `maps` ディレクトリへ展開してください。

##### サーバ側ターミナル

```sh
cd WORKING_DIR
git clone https://github.com/rcsimjp/rrs-tutorials.git
cd rcrs-server
unzip ../rrs-tutorials/resources/maps/tutorial_fire_brigade_only.zip -d maps/
```

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

エージェント側の標準出力に `Custom FireBrigadeHumanDetector is active` と表示されれば、`module.yaml` から自作クラスが読み込まれ、`calculate()` が呼ばれています。この段階ではまだ対象を選ばないため、救助行動は行いません。次の節で対象選択を実装します。

## エージェントが扱う情報

`HumanDetector` の実装では、エージェント自身と市民の状態を取得します。RCRS では、都市に存在するオブジェクトを**エンティティ**と呼びます。

<figure className="doc-figure">
  <a href={useBaseUrl('/img/tutorial/tutorial-4/entity-examples.jpg')} target="_blank" rel="noopener">
    <img src={useBaseUrl('/img/tutorial/tutorial-4/entity-examples.jpg')} alt="RCRS のエンティティ例" />
  </a>
  <figcaption>都市内の道路、建物、市民、救助部隊はすべてエンティティとして表されます。</figcaption>
</figure>

各エンティティは `EntityID` で一意に識別され、`EntityURN` で種別を表します。

| EntityURN | 意味 |
| --- | --- |
| `CIVILIAN` | 市民 |
| `AMBULANCE_TEAM`、`POLICE_FORCE`、`FIRE_BRIGADE` | 救助エージェント |
| `AMBULANCE_CENTRE`、`POLICE_OFFICE`、`FIRE_STATION` | 司令所 |
| `REFUGE` | 避難所 |
| `ROAD`、`BUILDING`、`BLOCKADE` | 道路、建物、瓦礫 |
| `GAS_STATION`、`HYDRANT` | ガソリンスタンド、給水栓 |

:::note

`REFUGE` や `FIRE_STATION` は `Building` を継承しますが、固有の `EntityURN` を持ちます。そのため `get_entities_of_types([Building])` には含まれます。通常の建物だけを対象にしたいときは、`entity.get_urn() == EntityURN.BUILDING` で絞り込みます。

:::

### 継承関係

エンティティは共通の属性やメソッドを継承します。たとえば `Civilian`、`FireBrigade`、`PoliceForce`、`AmbulanceTeam` は `Human` を継承し、`Human` は `Entity` を継承します。

<figure className="doc-figure doc-figure--narrow">
  <a href={useBaseUrl('/img/tutorial/tutorial-4/entity-inheritance-diagram.jpg')} target="_blank" rel="noopener">
    <img src={useBaseUrl('/img/tutorial/tutorial-4/entity-inheritance-diagram.jpg')} alt="エンティティの継承関係" />
  </a>
  <figcaption>エンティティの継承関係</figcaption>
</figure>

| クラス | 主な情報・操作 |
| --- | --- |
| `Entity` | `EntityID`、座標、種別。`get_entity_id()`、`get_x()`、`get_y()`、`get_urn()` を利用できます。未観測の属性は `None` になることがあります。 |
| `Human` | HP、ダメージ、埋没度、位置、移動距離。`get_hp()`、`get_damage()`、`get_buriedness()`、`get_position()` を利用できます。 |

エージェントが得られる情報は、知覚または通信によって更新されたものです。実際の都市状態が常にすべて分かるわけではありません。

### `AgentInfo` と `WorldInfo`

戦略の実装では、主に次の 2 つを使います。

| クラス | 用途 | よく使うメソッド |
| --- | --- | --- |
| `AgentInfo` | 自分自身の状態 | `get_entity_id()`、`get_time()`、`get_position_entity_id()`、`get_myself()` |
| `WorldInfo` | 自分以外も含む既知の世界情報 | `get_entity()`、`get_entities_of_types()`、`get_distance()`、`get_change_set()` |

この章では、`self._agent_info.get_entity_id()` で自分の ID を取得し、`self._world_info.get_entities_of_types([Civilian])` で市民を取得します。`WorldInfo` はエージェントが知覚・通信で得た情報を保持するため、実際の都市状態が常にすべて入っているわけではありません。

その他のエンティティやメソッドは、[rcrs-core-python の entities](https://github.com/adf-python/rcrs-core-python/tree/main/src/rcrscore/entities) を参照してください。

## 最も近い埋没市民を選ぶ

消防隊の救助対象は、次の条件を満たす市民に限定します。

- `Civilian` である
- HP が 0 より大きい
- 埋没度が 0 より大きい

候補のうち、自分との距離が最も短い市民を選びます。

<figure className="doc-figure doc-figure--narrow">
  <a href={useBaseUrl('/img/tutorial/tutorial-4/human-detector-flow.png')} target="_blank" rel="noopener">
    <img src={useBaseUrl('/img/tutorial/tutorial-4/human-detector-flow.png')} alt="HumanDetector の処理フロー" />
  </a>
  <figcaption>候補を絞り込み、最も近い埋没市民を選びます。</figcaption>
</figure>

### 演習

`calculate()` を実装する前に、ファイル先頭の import を次のように変更します。

```python
from rcrscore.entities import Civilian, Entity, EntityID
```

次に `calculate()` を、次の方針で実装してください。

1. 自分の `EntityID` と全 `Civilian` を取得する
2. 各市民が候補条件を満たすか確認する
3. `WorldInfo.get_distance()` で距離を取得する
4. 最短距離の市民の `EntityID` を `self._result` に設定する

### 実装例

自分で実装した後に確認してください。次のコードは **`fire_brigade_human_detector.py` 全体**です。既存の内容をすべて置き換えます。`calculate()` と `get_target_entity_id()` は、どちらも `FireBrigadeHumanDetector` クラスの中に置く必要があります。

```python title="src/TEAM_NAME/module/complex/fire_brigade_human_detector.py"
from adf_core_python.core.agent.develop.develop_data import DevelopData
from adf_core_python.core.agent.info.agent_info import AgentInfo
from adf_core_python.core.agent.info.scenario_info import ScenarioInfo
from adf_core_python.core.agent.info.world_info import WorldInfo
from adf_core_python.core.agent.module.module_manager import ModuleManager
from adf_core_python.core.component.module.complex.human_detector import HumanDetector
from adf_core_python.core.logger.logger import get_agent_logger
from rcrscore.entities import Civilian, Entity, EntityID


class FireBrigadeHumanDetector(HumanDetector):
  def __init__(
    self,
    agent_info: AgentInfo,
    world_info: WorldInfo,
    scenario_info: ScenarioInfo,
    module_manager: ModuleManager,
    develop_data: DevelopData,
  ) -> None:
    super().__init__(
      agent_info, world_info, scenario_info, module_manager, develop_data
    )
    self._result: EntityID | None = None
    self._logger = get_agent_logger(
      f"{self.__class__.__module__}.{self.__class__.__qualname__}",
      self._agent_info,
    )

  def calculate(self) -> HumanDetector:
    me: EntityID = self._agent_info.get_entity_id()
    civilians: list[Entity] = self._world_info.get_entities_of_types([Civilian])

    nearest_civilian: EntityID | None = None
    nearest_distance: float | None = None

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

      distance = self._world_info.get_distance(me, position)
      if nearest_distance is None or distance < nearest_distance:
        nearest_civilian = civilian.get_entity_id()
        nearest_distance = distance

    self._result = nearest_civilian
    self._logger.info(f"Target: {self._result}")
    return self

  def get_target_entity_id(self) -> EntityID | None:
    return self._result
```

`Civilian` 自身は座標を持たない場合があるため、距離は `civilian.get_entity_id()` ではなく、所在する Area を表す `position` まで求めます。位置がまだ観測されていない市民は候補から除外します。

## 実装を確認する

先ほどと同じ手順でサーバとエージェントを起動し、最後まで実行します。エージェント側のログに `Target: ...` が出力され、消防隊が埋没市民へ向かえば、対象選択が動作しています。

実行後、次のファイルが作成されていることを確認してください。

```text
WORKING_DIR/rcrs-server/logs/log/rescue.log.7z
```

このログを次節のログビューワで再生します。

## ログビューワで確認する

ログビューワを使うと、シミュレーションを再実行せずに、各ステップの状態を確認できます。

```sh
cd WORKING_DIR/rcrs-server
./gradlew logViewer --args="'-c' 'maps/test/config/logviewer.cfg' 'logs/log/rescue.log.7z'"
```

ログビューワが開いたら、次を確認します。

- 選択したステップの都市状態
- 選択したエンティティのプロパティ
- そのステップで発行されたコマンド
- 更新されたエンティティの種別と ID

下部のスライダーまたは矢印ボタンでステップを移動できます。停止するときはウィンドウを閉じるか、ターミナルで `Ctrl+C` を押します。

:::tip 次の章へ

次章では、この `HumanDetector` を距離だけでなく HP も考慮する選択器へ改良します。

:::

## 参考資料

- [adf-core-python — Agent Control](https://adf-python.github.io/adf-core-python/en/tutorial/agent/agent_control.html)
- [RCRS Core Python — Entity](https://github.com/adf-python/rcrs-core-python/blob/main/src/rcrscore/entities/entity.py)
- [RCRS Core Python — Building](https://github.com/adf-python/rcrs-core-python/blob/main/src/rcrscore/entities/building.py)
- [RCRS Core Python — Refuge](https://github.com/adf-python/rcrs-core-python/blob/main/src/rcrscore/entities/refuge.py)
