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

var height_mid: float = (height + slope_height) / 2.0

func duplicate() -> TerrainTile:
	var new_terrain_tile: TerrainTile = TerrainTile.new()
	
	new_terrain_tile.layer = layer
	new_terrain_tile.location = location
	new_terrain_tile.surface_type_id = surface_type_id
	new_terrain_tile.height = height 
	new_terrain_tile.depth = depth
	new_terrain_tile.slope_height = slope_height 
	new_terrain_tile.slope_type_id = slope_type_id
	new_terrain_tile.thickness = thickness 
	new_terrain_tile.no_stand_select = no_stand_select 
	new_terrain_tile.shading = shading 
	new_terrain_tile.no_walk = no_walk 
	new_terrain_tile.no_cursor = no_cursor 

	new_terrain_tile.default_camera_position_id = 0 # Controls which angles the camera will auto-rotate to when a unit enters this tile. 

	new_terrain_tile.height_mid = height + (slope_height / 2.0)
	
	return new_terrain_tile
