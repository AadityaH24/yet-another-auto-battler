extends Node

# Available for consumers (UI, audio, analytics, etc.).
# Connect to these from any script via EventBus.<signal>.connect(...)
signal battle_started
signal unit_damaged(unit: Node2D, attacker: Node2D, amount: int)
signal unit_destroyed(unit: Node2D)
signal battle_ended(winner: int)
