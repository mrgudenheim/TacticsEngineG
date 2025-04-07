class_name TerrainTile

# https://ffhacktics.com/wiki/Maps/Mesh#Terrain
var layer: int = 0
var location: Vector2i = Vector2i.ZERO
var surface_type_id: int = 0
var height: int = 0 # For sloped tiles, the height of the bottom of the slope
var depth: int = 0
var slope_height: int = 0 # difference between the height at the top and the height at the bottom
var slope_type_id: int = 0
var thickness: int = 0 # used for calculating ceiling: https://ffhacktics.com/wiki/Calculate_Tile_Ceiling
var no_stand_select: int = 0 # Can Walk/Cursor through this tile but not stand on it or select it. 
var shading: int = 0 # Terrain Tile Shading. 0 = Normal, 1 = Dark, 2 = Darker, 3 = Darkest
var no_walk: int = 0 # Can't walk on this tile 
var no_cursor: int = 0 # Can't move cursor to this tile 

var default_camera_position_id: int = 0 # Controls which angles the camera will auto-rotate to when a unit enters this tile. 
