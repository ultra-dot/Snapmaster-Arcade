extends Node

@export var duck_scene: PackedScene
@export var spawn_interval: float = 2.0

@export_group("Heart Textures")
@export var tex_heart_full: Texture2D
@export var tex_heart_half: Texture2D
@export var tex_heart_empty: Texture2D

var score: int = 0
var current_health: int = 6 # 3 hearts * 2 halves
var max_health: int = 6
var screen_size: Vector2

@onready var spawn_timer: Timer = $SpawnTimer
@onready var score_label: Label = $HUD/ScoreLabel
@onready var hearts_container: HBoxContainer = $HUD/HeartsContainer

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	update_hud()
	
	# Add GameManager to group for easy access
	add_to_group("game_manager")

func _on_spawn_timer_timeout():
	spawn_duck()

func spawn_duck():
	if not duck_scene: return
	
	var duck = duck_scene.instantiate()
	
	# Randomize spawn side (0 = left, 1 = right)
	var spawn_side = randi() % 2
	
	# Randomize Y position (keep it somewhat within the middle third of the screen)
	var spawn_y = randf_range(screen_size.y * 0.3, screen_size.y * 0.7)
	
	if spawn_side == 0:
		# Left spawn
		duck.global_position = Vector2(-100, spawn_y)
		duck.direction = 1
	else:
		# Right spawn
		duck.global_position = Vector2(screen_size.x + 100, spawn_y)
		duck.direction = -1
		duck.scale.x = -abs(duck.scale.x) # Flip sprite
		
	# Add duck to the spawner container or main tree
	var spawner = get_node_or_null("DuckSpawner")
	if spawner:
		spawner.add_child(duck)
	else:
		add_child(duck)

func add_score(amount: int):
	score += amount
	update_hud()

func lose_life():
	current_health -= 1
	update_hud()
	if current_health <= 0:
		game_over()

func update_hud():
	if score_label:
		# Format score with leading zeros
		score_label.text = "SCORE: %05d" % score
		
	if hearts_container:
		# Update heart textures based on current health (Zelda style)
		var hearts = hearts_container.get_children()
		for i in range(hearts.size()):
			# Each heart represents 2 health points
			var heart_val = current_health - (i * 2)
			
			if heart_val >= 2:
				hearts[i].texture = tex_heart_full
			elif heart_val == 1:
				hearts[i].texture = tex_heart_half
			else:
				hearts[i].texture = tex_heart_empty

func game_over():
	print("Game Over! Final Score: ", score)
	spawn_timer.stop()
	# For now, just restart after 2 seconds
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
