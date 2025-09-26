class_name Ability
extends Resource

enum SlotType {
	SKILLSET,
	REACTION,
	SUPPORT,
	MOVEMENT,
}

@export var id: int = 0
@export var unique_name: String = "unique_name.ability"
@export var name: String = "[Ability Name]"
@export var slot_type: SlotType = SlotType.SKILLSET

@export var spell_quote: String = "spell quote"
@export var jp_cost: int = 0
@export var chance_to_learn: float = 100 # percent
@export var learn_with_jp: bool = true
@export var display_ability_name: bool = true
@export var learn_on_hit: bool = false

@export var passive_effect: PassiveEffect = PassiveEffect.new()
@export var triggered_actions: Array[TriggeredAction] = []
