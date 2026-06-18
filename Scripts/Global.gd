@tool
extends Node

signal furniture_placed(item: Node2D)

var grid_size: int = 16
var current_world: Node2D

func snap_to_grid(pos: Vector2, item_size: Vector2 = Vector2(16, 16)) -> Vector2:
	var tiles_x = round(item_size.x / grid_size)
	var tiles_y = round(item_size.y / grid_size)
	
	var snap_x = 0.0
	if int(tiles_x) % 2 != 0:
		# Odd number of tiles (1, 3): snap to cell center
		snap_x = floor(pos.x / grid_size) * grid_size + (grid_size / 2.0)
	else:
		# Even number of tiles (2, 4): snap to grid line
		snap_x = round(pos.x / grid_size) * grid_size
		
	var snap_y = 0.0
	if int(tiles_y) % 2 != 0:
		snap_y = floor(pos.y / grid_size) * grid_size + (grid_size / 2.0)
	else:
		snap_y = round(pos.y / grid_size) * grid_size
		
	return Vector2(snap_x, snap_y)
