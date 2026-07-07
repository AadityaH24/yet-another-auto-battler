# YAABR — Technical Design Document

## Godot 4 Implementation Blueprint

---

## 1. Project Structure

```
yet-another-auto-battler/
├── assets/          # Sprites, sounds, fonts
│   ├── tiles/
│   ├── units/
│   ├── items/
│   ├── ui/
│   └── sfx/
├── scenes/          # .tscn files
│   ├── map/
│   ├── battle/
│   ├── shop/
│   ├── draft/
│   └── main_menu/
├── scripts/         # .gd files
│   ├── map/
│   ├── battle/
│   ├── shop/
│   ├── draft/
│   ├── units/
│   ├── items/
│   ├── elements/
│   └── core/
├── resources/       # .tres files (data definitions)
│   ├── units/
│   ├── items/
│   ├── elements/
│   └── encounters/
└── addons/
```

---

## 2. Core Architecture (Singletons / Autoloads)

### 2.1 Autoloads

```
┌─────────────────────┐
│     GameManager     │  Global state: run progress, gold, act
├─────────────────────┤
│    EventBus         │  Signal hub for decoupled communication
├─────────────────────┤
│    ResourceDB       │  Loads & caches all .tres data
├─────────────────────┤
│    CombatEngine     │  Resolves battle logic (stateless)
└─────────────────────┘
```

### 2.2 GameManager (core/game_manager.gd)

```gdscript
class_name GameManager extends Node

# -- Run State --
var current_act: int
var current_node: MapNodeData
var gold: int
var roster: Array[UnitData]          # owned units (max 6)
var deployed_indices: Array[int]     # indices into roster for next battle

# -- Signals --
signal gold_changed(new_amount: int)
signal roster_changed()
signal run_ended(result: RunResult)
signal act_completed(act: int)

func start_run()
func end_run(result: RunResult)
func add_gold(amount: int)
func spend_gold(amount: int) -> bool
func add_unit(data: UnitData) -> bool
func remove_unit(index: int)
```

### 2.3 EventBus (core/event_bus.gd)

```gdscript
extends Node

signal battle_started(units_p1: Array[UnitInstance], units_p2: Array[UnitInstance])
signal battle_tick(turn_number: int)
signal unit_damaged(unit: UnitInstance, attacker: UnitInstance, amount: int)
signal unit_destroyed(unit: UnitInstance)
signal battle_ended(winner: int)  # 0=player, 1=enemy, -1=draw
signal element_applied(tile: Vector2i, element: ElementType)
signal combo_triggered(combo: ComboDefinition, tile: Vector2i)
signal node_entered(node: MapNodeData)
signal shop_opened()
```

---

## 3. Data-Driven Design (Resources)

All game data lives in `.tres` resource files. This separates data from logic.

### 3.1 UnitData (resources/units/unit_data.gd)

```gdscript
class_name UnitData extends Resource

@export var unit_name: String
@export var unit_class: UnitClass          # enum: SOLDIER, MAGE, SCOUT, KNIGHT, ELEMENTALIST
@export var weight: UnitWeight             # enum: LIGHT, HEAVY
@export var base_hp: int
@export var base_attack: int
@export var base_speed: int
@export var element_affinity: ElementType  # enum: NONE, FIRE, WIND, WATER, EARTH
@export var ability: AbilityData           # optional special ability
@export var icon: Texture2D
@export var scene: PackedScene             # visual representation
```

### 3.2 ItemData (resources/items/item_data.gd)

```gdscript
class_name ItemData extends Resource

@export var item_name: String
@export var item_rarity: ItemRarity        # enum: COMMON, RARE, EPIC
@export var item_category: ItemCategory    # enum: STAT, ELEMENT, DEFENSIVE, REACTIVE, COMBO
@export var modifiers: Array[StatModifier]

# StatModifier is a simple dict-like Resource
class_name StatModifier extends Resource
@export var stat: StatType                 # enum: HP, ATK, SPD, DEF
@export var value: int
@export var operation: ModOp               # enum: ADD, MULTIPLY
```

### 3.3 ElementData (resources/elements/element_data.gd)

```gdscript
class_name ElementData extends Resource

@export var element_type: ElementType
@export var display_name: String
@export var color: Color
@export var icon: Texture2D
@export var affliction_turns: int          # how long the affliction lasts
@export var on_tick_effect: Callable       # optional effect each turn (e.g. Burn)
```

### 3.4 ComboDefinition (resources/elements/combo_definition.gd)

```gdscript
class_name ComboDefinition extends Resource

@export var primary: ElementType
@export var secondary: ElementType
@export var combo_name: String
@export var effect: ComboEffect            # enum with associated data
@export var area: int                      # 0=single target, 1=cross, 2=2x2
```

### 3.5 MapNodeData (resources/map/map_node_data.gd)

```gdscript
class_name MapNodeData extends Resource

@export var node_type: MapNodeType         # enum: BATTLE, ELITE, BOSS, SHOP, TREASURE, REST
@export var node_name: String
@export var connections: Array[MapNodeData]  # next nodes (branching)
@export var encounter: EncounterData       # for battle nodes
@export var grid_position: Vector2         # visual position on map screen
```

### 3.6 EncounterData (resources/encounters/encounter_data.gd)

```gdscript
class_name EncounterData extends Resource

@export var enemy_units: Array[UnitData]
@export var difficulty_modifier: float     # scales enemy stats
@export var reward_multiplier: float
```

---

## 4. Battle System Architecture

### 4.1 Scene Tree (scenes/battle/battle.tscn)

```
Battle (Node2D)
├── BattleGrid (TileMapLayer)        # 4x4 grid rendering
├── GridOverlay (TileMapLayer)       # selection highlights, element infusions
├── EnemyUnits (Node2D)              # enemy unit sprites
├── PlayerUnits (Node2D)             # player unit sprites
├── TurnOrderUI (Control)            # turn order display
├── CombatLog (Control)              # scrollable log
└── BattleHUD (Control)              # end-turn, unit info
```

### 4.2 UnitInstance (units/unit_instance.gd)

Runtime representation of a unit on the grid:

```gdscript
class_name UnitInstance extends Node2D

# -- Data (set on spawn) --
var unit_data: UnitData
var owner_id: int                      # 0=player, 1=enemy
var grid_pos: Vector2i
var items: Array[ItemData]             # equipped (max 2)

# -- Runtime state --
var current_hp: int
var current_speed: int                 # after modifications
var afflicted_element: ElementType
var affliction_turns_remaining: int
var is_stunned: bool
var has_acted: bool                    # already acted this turn
var buffs: Array[BuffInstance]

# -- Signals --
signal hp_changed(new_hp: int, old_hp: int)
signal element_changed(element: ElementType)
signal destroyed()
```

### 4.3 CombatEngine (core/combat_engine.gd)

Stateless, callable from autoload:

```gdscript
class_name CombatEngine extends Node

func execute_battle(state: BattleState) -> BattleResult
func calculate_turn_order(state: BattleState) -> Array[UnitInstance]
func process_action(state: BattleState, actor: UnitInstance, action: BattleAction)
func apply_damage(state: BattleState, target: UnitInstance, amount: int, element: ElementType)
func apply_element(state: BattleState, target: UnitInstance, element: ElementType)
func check_combos(state: BattleState, target: UnitInstance, element: ElementType, position: Vector2i)
func resolve_chain_combo(state: BattleState, primary: ElementType, secondary: ElementType, tile: Vector2i)
func resolve_zone_combo(state: BattleState, tile: Vector2i)
func check_win_condition(state: BattleState) -> int
func move_unit(state: BattleState, unit: UnitInstance, target_tile: Vector2i)
```

### 4.4 BattleState (battle/battle_state.gd)

Value object holding all mutable battle data:

```gdscript
class_name BattleState extends RefCounted

var turn_number: int
var units: Array[UnitInstance]          # all units on grid
var tile_infusions: Dictionary          # Vector2i -> ElementType (residual element on tiles)
var tile_units: Dictionary              # Vector2i -> UnitInstance (occupancy map)
var turn_queue: Array[UnitInstance]     # remaining units to act
var current_actor_index: int
var winner: int                         # -1 = undecided
```

### 4.5 AI Controller (battle/ai_controller.gd)

```gdscript
class_name AIController extends Node

func decide_action(state: BattleState, unit: UnitInstance) -> BattleAction
func find_best_target(state: BattleState, unit: UnitInstance) -> UnitInstance
func evaluate_threat(unit: UnitInstance) -> int
func evaluate_position(state: BattleState, unit: UnitInstance) -> Vector2i
```

AI Decision Flow:
1. If enemy in attack range → attack (prefer element-combo target)
2. If ability off cooldown and in range → use ability
3. If no target in range → move toward nearest enemy
4. If cannot move → wait

### 4.6 BattleAction (battle/battle_action.gd)

```gdscript
class_name BattleAction extends RefCounted

enum ActionType { MOVE, ATTACK, ABILITY, WAIT }
var action_type: ActionType
var target_tile: Vector2i               # for move
var target_unit: UnitInstance           # for attack/ability
var ability_index: int                  # for ability
```

### 4.7 Turn Resolution Flow

```
1. Sort all units by Speed → turn_queue
2. For each unit in turn_queue:
   a. AI (if enemy) or player command (if player and manual mode — future)
   b. Execute action via CombatEngine
   c. Check win condition after each action
   d. Emit signals via EventBus
3. End of turn → tick afflictions (Burn damage)
4. Start next turn
```

---

## 5. Element & Combo Resolution

### 5.1 Applying Element (CombatEngine.apply_element)

```
1. Check if target already has an affliction
2. If yes → check chain combo table → resolve chain effect → replace affliction
3. If no → apply fresh affliction
4. Emit element_applied signal
```

### 5.2 Zone Overlap Detection (after each AoE)

```
1. For each tile hit by AoE:
   a. If tile_infusions has an existing element → check combo against new element
   b. Resolve combo at that tile position
   c. Update tile_infusion
2. Clear tile_infusions at end of turn
```

### 5.3 Tile Infusion (CombatEngine)

```
1. After any elemental AoE or chain effect, record residual element on affected tiles
2. Duration: 1 turn (cleared during end-of-turn cleanup)
3. Unit that steps on or occupies an infused tile:
   a. Gains that element's affliction for 1 turn
```

---

## 6. Map System

### 6.1 Scene (scenes/map/map.tscn)

```
MapScreen (Control)
├── MapCanvas (Node2D)                  # draws paths & nodes
│   ├── PathLine (Line2D)              # connecting lines
│   └── MapNode (TextureButton) × N   # clickable nodes
└── MapHUD (Control)
    ├── GoldDisplay
    ├── ActIndicator
    └── RosterPreview
```

### 6.2 Map Generation (scripts/map/map_generator.gd)

```gdscript
class_name MapGenerator extends Node

func generate_map(act: int) -> Array[MapNodeData]
func generate_layout(act: int, nodes: Array[MapNodeData])
```

Generation algorithm:
1. Define number of layers (3 for act 1, 4 for act 2, 5 for act 3)
2. For each layer, generate 2–4 nodes with random types (weighted)
3. Connect each node to 1–2 nodes in the next layer (ensuring no dead ends)
4. Mark exactly one node per act as the Boss (last layer)
5. Return flat array + connection graph

### 6.3 Node Type Weights

| Act | Battle | Elite | Shop | Treasure | Rest |
|-----|--------|-------|------|----------|------|
| 1   | 50%    | 10%   | 15%  | 15%      | 10%  |
| 2   | 40%    | 20%   | 15%  | 10%      | 15%  |
| 3   | 35%    | 25%   | 15%  | 10%      | 15%  |

---

## 7. Shop System

### 7.1 Scene (scenes/shop/shop.tscn)

```
ShopScreen (Control)
├── UnitShopPanel (GridContainer)
│   └── ShopSlot (Panel) × 4           # purchasable units
├── ItemShopPanel (GridContainer)
│   └── ShopSlot (Panel) × 4           # purchasable items
├── RosterPanel (HBoxContainer)
│   └── RosterSlot × 6                 # current roster + sell
├── GoldDisplay
├── RerollButton
└── ConfirmButton
```

### 7.2 Shop Logic (scripts/shop/shop_controller.gd)

```gdscript
class_name ShopController extends Node

var available_units: Array[UnitData]
var available_items: Array[ItemData]

func open_shop()
func generate_shop_pool()
func buy_unit(index: int) -> bool
func buy_item(index: int) -> bool
func reroll() -> bool
func sell_unit(index: int)
func can_afford(cost: int) -> bool
```

---

## 8. Draft System (Post-Battle)

### 8.1 Scene (scenes/draft/draft.tscn)

```
DraftScreen (Control)
├── DraftCard (Panel) × 3              # choice cards
│   ├── CardIcon
│   ├── CardName
│   ├── CardDescription
│   └── CardRarityIndicator
└── SkipButton
```

### 8.2 Draft Logic (scripts/draft/draft_controller.gd)

```gdscript
class_name DraftController extends Node

var options: Array[DraftOption]          # 3 choices

func open_draft(reward_tier: RewardTier)
func generate_options(tier: RewardTier)
func select_option(index: int)
func skip()
```

DraftOption can contain:
- UnitData (new unit)
- ItemData (new item)
- int (gold amount)

---

## 9. Signal Flow Diagram

```
┌────────────┐   node_entered    ┌───────────┐
│ MapScreen  │ ────────────────→ │GameManager│
└────────────┘                   └─────┬─────┘
                                       │
                          battle_started│
                                       ↓
                              ┌────────────────┐
                              │  BattleScene   │
                              │  CombatEngine  │
                              └───────┬────────┘
                          unit_destroyed│
                                       ↓
                              ┌────────────────┐
                              │GameManager     │
                              │ check roster   │
                              └───────┬────────┘
                          battle_ended│
                          (player win)│
                                     ↓
                            ┌─────────────────┐
                            │ DraftController │
                            └───────┬─────────┘
                                    │
                          roster_changed│
                                     ↓
                            ┌─────────────────┐
                            │ ShopController  │ (if shop node)
                            └───────┬─────────┘
                                    │
                          node_entered│ (next node)
                                     ↓
                            ┌─────────────────┐
                            │   MapScreen     │ (next loop)
                            └─────────────────┘
```

---

## 10. Enums (core/enums.gd)

```gdscript
enum UnitClass { SOLDIER, MAGE, SCOUT, KNIGHT, ELEMENTALIST }
enum UnitWeight { LIGHT, HEAVY }
enum ElementType { NONE, FIRE, WIND, WATER, EARTH }
enum ItemRarity { COMMON, RARE, EPIC }
enum ItemCategory { STAT, ELEMENT, DEFENSIVE, REACTIVE, COMBO }
enum ModOp { ADD, MULTIPLY }
enum StatType { HP, ATK, SPD, DEF }
enum MapNodeType { BATTLE, ELITE, BOSS, SHOP, TREASURE, REST }
enum RunResult { VICTORY, DEFEAT }
enum ComboEffect { WILDFIRE, STORM, MUD, MAGMA, STEAM, DUST, BLIND, SLOW }
```

---

## 11. Implementation Order

| Phase | What | Depends On |
|-------|------|------------|
| 1 | Resource types (UnitData, ItemData, ElementData, etc.) | Nothing |
| 2 | Enums, EventBus, GameManager singletons | Phase 1 |
| 3 | Tile grid rendering (TileMapLayer) | Nothing |
| 4 | UnitInstance scene + spawning | Phase 1 |
| 5 | CombatEngine core (damage, move, turn order) | Phase 2, 4 |
| 6 | Element affliction + chain combos | Phase 1, 5 |
| 7 | Zone overlap + tile infusion | Phase 3, 6 |
| 8 | AI controller | Phase 5 |
| 9 | Map generator + MapScreen | Phase 1 |
| 10 | Draft screen | Phase 1, 2 |
| 11 | Shop screen | Phase 1, 2 |
| 12 | Full run loop integration | Phase 9–11 |
| 13 | Items + equipment UI | Phase 1, 4 |
| 14 | Polish (VFX, SFX, animations) | All |
