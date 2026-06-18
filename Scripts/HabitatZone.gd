extends StaticBody2D
class_name HabitatZone

@export var is_placed: bool = false
@export var furniture_data: FurnitureData

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var area: Area2D = $Area2D
@onready var background: ColorRect = $ColorRect

var furniture_inside: Array[Node2D] = []
var active_habitat: Habitat = null

func _ready():
	if not is_placed:
		modulate.a = 0.5
		collision.disabled = true
	else:
		place()

func place():
	is_placed = true
	add_to_group("habitat_zones")
	modulate.a = 1.0
	collision.disabled = false
	background.show()
	# Check for furniture already inside
	_update_furniture_inside()
	check_habitat_recipe()

func _on_area_2d_body_entered(body: Node2D):
	# If it's a furniture (has furniture_data), we track it even if not placed yet
	if "furniture_data" in body and not furniture_inside.has(body):
		furniture_inside.append(body)
		# We don't check recipe yet because it might not be placed
		if body.is_placed:
			check_habitat_recipe()

func _on_area_2d_body_exited(body: Node2D):
	if furniture_inside.has(body):
		furniture_inside.erase(body)
		check_habitat_recipe()

func _update_furniture_inside():
	furniture_inside.clear()
	if not is_instance_valid(Global.current_world): return
	
	var all_furniture = get_tree().get_nodes_in_group("furniture")
	var half_size = 64.0 # For 128x128 zone
	var my_pos = global_position
	
	print("[HabitatZone] Scanning for furniture. Total in world: ", all_furniture.size())
	
	for f in all_furniture:
		if not is_instance_valid(f) or not f.is_placed: continue
		
		var f_pos = f.global_position
		# Simple AABB check
		if f_pos.x >= my_pos.x - half_size and f_pos.x <= my_pos.x + half_size \
		and f_pos.y >= my_pos.y - half_size and f_pos.y <= my_pos.y + half_size:
			if not furniture_inside.has(f):
				furniture_inside.append(f)
				print("[HabitatZone]   - Detected inside: ", f.name, " at ", f_pos)
	
	print("[HabitatZone] Scan complete. Items found: ", furniture_inside.size())

func check_habitat_recipe():
	if active_habitat:
		return
	
	if not is_placed:
		return

	# If this was called immediately after placement, we might need a tiny delay 
	# for physics/groups, but find_recipe_components_in_zone now checks is_placed property.
	HabitatManager.check_zone_for_habitat(self)

func set_habitat(habitat: Habitat):
	active_habitat = habitat
	# Link creatures to this zone? 
	# Habitat itself usually handles creature spawning.
