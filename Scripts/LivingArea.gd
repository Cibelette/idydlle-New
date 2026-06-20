extends StaticBody2D
class_name LivingArea

@export var is_placed: bool = false
@export var furniture_data: FurnitureData

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var area: Area2D = $Area2D
@onready var background: ColorRect = $ColorRect

var furniture_inside: Array[Node2D] = []
var active_habitat: Habitat = null
var inventory: Dictionary = {}

func _ready():
	if not is_placed:
		modulate.a = 0.5
		collision.disabled = true
	else:
		place()

func place():
	is_placed = true
	add_to_group("living_areas")
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
		if "living_area" in body:
			body.living_area = self
			if body.has_method("_update_bubble"):
				body._update_bubble()
		# We don't check recipe yet because it might not be placed
		if body.is_placed:
			check_habitat_recipe()

func _on_area_2d_body_exited(body: Node2D):
	if furniture_inside.has(body):
		furniture_inside.erase(body)
		if "living_area" in body and body.living_area == self:
			body.living_area = null
			if body.has_method("_update_bubble"):
				body._update_bubble()
		check_habitat_recipe()


func _update_furniture_inside():
	for f in furniture_inside:
		if is_instance_valid(f) and "living_area" in f and f.living_area == self:
			f.living_area = null
	furniture_inside.clear()
	if not is_instance_valid(Global.current_world): return
	
	# Determine bounds dynamically from CollisionShape2D
	var shape_size = Vector2(256.0, 256.0) # Fallback size
	var zone_center = global_position + Vector2(64.0, 64.0) # Fallback center
	
	if collision and collision.shape is RectangleShape2D:
		shape_size = collision.shape.size
		zone_center = collision.global_position
		
	var half_size = shape_size / 2.0
	
	var all_furniture = get_tree().get_nodes_in_group("furniture")
	print("[LivingArea] Scanning for furniture. Total in world: ", all_furniture.size())
	
	for f in all_furniture:
		if not is_instance_valid(f) or not f.is_placed: continue
		
		var f_pos = f.global_position
		# AABB check based on CollisionShape2D bounds
		if f_pos.x >= zone_center.x - half_size.x and f_pos.x <= zone_center.x + half_size.x \
		and f_pos.y >= zone_center.y - half_size.y and f_pos.y <= zone_center.y + half_size.y:
			if not furniture_inside.has(f):
				furniture_inside.append(f)
				if "living_area" in f:
					f.living_area = self
					if f.has_method("_update_bubble"):
						f._update_bubble()
				print("[LivingArea]   - Detected inside: ", f.name, " at ", f_pos)
	
	print("[LivingArea] Scan complete. Items found: ", furniture_inside.size())

func store_resource(type: Types.ResourceType, amount: int):
	if inventory.has(type):
		inventory[type] += amount
	else:
		inventory[type] = amount
	update_all_chests_bubbles()

func update_all_chests_bubbles():
	for item in furniture_inside:
		if is_instance_valid(item) and "furniture_data" in item and item.furniture_data:
			if item.furniture_data.furniture_type == Types.FurnitureType.STORAGE:
				if item.has_method("_update_bubble"):
					item._update_bubble()


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
