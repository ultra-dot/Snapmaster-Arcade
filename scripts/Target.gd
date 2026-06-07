extends Area2D

enum MovementType { STRAIGHT, SINE_WAVE, BOUNCE }

@export var point_value: int = 100
@export var is_zonk: bool = false
@export var is_healer: bool = false
@export var base_speed: float = 200.0
@export var movement_type: MovementType = MovementType.STRAIGHT
@export var max_hp: int = 1
@export var allowed_bounces: int = 0

var direction: int = 1
var is_captured: bool = false
var current_hp: int = 1

# Sine wave properties
var time_passed: float = 0.0
var original_y: float = 0.0
@export var sine_amplitude: float = 50.0
@export var sine_frequency: float = 5.0

# Bounce properties
var vertical_velocity: float = 0.0
@export var bounce_gravity: float = 800.0
@export var bounce_strength: float = -400.0
var floor_y: float = 0.0

func set_speed_multiplier(mult: float):
	base_speed *= mult

func _ready():
	current_hp = max_hp
	original_y = global_position.y
	# Assume floor is slightly below spawn point
	floor_y = global_position.y + 100.0 
	
	if global_position.x > get_viewport_rect().size.x / 2:
		direction = -1
		scale.x = -abs(scale.x)

func _process(delta):
	if not is_captured:
		global_position.x += base_speed * direction * delta
		
		if movement_type == MovementType.SINE_WAVE:
			time_passed += delta
			global_position.y = original_y + sin(time_passed * sine_frequency) * sine_amplitude
			
		elif movement_type == MovementType.BOUNCE:
			vertical_velocity += bounce_gravity * delta
			global_position.y += vertical_velocity * delta
			
			# Bounce logic
			if global_position.y >= floor_y:
				global_position.y = floor_y
				vertical_velocity = bounce_strength

func capture():
	if is_captured: return
	
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("sfx_camera")
		
	current_hp -= 1
	
	if current_hp > 0:
		# Just flash to indicate damage, but don't capture yet
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(10, 10, 10), 0.1)
		tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
		return
		
	is_captured = true
	var gm = get_tree().get_first_node_in_group("game_manager")
	
	if is_healer:
		modulate = Color(0.5, 2.0, 0.5)
		if gm and gm.has_method("add_life"): 
			gm.add_life()
	elif is_zonk:
		modulate = Color(5, 0.5, 0.5) 
		if gm: gm.lose_life()
	else:
		modulate = Color(2, 2, 2)
		if gm: gm.add_score(point_value)
		# Tembak musuh boss dapet shake dikit biar keren
		if gm and gm.has_method("apply_shake") and point_value >= 500:
			gm.apply_shake(0.4)
	
	await get_tree().create_timer(0.2).timeout
	if gm: gm.duck_resolved()
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited():
	if not is_captured:
		if allowed_bounces > 0:
			direction *= -1
			scale.x = -scale.x
			allowed_bounces -= 1
			return
			
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm:
			if not is_zonk:
				gm.lose_life()
			gm.duck_resolved()
		queue_free()
