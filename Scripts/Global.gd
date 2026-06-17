@tool
extends Node

signal furniture_placed(item: Node2D)

var grid_size: int = 16

func snap_to_grid(pos: Vector2) -> Vector2:
	return (pos / grid_size).floor() * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
