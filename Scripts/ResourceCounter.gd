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
	ResourcesManager.inventory_updated.connect(update_display)

func setup_counter():
	var data = ResourcesManager.get_resource_data(resource_type)
	if data:
		if sprite and data.sprite:
			sprite.texture = data.sprite
			sprite.region_enabled = false
	else:
		print("Warning: Resource type '", resource_type, "' not found in ResourcesManager.resource_definitions")

func update_display():
	var amount = ResourcesManager.get_amount(resource_type)
	var display_text = str(amount)
	
	var data = ResourcesManager.get_resource_data(resource_type)
	if show_name and data:
		display_text = data.name + ": " + display_text
		
	label.text = display_text
