extends Area2D

@export var capture_time: float = 0.5
var current_capture_timer: float = 0.0
var targeted_duck: Area2D = null

# User will add this node manually later
@onready var progress_bar = get_node_or_null("TextureProgressBar")

func _process(delta):
	# Update position to follow InputManager
	global_position = InputManager.target_pos
	
	# Hold and Steady Mechanic
	if InputManager.is_trigger_held:
		var overlapping_areas = get_overlapping_areas()
		var valid_duck = null
		
		# Find first valid duck in the frame
		for area in overlapping_areas:
			if area.has_method("capture") and not area.is_captured:
				valid_duck = area
				break
				
		if valid_duck:
			if targeted_duck == valid_duck:
				# Keep focusing on the same duck
				current_capture_timer += delta
				
				# Capture triggered!
				if current_capture_timer >= capture_time:
					valid_duck.capture()
					var gm = get_tree().get_first_node_in_group("game_manager")
					if gm:
						gm.add_score(100)
					print("Snap! Captured target.")
					
					current_capture_timer = 0.0
					targeted_duck = null
			else:
				# Started looking at a new duck, reset timer
				targeted_duck = valid_duck
				current_capture_timer = 0.0
		else:
			# Holding click, but not looking at any duck
			current_capture_timer = 0.0
			targeted_duck = null
	else:
		# Not holding click, reset everything
		current_capture_timer = 0.0
		targeted_duck = null
		
	# Update UI Progress Bar if the user has added it
	if progress_bar:
		progress_bar.step = 1
		progress_bar.max_value = capture_time * 100.0
		progress_bar.value = current_capture_timer * 100.0
