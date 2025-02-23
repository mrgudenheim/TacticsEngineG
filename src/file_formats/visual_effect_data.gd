class_name VisualEffectData

# https://ffhacktics.com/wiki/Effect_Files
# https://ffhacktics.com/wiki/Effect_Data


var sprite: Image
var sprite_format: int = 8 # 8bpp or 4bpp
var image_height: int = 0 # pixels
var image_width = sprite_format * 16 # unless

# SINGLE - camera will point at the targeted location
# SEQUENTIAL - camera will move between each each target
# MULTI - camera will point at a single location, but make sure all targets are in view
enum camera_focus {SINGLE, SEQUENTIAL, MULTI} 

var sound_effects
var partical_effects
