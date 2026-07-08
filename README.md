# YAABR — Yet Another Auto Battler Roguelike

A turn-based auto battler with roguelike progression, built in **Godot 4.7** (GDScript).

**Draft a roster → Navigate a Slay-the-Spire-style map → Auto-resolve tactical grid battles → Repeat**

![Main Menu](screenshots/main_menu.png)

---

## Features

### Roster Draft
- **10 gold** budget to draft 3–5 units from 11 classes
- Classes: Soldier, Mage, Scout, Knight, Elementalist, Berserker, Shieldbearer, Lancer, Archer, Warlock, Cleric
- Each class has unique stats, cost (2–4 gold), range, AOE pattern, and passive/deployment abilities
- Duplicate classes allowed

### Roguelike Map
- 3 acts with branching paths (Slay the Spire style)
- Node types: **Battle**, **Elite**, **Boss**, **Shop**, **Treasure**, **Rest**
- Difficulty scales per node: `base 5 + act×2 + layer×2 + type bonus`
- Rest nodes let you **merge** 3 same-class units into an upgraded unit (×1.5/×2.0 stats)

### Grid Combat
- 4×4 grid, priority-based auto combat
- Units act in speed order each turn
- AOE patterns: Single, Cleave Sides, Line, Splash Ortho
- Floating damage numbers, hit flash, AOE preview overlay
- Status effects: Burn, Chill, Root, Pushback, Poison

### Element System
- 4 elements: **Fire → Wind → Earth → Water → Fire**
- ~30% chance per unit gets an element (rest are NONE)
- Element advantage: +1/-1 damage on attack
- Zone combos from adjacent allies with next-cycle element (+1 ATK)
- Afflictions on hit per element

### Items
- 15 predefined items across 3 rarities (Common, Rare, Epic)
- Stat bonuses: HP, ATK, SPD, Range
- On-hit effects: Poison, Burn, Thorns, Lifesteal, Snare
- Turn-start effects: Regen, Fortify
- Item management in deployment screen (equip/unequip)
- Rewards give mix of units + items

### Procedural Pixel Art
- 64×64 class-specific pixel art generated at runtime
- Color palettes per class with team tint and element auras
- Star rank indicators (★/★★)
- Class icon badges (wood plaque with class symbol at bottom-left of each sprite)

### UI
- Dark Fantasy Parchment theme
- Unit tooltips on hover
- HP bars on grid
- Pause menu with return to main menu

---

## Screenshots

| | |
|---|---|
| ![Battle](screenshots/battle.png) | ![Deployment](screenshots/deployment.png) |
| ![Map](screenshots/map.png) | ![Shop](screenshots/shop.png) |
| ![Draft](screenshots/draft.png) | ![Merge](screenshots/merge.png) |

---

## How to Play

1. **New Game** — Draft your starting roster with 10 gold
2. **Map** — Choose your path through 3 acts of nodes
3. **Deploy** — Place units on your zone tiles, equip items
4. **Battle** — Watch auto-combat resolve, with manual ability triggers
5. **Shop / Rewards** — Buy units, sell extras, collect items
6. **Rest** — Merge duplicate classes to power up
7. **Boss** — Defeat act bosses to progress

---

## Controls

| Input | Action |
|---|---|
| Left Click | Select / Place / Confirm |
| Right Click | Remove unit from grid |
| Escape | Cancel selection / Pause |

---

## Project Structure

```
yet-another-auto-battler/
├── scripts/
│   ├── battle/       AI, combat state, unit instances, deployment screen
│   ├── core/         Enums, EventBus, CombatEngine, UnitFactory
│   ├── draft/        Reward selection screen
│   ├── elements/     Element data definitions
│   ├── graphics/     Procedural sprite generator
│   ├── items/        Item data resource & database (15 items)
│   ├── main/         Game entry point, RunManager
│   ├── map/          Map generation, nodes, map screen
│   ├── menu/         Main menu, pause menu
│   ├── rest/         Merge screen
│   ├── shop/         Shop screen
│   ├── ui/           ThemeHelper (Dark Fantasy Parchment)
│   └── units/        UnitData resource
├── scenes/           main.tscn, unit_instance.tscn
├── tests/            Runtime validation & map generation tests
├── GDD.md            Game Design Document
└── TDD.md            Technical Design Document
```

---

## Tests

Run from command line:

```sh
godot --headless tests/validate_runtime.gd
godot --headless tests/test_map.gd
```

- `validate_runtime.gd` — Validates ItemData, UnitData, Enums, CombatEngine, UnitFactory
- `test_map.gd` — 6 unit tests for map generation (all passing)

---

## Tech

| | |
|---|---|
| Engine | Godot 4.7 (Mobile renderer) |
| Rendering | Direct3D 12, 1280×720 canvas_items stretch |
| Physics | Jolt Physics 3D |
| Language | GDScript (26 scripts) |
| Autoload | EventBus (`res://scripts/core/event_bus.gd`) |

---

## Development

Created by **Aaditya C**
