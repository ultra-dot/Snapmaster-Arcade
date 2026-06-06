extends Node

@export var duck_scene: PackedScene # Fallback
@export var target_scenes: Array[PackedScene] = []
@export var zonk_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 2.0

@export_group("Heart Textures")
@export var tex_heart_full: Texture2D
@export var tex_heart_half: Texture2D
@export var tex_heart_empty: Texture2D

var score: int = 0
var current_health: int = 6 # 3 hearts * 2 halves
var max_health: int = 6
var screen_size: Vector2
var is_game_over_state: bool = false

# Wave System
var current_wave: int = 1
var ducks_per_wave: int = 5
var ducks_spawned: int = 0
var ducks_resolved: int = 0 # Count of ducks captured + escaped
var last_snapshot: ImageTexture = null

# Edu Data Dictionary
var species_data = {
	1: {"name": "Bebek Mallard", "latin": "Anas platyrhynchos", "desc": "Bebek liar yang paling umum dijumpai. Sangat mudah beradaptasi."},
	2: {"name": "Bebek Kayu", "latin": "Aix sponsa", "desc": "Bebek berbulu sangat indah yang suka bertengger di pepohonan."},
	3: {"name": "Katak Hijau", "latin": "Lithobates clamitans", "desc": "Bisa diam berjam-jam, tapi lompatannya sangat cepat!"},
	4: {"name": "Bebek Misterius", "latin": "Anatidae ignotus", "desc": "Sangat cepat dan langka. Jangan sampai lepas!"}
}

@onready var spawn_timer: Timer = $SpawnTimer
@onready var score_label: Label = $HUD/ScoreLabel
@onready var hearts_container: HBoxContainer = $HUD/HeartsContainer
@onready var hud: CanvasLayer = $HUD

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	start_wave(current_wave)
	update_hud()
	add_to_group("game_manager")
	
	# Setup button effects
	var game_over_panel = $HUD.get_node_or_null("GameOverPanel")
	if game_over_panel:
		_add_button_effects(game_over_panel.get_node_or_null("HomeButton"))
		_add_button_effects(game_over_panel.get_node_or_null("RetryButton"))
		_add_button_effects(game_over_panel.get_node_or_null("SettingButton"))

func start_wave(wave: int):
	ducks_spawned = 0
	ducks_resolved = 0
	last_snapshot = null
	
	# Increase difficulty
	spawn_interval = max(0.5, 2.0 - (wave * 0.2))
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()
	print("Starting Wave: ", wave)
	update_hud()

func register_capture(snapshot: ImageTexture):
	last_snapshot = snapshot

func duck_resolved():
	ducks_resolved += 1
	if ducks_resolved >= ducks_per_wave:
		end_wave()

func end_wave():
	if is_game_over_state: return
	
	print("Wave ", current_wave, " complete!")
	var edu_card = $HUD.get_node_or_null("EduCard")
	
	if edu_card and species_data.has(current_wave):
		# Show the educational card and pause the wave progression
		# The EduCard's "Next" button will start the next wave
		edu_card.show_card(species_data[current_wave], last_snapshot)
	else:
		# Fallback if card isn't ready or we run out of data
		await get_tree().create_timer(3.0).timeout
		current_wave += 1
		start_wave(current_wave)

func _on_spawn_timer_timeout():
	if ducks_spawned < ducks_per_wave:
		spawn_entity()
		ducks_spawned += 1
		
		if ducks_spawned >= ducks_per_wave:
			spawn_timer.stop() # Stop spawning for this wave


func spawn_entity():
	var scene_to_spawn = duck_scene
	var is_spawning_zonk = false
	
	# 20% chance to spawn a Zonk if zonk_scenes are provided
	if zonk_scenes.size() > 0 and randf() < 0.2:
		scene_to_spawn = zonk_scenes[randi() % zonk_scenes.size()]
		is_spawning_zonk = true
	elif target_scenes.size() > 0:
		scene_to_spawn = target_scenes[randi() % target_scenes.size()]
		
	if not scene_to_spawn: return
	
	var entity = scene_to_spawn.instantiate()
	
	# Randomize Size (Tiny, Normal, Giant) for Normal Targets
	if not is_spawning_zonk:
		var scale_chance = randf()
		if scale_chance < 0.15:
			# Giant (Slow, Low points)
			entity.scale *= 2.0
			entity.base_speed *= 0.5
			entity.point_value = 50
		elif scale_chance < 0.30:
			# Tiny (Fast, High points)
			entity.scale *= 0.5
			entity.base_speed *= 1.5
			entity.point_value = 300
	
	# Randomize spawn side (0 = left, 1 = right)
	var spawn_side = randi() % 2
	
	# Randomize Y position (keep it somewhat within the middle third of the screen)
	var spawn_y = randf_range(screen_size.y * 0.3, screen_size.y * 0.7)
	
	if spawn_side == 0:
		# Left spawn
		entity.global_position = Vector2(-100, spawn_y)
		entity.direction = 1
	else:
		# Right spawn
		entity.global_position = Vector2(screen_size.x + 100, spawn_y)
		entity.direction = -1
		
	# Add entity to the spawner container or main tree
	var spawner = get_node_or_null("DuckSpawner")
	if spawner:
		spawner.add_child(entity)
	else:
		add_child(entity)

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
		score_label.text = "SCORE: %05d" % score
		
	var wave_label = $HUD.get_node_or_null("WaveLabel")
	if wave_label:
		wave_label.text = "WAVE: " + str(current_wave)
		
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
	if is_game_over_state: return
	is_game_over_state = true
	print("Game Over! Final Score: ", score)
	spawn_timer.stop()
	
	var game_over_panel = $HUD.get_node_or_null("GameOverPanel")
	if game_over_panel:
		var final_score_label = game_over_panel.get_node_or_null("FinalScoreLabel")
		if final_score_label:
			final_score_label.text = "Final Score: " + str(score)
		game_over_panel.show()
	else:
		# Fallback if UI not created yet
		await get_tree().create_timer(2.0).timeout
		restart_game()

func restart_game():
	get_tree().reload_current_scene()

func return_to_menu():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

# --- FUNGSI EFEK TOMBOL OTOMATIS ---
func _add_button_effects(btn: TextureButton):
	if not btn: return
	
	# Set pivot offset to center for smooth scaling
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	
	# Efek pas mouse masuk (Hover)
	btn.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1) # Membesar
		tween.parallel().tween_property(btn, "modulate", Color(1.2, 1.2, 1.2), 0.1) # Agak terang
	)
	
	# Efek pas mouse keluar
	btn.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1) # Balik normal
		tween.parallel().tween_property(btn, "modulate", Color(1.0, 1.0, 1.0), 0.1) # Warna normal
	)
	
	# Efek pas tombol ditekan (Clicked)
	btn.button_down.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.05) # Mengecil
		tween.parallel().tween_property(btn, "modulate", Color(0.8, 0.8, 0.8), 0.05) # Agak gelap
	)
	
	# Efek pas tombol dilepas
	btn.button_up.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1) # Balik ke ukuran hover
		tween.parallel().tween_property(btn, "modulate", Color(1.2, 1.2, 1.2), 0.1)
	)
