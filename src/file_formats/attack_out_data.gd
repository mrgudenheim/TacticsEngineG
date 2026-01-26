class_name AttackOutData

# https://ffhacktics.com/wiki/ATTACK.OUT
var scenario_data_start: int = 0x10938
var scenario_data_num_entries: int = 0x1ea
var scenario_data_entry_length: int = 24
var scenario_data: Array[ScenarioData] = []

var deployment_data_start: int = 0xbbd4
var deployment_data_num_entries: int = 0x2ff + 1
var deployment_data_entry_length: int = 12
var deployment_data: Array[DeploymentData] = []

class ScenarioData:
	var scenario_id: int = 0
	var map_id: int = 0
	var weather: int = 0
	var is_nighttime: bool = false
	var music_file_one_id: int = 0
	var music_file_two_id: int = 0
	var entd_idx: int = 0
	var first_squad_deployment_idx: int = 0
	var second_squad_deployment_idx: int = 0
	var flags: int = 0 # 0x01 = ramza is mandatory during deployment
	var next_scenario_id: int = 0
	var post_scenario_step: int = 0 # 0x80 = go to world map, 0x81 = go to next scenario, 0x82 = reset game
	var event_script_id: int = 0
	
	func _init(bytes: PackedByteArray) -> void:
		scenario_id = bytes.decode_u16(0)
		map_id = bytes.decode_u8(2)
		weather = bytes.decode_u8(3)
		is_nighttime = bytes.decode_u8(4) == 1
		music_file_one_id = bytes.decode_u8(5)
		music_file_two_id = bytes.decode_u8(6)
		entd_idx = bytes.decode_u16(7)
		first_squad_deployment_idx = bytes.decode_u16(9)
		second_squad_deployment_idx = bytes.decode_u16(11)
		flags = bytes.decode_u8(17) # 0x01 = ramza is mandatory during deployment
		next_scenario_id = bytes.decode_u16(18)
		post_scenario_step = bytes.decode_u8(20) # 0x80 = go to world map, 0x81 = go to next scenario, 0x82 = reset game
		event_script_id = bytes.decode_u16(22)

class DeploymentData:
	var deployment_zone_bitmap: int = 0 # 0x01ffffff is full 5x5 grid
	var deployment_map: Dictionary[Vector2i, bool] = {}
	var deployment_zone_center_x: int = 0
	var deployment_zone_center_y: int = 0
	var orientation: int = 0 # 0 = West, 1 = South, 2 = East, 3 = North
	var orientation_bitmap_rotated: int = 0 # 0 = West, 1 = South, 2 = East, 3 = North
	var max_squad_size: int = 1
	var map_id: int = 0
	var deployment_id: int = 0
	
	func _init(bytes: PackedByteArray) -> void:
		deployment_zone_bitmap = bytes.decode_u32(0) # 0x01ffffff is full 5x5 grid
		deployment_zone_center_x = bytes.decode_u8(4)
		deployment_zone_center_y = bytes.decode_u8(5)
		
		for idx: int in 25:
			var coord_x: int = (idx % 5) - 2 + deployment_zone_center_x
			var coord_y: int = floori(idx / 5.0) - 2 + deployment_zone_center_y
			var coordinates: Vector2i = Vector2i(coord_x, coord_y)
			var is_present: bool = deployment_zone_bitmap & (idx**2) != 0
			deployment_map[coordinates] = is_present
		
		orientation = (bytes.decode_u8(7) & 0xf0) >> 4 # 0 = West, 1 = South, 2 = East, 3 = North
		orientation_bitmap_rotated = bytes.decode_u8(7) & 0x0f # 0 = West, 1 = South, 2 = East, 3 = North
		max_squad_size = bytes.decode_u8(8)
		map_id = bytes.decode_u8(9)
		deployment_id = bytes.decode_u16(10)


func init_from_attack_out() -> void:
	var attack_out_bytes: PackedByteArray = RomReader.get_file_data("ATTACK.OUT")
	
	var scenario_bytes_length: int = scenario_data_num_entries * scenario_data_entry_length
	var scenario_bytes: PackedByteArray = attack_out_bytes.slice(scenario_data_start, scenario_data_start + scenario_bytes_length)
	for idx: int in scenario_data_num_entries:
		var scenario_bytes_start: int = idx * scenario_data_entry_length
		var scenario_entry_bytes: PackedByteArray = scenario_bytes.slice(scenario_bytes_start, scenario_bytes_start + scenario_data_entry_length)

		scenario_data.append(ScenarioData.new(scenario_entry_bytes))
	
	var deployment_bytes_length: int = deployment_data_num_entries * deployment_data_entry_length
	var deployment_table_bytes: PackedByteArray = attack_out_bytes.slice(deployment_data_start, deployment_data_start + deployment_bytes_length)
	for idx: int in deployment_data_num_entries:
		var deployment_bytes_start: int = idx * deployment_data_entry_length
		var deployment_entry_bytes: PackedByteArray = deployment_table_bytes.slice(deployment_bytes_start, deployment_bytes_start + deployment_data_entry_length)

		deployment_data.append(DeploymentData.new(deployment_entry_bytes))
