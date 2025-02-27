class_name AbilityData

# https://ffhacktics.com/wiki/Ability_Data
# https://ffhacktics.com/wiki/BATTLE.BIN_Data_Tables#Animation_.26_Display_Related_Data

var id: int
var name: String
var vfx_data : VisualEffectData # BATTLE.BIN offset="14F3F0" - table of Effect IDs used by Ability ID
var animation_charging # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 2
var animation_executing # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 1
var animation_text # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 3
