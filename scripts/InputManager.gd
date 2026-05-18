extends Node

signal photo_taken(target_pos)

var target_pos: Vector2 = Vector2.ZERO
var is_trigger_pulled: bool = false # Kept for Phase 1 compatibility if needed, but signal is better.
var is_trigger_held: bool = false

func _process(_delta):
	# Update target position based on mouse for Phase 1
	target_pos = get_viewport().get_mouse_position()
	
	is_trigger_pulled = Input.is_action_just_pressed("click")
	is_trigger_held = Input.is_action_pressed("click")
	
	if is_trigger_pulled:
		photo_taken.emit(target_pos)
