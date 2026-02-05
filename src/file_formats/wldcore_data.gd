class_name WldcoreData

# https://ffhacktics.com/wiki/WLDCORE.BIN_Random_Battle_Data
var world_random_battle_data_start: int = 0x2fa64
var world_random_battle_data_num_entries: int = 57
var world_random_battle_data_entry_length: int = 24
var world_random_battle_data: Array[RandomBattle] = []

var dungeon_random_battle_data_start: int = 0x2ffc0
var dungeon_random_battle_data_num_entries: int = 10
var dungeon_random_battle_data_entry_length: int = 10
var dungeon_random_battle_data: Array[DungeonBattle] = []

class RandomBattle:
	var path_id: int = 0
	var squad_id: int = 0
	var battle_sets: Array[PackedByteArray] = []
	var entds: PackedInt32Array = []
	var map_id: int = 0
	var variable_id: int = 0
	
	func _init(bytes: PackedByteArray) -> void:
		path_id = bytes.decode_u8(0)
		squad_id = bytes.decode_u8(1) + 0x200
		
		for idx: int in 4:
			var battle_set_start: int = (idx * 3) + 2
			var battle_set_bytes: PackedByteArray = bytes.slice(battle_set_start, battle_set_start + 3)
			battle_sets.append(battle_set_bytes)
		
		for idx: int in 8:
			entds.append(bytes.decode_u8(idx + 0x0e))
		
		map_id = bytes.decode_u8(0x16)
		variable_id = bytes.decode_u8(0x17)

class DungeonBattle:
	var map_id: int = 0
	var squad_id: int = 0
	var entds: PackedByteArray = []
	
	func _init(bytes: PackedByteArray) -> void:
		map_id = bytes.decode_u8(0)
		squad_id = bytes.decode_u8(1) + 0x200
		
		for idx: int in 8:
			entds.append(bytes.decode_u8(idx + 0x02))


func init_from_wldcore() -> void:
	var wldcore_bytes: PackedByteArray = RomReader.get_file_data("WLDCORE.BIN")
	
	var world_random_battle_bytes_length: int = world_random_battle_data_num_entries * world_random_battle_data_entry_length
	var world_random_battle_table_bytes: PackedByteArray = wldcore_bytes.slice(world_random_battle_data_start, world_random_battle_data_start + world_random_battle_bytes_length)
	for idx: int in world_random_battle_data_num_entries:
		var world_random_battle_bytes_start: int = idx * world_random_battle_data_entry_length
		var world_random_battle_bytes: PackedByteArray = world_random_battle_table_bytes.slice(world_random_battle_bytes_start, world_random_battle_bytes_start + world_random_battle_data_entry_length)

		world_random_battle_data.append(RandomBattle.new(world_random_battle_bytes))
	
	var dungeon_random_battle_bytes_length: int = dungeon_random_battle_data_num_entries * dungeon_random_battle_data_entry_length
	var dungeon_random_battle_table_bytes: PackedByteArray = wldcore_bytes.slice(dungeon_random_battle_data_start, dungeon_random_battle_data_start + dungeon_random_battle_bytes_length)
	for idx: int in dungeon_random_battle_data_num_entries:
		var dungeon_random_battle_bytes_start: int = idx * dungeon_random_battle_data_entry_length
		var dungeon_random_battle_bytes: PackedByteArray = dungeon_random_battle_table_bytes.slice(dungeon_random_battle_bytes_start, dungeon_random_battle_bytes_start + dungeon_random_battle_data_entry_length)

		dungeon_random_battle_data.append(DungeonBattle.new(dungeon_random_battle_bytes))
