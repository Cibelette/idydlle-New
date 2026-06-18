extends Node2D
class_name ResourcePopup

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func setup(resource_type: Types.ResourceType, amount: int):
	# Fetch resource visual data using ResourcesManager
	var visual_data = ResourcesManager.get_resource_data(resource_type)
	if visual_data:
		if visual_data.sprite:
			sprite_2d.texture = visual_data.sprite
		else:
			print("Warning: ResourceVisualData for '", resource_type, "' has no sprite.")
	else:
		print("Warning: No ResourceVisualData found for '", resource_type, "'")

	# Update the label text with the collected amount
	label.text = "+" + str(amount)
	
	# Design styling: Add black outline to the text for high contrast and readability on any background
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	# Layout setup: side-by-side or centered layout
	if sprite_2d.texture:
		var tex_width = sprite_2d.texture.get_size().x
		# Center the overall width: Sprite is on the left, Label is on the right
		sprite_2d.position = Vector2(-tex_width / 2.0, 0)
		label.position = Vector2(tex_width / 2.0 + 4, -label.size.y / 2.0)
	else:
		label.position = Vector2(-label.size.x / 2.0, -label.size.y / 2.0)
	
	# Ensure the popup is fully visible at spawn
	modulate.a = 1.0
	
	# Play floating and fading animation using Tween
	var tween = create_tween().set_parallel(true)
	
	# Float up from current position (e.g. 50 pixels) over 1.0 second
	tween.tween_property(self, "position", position + Vector2(0, -50), 1.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Fade out over 1.0 second
	tween.tween_property(self, "modulate:a", 0.0, 1.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
	# Clean up once the animation is done
	tween.set_parallel(false)
	tween.chain().tween_callback(queue_free)
