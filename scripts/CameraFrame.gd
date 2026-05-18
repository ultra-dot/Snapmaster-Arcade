extends Area2D

func _ready():
	InputManager.photo_taken.connect(_on_photo_taken)

func _process(_delta):
	# Update position to follow InputManager
	global_position = InputManager.target_pos

func _on_photo_taken(_pos):
	# Check for overlaps
	var overlapping_areas = get_overlapping_areas()
	var captured_something = false
	
	for area in overlapping_areas:
		if area.has_method("capture") and not area.is_captured:
			area.capture()
			captured_something = true
			# Notify Game Manager to increase score (could use signal or direct call)
			var gm = get_tree().get_first_node_in_group("game_manager")
			if gm:
				gm.add_score(100)
			
	if captured_something:
		print("Snap! Captured target.")
	else:
		print("Missed!")
