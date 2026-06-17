extends Control

@export var resource_type: String = "Wood"
@export var show_name: bool = false

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	setup_counter()
	# Mettre à jour le texte immédiatement
	update_display()
	# Se connecter au signal global
	Global.ressource_inventory_updated.connect(update_display)

func setup_counter():
	var data = Global.get_resource_data(resource_type)
	if data:
		if sprite and data.sprite:
			sprite.texture = data.sprite
			sprite.region_enabled = false
	else:
		print("Warning: Resource type '", resource_type, "' not found in Global.resource_definitions")

func update_display():
	if Global.ressource_inventory.has(resource_type):
		var amount = Global.ressource_inventory[resource_type]
		var display_text = str(amount)
		
		var data = Global.get_resource_data(resource_type)
		if show_name and data:
			display_text = data.name + ": " + display_text
			
		label.text = display_text
	else:
		label.text = "N/A"
