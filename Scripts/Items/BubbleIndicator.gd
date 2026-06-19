extends Sprite2D
class_name BubbleIndicator

var icon_sprite: Sprite2D = null

func _ready():
	# Create the resource icon sprite as a child of the bubble
	icon_sprite = Sprite2D.new()
	icon_sprite.position = Vector2.ZERO
	add_child(icon_sprite)

## Set up the bubble background, offset position, and scale factor
func setup(bubble_texture: Texture2D, offset: Vector2, scale_factor: float = 1.0):
	texture = bubble_texture
	position = offset * scale_factor
	z_index = 10 # Draw above other elements

## Show the bubble with a specific resource icon texture
func show_icon(icon_texture: Texture2D, icon_scale: Vector2 = Vector2(0.7, 0.7)):
	if not icon_sprite: return
	
	if icon_texture:
		icon_sprite.texture = icon_texture
		icon_sprite.scale = icon_scale
		visible = true
	else:
		visible = false

## Hide the bubble indicator
func hide_bubble():
	visible = false
