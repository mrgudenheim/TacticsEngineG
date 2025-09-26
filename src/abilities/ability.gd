class_name Ability
extends Resource

enum SlotType {
	SKILLSET,
	REACTION,
	SUPPORT,
	MOVEMENT,
}

@export var id: int = 0
@export var unique_name: String = "unique_name"
@export var ability_name: String = "[Ability Name]"
@export var slot_type: SlotType = SlotType.SKILLSET

@export var spell_quote: String = "spell quote"
@export var jp_cost: int = 0
@export var chance_to_learn: float = 100 # percent
@export var learn_with_jp: bool = true
@export var display_ability_name: bool = true
@export var learn_on_hit: bool = false

@export var passive_effect: PassiveEffect = PassiveEffect.new()
@export var triggered_actions: Array[TriggeredAction] = []


func add_to_global_list(will_overwrite: bool = false) -> void:
	if ["", "unique_name"].has(unique_name):
		unique_name = ability_name.to_snake_case()
	if RomReader.abilities.keys().has(unique_name) and will_overwrite:
		push_warning("Overwriting existing action: " + unique_name)
	elif RomReader.abilities.keys().has(unique_name) and not will_overwrite:
		var num: int = 2
		var formatted_num: String = "%02d" % num
		var new_unique_name: String = unique_name + "_" + formatted_num
		while RomReader.abilities.keys().has(new_unique_name):
			num += 1
			formatted_num = "%02d" % num
			new_unique_name = unique_name + "_" + formatted_num
		
		push_warning("Ability list already contains: " + unique_name + ". Incrementing unique_name to: " + new_unique_name)
		unique_name = new_unique_name
	
	RomReader.abilities[unique_name] = self