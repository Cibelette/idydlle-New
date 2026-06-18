extends CPUParticles2D
class_name SparkleBurst

func _ready():
	# Default setup
	emitting = false
	one_shot = true
	explosiveness = 0.8
	amount = 12
	lifetime = 0.6
	
	# Gravity & velocity settings for standard sparks
	gravity = Vector2(0, 120) # Downward gravity
	direction = Vector2(0, -1) # Rise upward
	spread = 75.0 # Fan out
	initial_velocity_min = 40.0
	initial_velocity_max = 75.0
	
	# Size and shape (tiny pixel squares)
	scale_amount_min = 2.0
	scale_amount_max = 4.0
	
	# Shrink curve over lifetime
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(0.6, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	scale_amount_curve = curve
	
	# Auto-destroy once finished emitting
	get_tree().create_timer(lifetime + 0.1).timeout.connect(queue_free)

func setup(resource_type: Types.ResourceType):
	var main_color = Color(1.0, 0.9, 0.3) # Default gold
	var end_color = Color(1.0, 0.4, 0.0, 0.0)
	
	match resource_type:
		Types.ResourceType.WOOD:
			main_color = Color(0.76, 0.53, 0.34) # Wood brown
			end_color = Color(0.48, 0.28, 0.12, 0.0)
		Types.ResourceType.STONE:
			main_color = Color(0.65, 0.67, 0.72) # Stone grey
			end_color = Color(0.38, 0.39, 0.43, 0.0)
		Types.ResourceType.BERRY:
			main_color = Color(0.92, 0.16, 0.38) # Berry red
			end_color = Color(0.53, 0.04, 0.18, 0.0)
		Types.ResourceType.COINS:
			main_color = Color(0.98, 0.84, 0.23) # Gold coin yellow
			end_color = Color(0.72, 0.42, 0.0, 0.0)
		Types.ResourceType.FRUIT:
			main_color = Color(0.39, 0.80, 0.22) # Fruit green
			end_color = Color(0.18, 0.44, 0.08, 0.0)

	color = main_color
	
	# Create a bright white-hot spark gradient that fades to the resource theme color
	var ramp = Gradient.new()
	ramp.add_point(0.0, Color.WHITE)
	ramp.add_point(0.25, main_color)
	ramp.add_point(1.0, end_color)
	color_ramp = ramp
	
	# Start emitting after parameters are configured
	emitting = true
