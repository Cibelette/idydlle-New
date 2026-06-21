extends Node
class_name NaturalResourceComponent

@onready var parent: PlaceableItem = get_parent()

func _ready():
	# Start production if the parent is already placed
	if parent.is_placed:
		start_production()

func start_production():
	var timer = Timer.new()
	timer.name = "ProductionTimer"
	add_child(timer)
	timer.timeout.connect(_on_production_timeout)
	timer.wait_time = _calculate_production_interval()
	timer.start()

func _calculate_production_interval() -> float:
	var data = parent.placeable_item_data as NaturalResourceData
	if not data: return 1.0
	
	var multiplier = 1.0
	var zone = parent._get_current_living_area()
	
	if zone and is_instance_valid(zone.active_habitat):
		var habitat = zone.active_habitat
		if habitat.has_method("spawn_creatures_clean_up"):
			habitat.spawn_creatures_clean_up()
			
		for creature in habitat.spawned_creatures:
			if is_instance_valid(creature) and creature.data and creature.data.resource_type == data.resource_type:
				multiplier = creature.data.produce_time
				break
				
		var happiness = zone.happiness
		if happiness > 0:
			var speed_buff = 1.0 - clamp(happiness * 0.01, 0.0, 0.75)
			multiplier *= speed_buff
				
	return data.produce_time * multiplier

func _on_production_timeout():
	var data = parent.placeable_item_data as NaturalResourceData
	if not data: return
	
	var zone = parent._get_current_living_area()
	if zone and is_instance_valid(zone.active_habitat):
		var has_chest = false
		for item in zone.placeable_items_inside:
			if is_instance_valid(item) and "placeable_item_data" in item and item.placeable_item_data:
				var p_data = item.placeable_item_data
				if p_data is FurnitureData and p_data.function == Types.FurnitureFunction.STORAGE:
					has_chest = true
					break
					
		if not has_chest:
			return
			
		var habitat = zone.active_habitat
		for creature in habitat.spawned_creatures:
			if is_instance_valid(creature) and creature.data and creature.data.resource_type == data.resource_type:
				if creature.has_method("produce_from_source"):
					creature.produce_from_source(parent)
		
		var timer = $ProductionTimer
		if timer:
			timer.wait_time = _calculate_production_interval()
	else:
		var timer = $ProductionTimer
		if timer:
			timer.wait_time = data.produce_time if data.produce_time > 0 else 1.0
