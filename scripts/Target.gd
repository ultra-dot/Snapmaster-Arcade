extends Area2D

@export var point_value: int = 100
@export var is_zonk: bool = false
@export var base_speed: float = 200.0

var direction: int = 1
var is_captured: bool = false

func _ready():
	# If spawned on right side, move left
	if global_position.x > get_viewport_rect().size.x / 2:
		direction = -1
		scale.x = -abs(scale.x) # Flip sprite

func _process(delta):
	if not is_captured:
		global_position.x += base_speed * direction * delta

func capture():
	if is_captured: return
	is_captured = true
	
	var gm = get_tree().get_first_node_in_group("game_manager")
	
	if is_zonk:
		# Flash bright red
		modulate = Color(5, 0.5, 0.5) 
		if gm:
			gm.lose_life()
	else:
		# Flash bright white
		modulate = Color(2, 2, 2)
		if gm:
			gm.add_score(point_value)
	
	# Delay then delete
	await get_tree().create_timer(0.2).timeout
	if gm:
		gm.duck_resolved()
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	if not is_captured:
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm:
			if not is_zonk:
				# Only lose life if a VALID target escapes
				gm.lose_life()
			gm.duck_resolved()
		queue_free()
