extends Area2D

@export var speed: float = 200.0
var direction: int = 1
var is_captured: bool = false

func _ready():
	# If spawned on right side, move left
	if global_position.x > get_viewport_rect().size.x / 2:
		direction = -1
		scale.x = -abs(scale.x) # Flip sprite

func _process(delta):
	if not is_captured:
		global_position.x += speed * direction * delta

func capture():
	if is_captured: return
	is_captured = true
	# Placeholder for visual feedback (e.g., flash, stop moving)
	# Play animation or change sprite color here later
	modulate = Color(2, 2, 2) # Quick flash effect
	
	# Delay then delete
	await get_tree().create_timer(0.2).timeout
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	if not is_captured:
		# Duck escaped
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm:
			gm.lose_life()
		queue_free()
