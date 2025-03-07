class_name AbilityData

# https://ffhacktics.com/wiki/Ability_Data
# https://ffhacktics.com/wiki/BATTLE.BIN_Data_Tables#Animation_.26_Display_Related_Data

var id: int = 0
var name: String = "ability name"
var spell_quote: String = "spell quote"
var vfx_data: VisualEffectData # BATTLE.BIN offset="14F3F0" - table of Effect IDs used by Ability ID
var animation_charging_id: int # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 2
var animation_executing_id: int # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 1
var animation_text_id: int # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 3


func _init(new_id: int = 0) -> void:
	id = new_id
	
	name = RomReader.fft_text.ability_names[id]
	spell_quote = RomReader.fft_text.ability_names[id]
