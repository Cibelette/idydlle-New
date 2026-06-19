extends Sprite2D
class_name BubbleIndicator

var icon_sprite: Sprite2D = null
var base_position: Vector2 = Vector2.ZERO
var bob_tween: Tween = null

func _ready():
	# Create the resource icon sprite as a child of the bubble
	icon_sprite = Sprite2D.new()
	icon_sprite.position = Vector2.ZERO
	add_child(icon_sprite)

## Set up the bubble background, offset position, and scale factor
func setup(bubble_texture: Texture2D, offset: Vector2, scale_factor: float = 1.0):
	texture = bubble_texture
	position = offset * scale_factor
	base_position = position
	z_index = 10 # Draw above other elements

## Show the bubble with a specific resource icon texture
func show_icon(icon_texture: Texture2D, icon_scale: Vector2 = Vector2(0.7, 0.7)):
	if not icon_sprite: return
	
	if icon_texture:
		icon_sprite.texture = icon_texture
		icon_sprite.scale = icon_scale
		if not visible:
			visible = true
			start_bobbing()
	else:
		hide_bubble()

## Hide the bubble indicator
func hide_bubble():
	visible = false
	stop_bobbing()

## Start a looping bobbing animation to float the bubble gently up and down
func start_bobbing():
	stop_bobbing()
	
	position = base_position
	
	bob_tween = create_tween().set_loops()
	# Float up by 3 pixels over 1.2 seconds smoothly
	bob_tween.tween_property(self, "position", base_position + Vector2(0, -3), 1.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	# Float back down
	bob_tween.tween_property(self, "position", base_position, 1.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

## Stop the bobbing animation and reset position
func stop_bobbing():
	if bob_tween:
		bob_tween.kill()
		bob_tween = null
	position = base_position
