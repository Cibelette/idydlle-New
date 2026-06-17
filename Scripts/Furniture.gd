@tool
extends StaticBody2D

@export var is_placed: bool = false
@export var furniture_data: FurnitureData

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	if Engine.is_editor_hint():
		set_notify_transform(true)
		return

	if is_placed:
		# If checked in Inspector, finalize immediately
		place()
	else:
		# Initially, collision is disabled while we are placing it
		collision.disabled = true
		# Give it some transparency to show it's a "ghost"
		modulate.a = 0.5

func _notification(what):
	if Engine.is_editor_hint():
		if what == NOTIFICATION_TRANSFORM_CHANGED:
			# Only snap if we are not being actively dragged (optional refinement)
			# For simplicity, we snap whenever transform changes in editor
			global_position = (global_position / 16.0).floor() * 16.0 + Vector2(8, 8)

func place():
	is_placed = true
	add_to_group("furniture")
	collision.disabled = false
	modulate.a = 1.0
	# Set the Z index or layer if necessary to ensure it's behind/in front of things
	z_index = int(global_position.y) 
	
	# Update navigation obstacle if it exists
	var obstacle = get_node_or_null("NavigationObstacle2D")
	if obstacle:
		obstacle.avoidance_enabled = true
