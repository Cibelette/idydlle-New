extends StaticBody2D
class_name LivingArea

@export var is_placed: bool = false
@export var placeable_item_data: PlaceableItemData

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var area: Area2D = $Area2D
@onready var background: ColorRect = $ColorRect
@onready var happiness_label: Label = get_node_or_null("HappinessLabel")

signal happiness_changed(new_value: int)

var placeable_items_inside: Array[Node2D] = []
var active_habitat: Habitat = null
var inventory: Dictionary = {}
var happiness: int = 0

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
	
	GridManager.register_item(self)
	
	# Check for placeable items already inside
	_update_placeable_items_inside()
	check_habitat_recipe()

func _exit_tree():
	if Engine.is_editor_hint(): return
	GridManager.deregister_item(self)

func _on_area_2d_body_entered(body: Node2D):
	# If it's a placeable (has placeable_item_data), we track it even if not placed yet
	if "placeable_item_data" in body and not placeable_items_inside.has(body):
		placeable_items_inside.append(body)
		if "living_area" in body:
			body.living_area = self
			if body.has_method("_update_bubble"):
				body._update_bubble()
		# We don't check recipe yet because it might not be placed
		if body.is_placed:
			check_habitat_recipe()
		update_happiness()

func _on_area_2d_body_exited(body: Node2D):
	if placeable_items_inside.has(body):
		placeable_items_inside.erase(body)
		if "living_area" in body and body.living_area == self:
			body.living_area = null
			if body.has_method("_update_bubble"):
				body._update_bubble()
		check_habitat_recipe()
		update_happiness()


func _update_placeable_items_inside():
	for f in placeable_items_inside:
		if is_instance_valid(f) and "living_area" in f and f.living_area == self:
			f.living_area = null
	placeable_items_inside.clear()
	
	var zone_cells = GridManager.get_occupied_cells_for_item(self)
	print("[LivingArea] Scanning for placeable items inside zone cells: ", zone_cells)
	
	for cell in zone_cells:
		var f = GridManager.placeable_grid.get(cell)
		if is_instance_valid(f) and f.is_placed:
			if not placeable_items_inside.has(f):
				placeable_items_inside.append(f)
				if "living_area" in f:
					f.living_area = self
					if f.has_method("_update_bubble"):
						f._update_bubble()
				print("[LivingArea]   - Detected inside: ", f.name, " at cell ", cell)
	
	print("[LivingArea] Scan complete. Items found: ", placeable_items_inside.size())
	update_happiness()


func store_resource(type: Types.ResourceType, amount: int):
	if inventory.has(type):
		inventory[type] += amount
	else:
		inventory[type] = amount
	update_all_chests_bubbles()

func update_all_chests_bubbles():
	for item in placeable_items_inside:
		if is_instance_valid(item) and "placeable_item_data" in item and item.placeable_item_data:
			var data = item.placeable_item_data
			if data is FurnitureData and data.function == Types.FurnitureFunction.STORAGE:
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
	update_happiness()

func get_total_happiness() -> int:
	var total = 0
	for f in placeable_items_inside:
		if is_instance_valid(f) and "is_placed" in f and f.is_placed and "placeable_item_data" in f and f.placeable_item_data:
			var data = f.placeable_item_data
			if data is FurnitureData:
				total += data.happiness
	return total

func update_happiness():
	if not is_placed:
		if happiness_label:
			happiness_label.visible = false
		return

	if active_habitat and is_instance_valid(active_habitat):
		if happiness_label:
			happiness_label.visible = true
		
		var new_happiness = get_total_happiness()
		if new_happiness != happiness:
			happiness = new_happiness
			happiness_changed.emit(happiness)
			
		if happiness_label:
			happiness_label.text = "Happiness: " + str(happiness)
	else:
		if happiness != 0:
			happiness = 0
			happiness_changed.emit(happiness)
		if happiness_label:
			happiness_label.visible = false
