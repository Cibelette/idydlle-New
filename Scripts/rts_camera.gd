extends Node2D

@export var speed: float = 500.0  # Pixels per second
@export var zoom_speed: float = 0.1


func _process(delta: float):
	# 1. Get input direction using WASD (Standard UI actions)
	# Note: Ensure "left", "right", "up", "down" are mapped in Input Map
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 2. Apply movement
	position += input_direction * speed * delta
	
	# 3. Optional: Zooming with mouse wheel
	if Input.is_action_just_released("zoom_in"):
		$Camera2D.zoom += Vector2(zoom_speed, zoom_speed)
	if Input.is_action_just_released("zoom_out"):
		$Camera2D.zoom -= Vector2(zoom_speed, zoom_speed)
