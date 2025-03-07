class_name FftText

class FftTextFile:
	var offsets_start: int = 0
	var num_offsets = 0
	var offsets_end = 0
	var offsets: PackedInt32Array = []
	var text_arrays: Dictionary[int, PackedStringArray] = {}
	var text_end: int = 0
	var sections: Dictionary = {}
	
	func _init(new_offsets_start = 0, new_num_offsets = 0, new_text_end = 0, new_sections: Dictionary = {}) -> void:
		offsets_start = new_offsets_start
		num_offsets = new_num_offsets
		text_end = 2147483647 if new_text_end == 0 else new_text_end
		sections = new_sections
		
		offsets_end = offsets_start + (num_offsets * 4)
		offsets.resize(num_offsets)

# Text
# https://github.com/Glain/FFTPatcher/blob/master/FFTacText/notes.txt
# https://ffhacktics.com/wiki/Load_FFTText
# https://github.com/Glain/FFTPatcher/blob/master/FFTacText/PSXText.xml
enum WorldLzwSections {
	JOB_NAMES = 6,
	ITEM_NAMES = 7,
	ROSTER_UNIT_NAMES = 8,
	UNIT_NAMES2 = 9,
	BATTLE_MENUS = 10,
	HELP_TEXT = 11,
	PROPOSITION_OUTCOMES = 12,
	ABILITY_NAMES = 14,
	PROPOSITION_REWARDS = 15,
	TIPS_NAMES = 16,
	LOCATION_NAMES = 18,
	WORLD_MAP_MENU = 20,
	MAP_NAMES = 21,
	SKILLSET_NAMES = 22,
	BAR_TEXT = 23,
	TUTORIAL_NAMES = 24,
	RUMORS_NAMES = 25,
	PROPOSITION_NAMES = 26,
	UNEXPLORED_LANDS = 27,
	TREASURE = 28,
	RECORD = 29,
	PERSON = 30,
	PROPOSITION_OBJECTIVES = 31,
	}

enum BattleBinTextSections {
	EVENT_TEXT = 0,
	BATTLE_ACTION_DENIED = 2,
	BATTLE_ACTION_EFFECT = 3,
	JOB_NAMES = 6,
	ITEM_NAMES = 7,
	UNIT_NAMES = 8,
	MISC_MENU = 10,
	ROSTER_UNIT_NICKNAMES = 11,
	ABILITY_NAMES = 14,
	BATTLE_NAVIGATION_MESSAGES = 16,
	STATUSES_NAMES = 17,
	FORMATION_TEXT = 18,
	SKILLSET_NAMES = 22,
	SUMMON_DRAW_OUT_NAMES = 23,
	}

var battle_text: FftTextFile = FftTextFile.new(0xfa2dc, 32, 0xfee64, BattleBinTextSections)
var world_text: FftTextFile = FftTextFile.new(0, 32, 0, WorldLzwSections)
var file_layouts: Dictionary[String, FftTextFile] = {
	"BATTLE.BIN" : battle_text,
	"WORLD.LZW" : world_text,
	}


var ability_names: PackedStringArray = []
var spell_quotes: PackedStringArray = []
var battle_effect_text: PackedStringArray = []

var map_names: PackedStringArray = []
var location_names: PackedStringArray = []


func init_text() -> void:
	init_text_from_file("BATTLE.BIN")
	init_text_from_file("WORLD.LZW")
	
	ability_names = battle_text.text_arrays[BattleBinTextSections.ABILITY_NAMES]
	spell_quotes = text_to_string(RomReader.get_file_data("SPELL.MES"))
	battle_effect_text = battle_text.text_arrays[BattleBinTextSections.BATTLE_ACTION_EFFECT]
	
	map_names = world_text.text_arrays[WorldLzwSections.MAP_NAMES]
	location_names = world_text.text_arrays[WorldLzwSections.LOCATION_NAMES]


func init_text_from_file(file_name: String) -> void:
	var text_layout: FftTextFile = file_layouts[file_name]
	
	var offsets_bytes = RomReader.get_file_data(file_name).slice(text_layout.offsets_start, text_layout.offsets_end)
	for idx: int in text_layout.num_offsets:
		text_layout.offsets[idx] = offsets_bytes.decode_u32(idx * 4) + text_layout.offsets_end
	
	for section_name in text_layout.sections:
		var section_num: int = text_layout.sections[section_name]
		var start_offset: int = text_layout.offsets[section_num]
		if start_offset == text_layout.offsets_end and section_num != 0:
			continue
		elif section_num == text_layout.offsets.size() - 1:
			text_layout.text_arrays[section_num] = text_to_string(RomReader.get_file_data(file_name).slice(start_offset, text_layout.text_end))
		elif text_layout.offsets[section_num + 1] == text_layout.offsets_end:
			text_layout.text_arrays[section_num] = text_to_string(RomReader.get_file_data(file_name).slice(start_offset, text_layout.text_end))
		else:
			text_layout.text_arrays[section_num] = text_to_string(RomReader.get_file_data(file_name).slice(start_offset, text_layout.offsets[section_num + 1]))
		
		#push_warning(str(section_num) + " " + section_name + "\n" + str(text_layout.text_arrays[section_num]))


# https://ffhacktics.com/wiki/Font
# https://ffhacktics.com/wiki/Text_Format
static func text_to_string(bytes_text: PackedByteArray) -> PackedStringArray:
	var text : PackedStringArray = []
	
	if bytes_text.size() == 0:                        
		push_warning("No text data")
		return text
	
	
	var byte_index: int = 0
	var text_element = ""
	while byte_index < bytes_text.size():
		var char_code: int = bytes_text[byte_index]
		
		if char_code > 0xda:
			byte_index += 1
		elif char_code > 0xcf:
			var code_2bytes: String = bytes_text.slice(byte_index, byte_index + 2).hex_encode()
			char_code = code_2bytes.hex_to_int()
			#char_code = bytes_text.decode_u16(byte_index)
			byte_index += 2
		else:
			byte_index += 1
		
		if char_code == 0xfa or char_code == 0xda73: # space
			char_code = 0x20
		elif char_code == 0xe0: # code for protaganists name
			text_element += "[Ramza]"
			continue
		elif char_code == 0xe1: # code for printing unit's name
			text_element += "[UnitName]"
			continue
		elif char_code == 0xe3: # code to change color
			#text += "[UnitName]"
			byte_index += 1
			continue
		elif [0xe4, 0xe6].has(char_code): # codes for printing text variable as decimal
			text_element += "[Number]"
			if char_code == 0xe6:
				byte_index += 1
			continue
		elif [0xe5, 0xe9, 0xea, 0xeb].has(char_code): # code for printing text variable
			text_element += "[TextVariable]"
			continue
		elif char_code == 0xe8: # code to provide space for decimals?
			#text += "[UnitName]"
			byte_index += 1
			continue
		elif char_code == 0xec: # displays a portrait?
			#text += "[UnitName]"
			byte_index += 1
			continue
		elif char_code == 0xfe or char_code == 0xff: # end string TODO separate out the text
			text.append(text_element)
			text_element = ""
			continue
			#char_code = 0x0d # interpret as new line
		elif char_code == 0xfd: # code to prevent closing?
			#char_code = 0x0d # interpret as new line
			continue
		elif char_code == 0xf8: # new line
			#char_code = 0x0d # new line
			char_code = 0x20 # use a space instead of new line
		elif char_code < 10: # 0-9 are digits
			char_code += 0x30
		elif char_code < 36: # next 26 are upper case alphabet
			char_code += (0x41 - 10)
		elif char_code < 62: # next 26 are lower case alphabet
			char_code += (0x61 - 36)
		elif char_code == 62 or char_code == 0xd11a: # exclamation mark
			char_code = 0x21
		elif char_code == 63: # japanese
			char_code = 0x3042
		elif char_code == 64 or char_code == 0xd9c9: # question mark
			char_code = 0x3f
		elif char_code == 65: # japanese
			char_code = 0x3044
		elif char_code == 66 or char_code == 0xd11e: # plus sign
			char_code = 0x2b
		elif char_code == 67: # japanese
			char_code = 0x3046
		elif char_code == 68 or char_code == 0xd9c6: # forward slash
			char_code = 0x2f
		elif char_code == 69: # japanese
			char_code = 0x3048
		elif char_code == 70 or char_code == 0xd9bd: # colon
			char_code = 0x3a
		# 71 - 94 japanese # TODO
		elif char_code == 95 or char_code == 0xd11c or char_code == 0xd9b6: # period
			char_code = 0x2e
		# 96 - 138 japanese # TODO
		elif char_code == 139 or char_code == 0xd9bc: # middle dot
			char_code = 0xb7
		elif char_code == 140: # japanese
			char_code = 0x308f
		elif char_code == 141 or char_code == 0xd9be: # open parentheses
			char_code = 0x28
		elif char_code == 142 or char_code == 0xd9bf: # close parentheses
			char_code = 0x29
		# 143 - 144 japanese # TODO
		elif char_code == 145 or char_code == 0xda77 or char_code == 0xd9c0: # double quote
			char_code = 0x22
		elif char_code == 147 or char_code == 0xda76 or char_code == 0xd9c1: # single quote, apostrophe
			char_code = 0x27
		elif char_code == 178: # music note
			char_code = 0x1d160
		elif char_code == 0xd110: # counter clockwise arrow
			char_code = 0x2607
		elif char_code == 181 or char_code == 0xd111: # asterisk
			char_code = 0x2a
		elif char_code == 0xd117: # minus sign
			char_code = 0x2212
		elif char_code == 0xd118: # left corner bracket
			char_code = 0x300c
		elif char_code == 0xd11b: # ellipsis
			char_code = 0x2026
		elif char_code == 0xd11d: # hyphen-minus
			char_code = 0x2d
		elif char_code == 0xd11f: # multiplication sign
			char_code = 0xd7
		elif char_code == 0xd120: # division sign
			char_code = 0xf7
		elif char_code == 0xd123 or char_code == 0xda70: # equal sign
			char_code = 0x3d
		elif char_code == 0xd125: # greater than
			char_code = 0x3e
		elif char_code == 0xd126: # less than
			char_code = 0x3c
		elif char_code == 0xd9b5: # infinity
			char_code = 0x221e
		elif char_code == 0xd9b7: # ampersand
			char_code = 0x26
		elif char_code == 0xd9b8: # percent
			char_code = 0x25
		elif char_code == 0xd9b9: # circle
			char_code = 0x25cb
		elif char_code == 0xd9ba: # left arrow
			char_code = 0x2190
		elif char_code == 0xd9bb: # right arrow
			char_code = 0x2192
		elif char_code == 0xd9c4: # right corner bracket
			char_code = 0x300d
		elif char_code == 0xd9c5: # tilde
			char_code = 0x7e
		elif char_code == 0xd9c7: # triangle
			char_code = 0x25b3
		elif char_code == 0xd9c8: # square
			char_code = 0x25a1
		elif char_code == 0xd9ca: # heart
			char_code = 0x2665
		elif char_code >= 0xd9cb and char_code <= 0xd9cf: # roman numerals
			char_code = (char_code - 0xd9cb) + 0x2160
		elif char_code >= 0xda00 and char_code <= 0xda0b: # zodiac signs
			char_code = (char_code - 0xda00) + 0x2648
		elif char_code == 0xda0c: # serpentarius zodiac signs
			text_element += "[Serpentarius]"
			continue
		elif char_code == 0xda71: # dollar sign
			char_code = 0x24
		elif char_code == 0xda74: # comma
			char_code = 0x2c
		elif char_code == 0xda75: # semi colon
			char_code = 0x3b
		else:
			text_element += ("%x" % char_code)
			continue
		
		text_element += String.chr(char_code)
	
	return text
