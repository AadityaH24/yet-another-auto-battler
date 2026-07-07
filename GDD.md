# Yet Another Auto Battler Roguelike (YAABR)

## Game Design Document

---

## 1. Overview

YAABR is a **turn-based auto battler** with roguelike progression. Players draft units, items, and abilities across a branching map, then engage in tactical auto-resolved battles on a small 4×4 grid. Elemental interactions (Fire, Wind, Water, Earth) create combo opportunities through zone overlaps and attack chaining.

**Core Loop**: Map Navigation → Battle → Shop/Draft → Battle → Boss → Run Ends

---

## 2. The Roguelike Map

Slay the Spire-style branching path. Each run consists of a sequence of nodes:

| Node Type | Description |
|-----------|-------------|
| **Battle** | Standard combat encounter |
| **Elite** | Harder fight with better rewards |
| **Boss** | End-of-act boss, run ends here |
| **Shop** | Spend gold on units, items, or consumables |
| **Treasure** | Free reward (unit, item, or gold) |
| **Rest** | Heal a damaged unit or remove a negative effect |

- The map has 3 acts, each ending with a Boss node.
- Paths branch at intervals; choices are permanent.
- Gold carries over through the run. Unspent gold is lost at run end.

---

## 3. Battle System

### 3.1 Grid

- **4×4 tile grid** (16 tiles total).
- Each player deploys **4–5 units** on their half of the grid (rows 1–2 for Player, rows 3–4 for Enemy by default).
- Deployment happens during the draft phase before combat.

### 3.2 Turn Order

- Every unit has a **Speed** stat.
- At the start of each turn, all units are sorted by Speed (descending).
- Ties broken randomly.
- Each unit acts once per turn in that order.

### 3.3 Unit Actions

On its turn, a unit's AI evaluates:

1. **In-range target** – prefers lowest-HP or highest-threat enemy
2. **Best ability** – basic attack vs. special ability (if off cooldown)
3. **Positioning** – if no target in range, move toward nearest enemy

Actions available:
- **Move**: shift 1 tile (orthogonal)
- **Attack**: deal damage to target
- **Ability**: use equipped special (if any, cooldown-gated)
- **Wait**: skip turn

### 3.4 Win Condition

- Eliminate all enemy units on the grid.
- If both sides lose their last unit on the same turn, it's a draw (rare, re-roll).

---

## 4. Unit Classes

Two weight classes, five total unit types:

### Light Units (2 HP, faster, higher priority)

| Class | Element Affinity | Role | Special |
|-------|-----------------|------|---------|
| **Soldier** | Neutral | Melee DPS | Basic attack, no element |
| **Mage** | Random element | Ranged caster | Attacks apply elemental affliction |
| **Scout** | Neutral | Mobile harasser | Can move 2 tiles per turn |

### Heavy Units (4 HP, slower, lower priority)

| Class | Element Affinity | Role | Special |
|-------|-----------------|------|---------|
| **Knight** | Neutral | Tank | Blocks adjacent ally attacks (soaks 1 dmg) |
| **Elementalist** | Random element | Heavy caster | Attacks apply strong elemental affliction, AOE on 2×2 zone |

- Each unit has a **base attack value** (Light: 1 dmg, Heavy: 2 dmg).
- HP is fixed per weight class (Light: 2, Heavy: 4).

---

## 5. Elements & Combos

### 5.1 The Four Elements

| Element | Abbrev | Affliction Effect |
|---------|--------|-------------------|
| Fire | FR | Burns – deals 1 dmg at start of afflicted unit's turn |
| Wind | WD | Knocks back – target is pushed 1 tile (if occupied, stunned instead) |
| Water | WT | Drenched – doubles next elemental damage taken |
| Earth | EA | Staggered – target skips next action (stun) |

### 5.2 Applying Elements

- **Mage** and **Elementalist** attacks apply affliction for 2 turns.
- Other units gain elemental attacks only through **items** or **buffs**.

### 5.3 Combo: Attack Chaining

If a unit attacks an enemy that is already afflicted with an element, the attack **chains**:

| Chain Combo | Effect |
|-------------|--------|
| Fire → Wind | **Wildfire** – spreads Burn to adjacent tiles |
| Wind → Water | **Storm** – pushes target + drenches all adjacent tiles |
| Water → Earth | **Mud** – slows target (reduced Speed next turn) |
| Earth → Fire | **Magma** – bonus +1 damage, removes Staggered |
| Fire → Water | **Steam** – blinds target (50% miss chance next attack) |
| Water → Fire | **Steam** (same as above) |
| Earth → Wind | **Dust** – reduces target's attack by 1 for 1 turn |
| Wind → Earth | **Dust** (same as above) |

Chaining consumes the existing affliction (it is replaced by the new element).

### 5.4 Combo: Zone Overlap

**AoE attacks** (Elementalist 2×2 blast) that hit multiple tiles can create **reaction zones**:

- If two different elemental AoEs overlap on the same tile(s), the intersection tile produces a combo effect instantly.
- The combo effect table (above) applies, centered on the overlap tile.
- If three or more elements overlap on one tile, the two most recently applied react; the third remains.

### 5.5 Elemental Reactions on the Grid

Tiles can be **infused** with residual element for 1 turn after an AoE lands there. If a unit steps onto an infused tile, they gain that element's affliction.

---

## 6. Items

### 6.1 Item Slots

Each unit can equip **up to 2 items**. Items are passive modifiers only (no activated abilities).

### 6.2 Item Types

| Category | Examples | Effect |
|----------|----------|--------|
| **Stat** | Iron Ring, Pendant of Haste | +1 ATK, +1 SPD, +1 DEF (reduce incoming dmg by 1) |
| **Element** | Fire Amulet, Wind Cape | Attacks apply that element (overrides class element) |
| **Defensive** | Stone Skin, Cloak of Evasion | Block first hit, 25% dodge chance |
| **Reactive** | Thorn Mail, Vitality Gem | Deal 1 dmg to attacker on hit, heal 1 on kill |
| **Combo** | Catalyst Orb, Twin Essence | +1 dmg on combo attacks, apply 2 elements on hit |

### 6.3 Rarity

- Common, Rare, Epic – higher rarities are stronger versions of the same effects.

---

## 7. Draft & Shop

### 7.1 Post-Battle Draft

After each battle win, the player is offered a choice of **1 of 3 rewards**:
- A random unit (from a pool that grows through the run)
- A random item (from current rarity pool)
- Gold

### 7.2 Shop Nodes

On shop nodes, the player can spend gold on:
- **Buy Unit** – purchase a specific unit type (cost varies by class)
- **Buy Item** – purchase from a rotating selection of 4 items
- **Reroll** – refresh the shop (costs 1 gold)
- **Sell Unit** – remove a unit and gain 1 gold

### 7.3 Unit Pool

- Starts with 2 Soldiers + 1 random Light unit.
- After each battle, available unit types in the pool expand.
- Maximum roster size: **6 units** (only 4–5 deploy per battle).
- Benched units do not participate.

---

## 8. Run Structure

```
Act 1 (3 nodes)
  ├─ Battle → Shop → Battle → Elite → Boss
  └─ Alternate path options at each branch

Act 2 (4 nodes) – harder enemies, higher rarity items

Act 3 (5 nodes) – hardest, best loot

Final Boss → Victory screen + score
```

- If all units die, run ends.
- Score based on: bosses killed, units collected, items collected, gold earned.

---

## 9. Economy

| Action | Cost / Reward |
|--------|---------------|
| Win battle | +2 gold |
| Win elite | +4 gold + treasure |
| Win boss | +6 gold + treasure |
| Sell unit | +1 gold |
| Buy Light unit | 2 gold |
| Buy Heavy unit | 3 gold |
| Buy Common item | 1 gold |
| Buy Rare item | 2 gold |
| Buy Epic item | 3 gold |
| Reroll shop | 1 gold |

---

## 10. UI Layout (Concept)

```
┌─────────────────────────────────┐
│  Map (top bar, node indicator)  │
├──────────┬──────────────────────┤
│  Bench   │                      │
│  (3 cols) │    Battle Grid      │
│          │    4×4 tiles        │
│          │                      │
├──────────┴──────────────────────┤
│  Unit Info / Shop / Draft Panel │
└─────────────────────────────────┘
```

---

## 11. Technical Notes

- Target engine: **Godot 4**
- Resolution: 1280×720 (scalable)
- Grid tiles: 64×64 px each
- Art style: pixel art (to be defined)
