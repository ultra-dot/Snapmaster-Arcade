extends Node

@export var duck_scene: PackedScene # Fallback
@export var target_scenes: Array[PackedScene] = []
@export var zonk_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 2.0

@export_group("Heart Textures")
@export var tex_heart_full: Texture2D
@export var tex_heart_half: Texture2D
@export var tex_heart_empty: Texture2D



var duck_preload = preload("res://Scenes/Duck.tscn")
var chicken_preload = preload("res://Scenes/Chicken.tscn")
var chicks_preload = preload("res://Scenes/Chicks.tscn")
var pig_preload = preload("res://Scenes/Pig.tscn")
var penguin_preload = preload("res://Scenes/Penguin.tscn")
var bear_preload = preload("res://Scenes/Bear.tscn")
var polarbear_preload = preload("res://Scenes/PolarBear.tscn")
var panglima_preload = preload("res://Scenes/Panglima.tscn")
var mushroom_preload = preload("res://Scenes/Mushroom.tscn")

var frog_preload = preload("res://Scenes/Frog.tscn")
var kitty_preload = preload("res://Scenes/Kitty.tscn")
var bat_preload = preload("res://Scenes/Bat.tscn")
var slime_preload = preload("res://Scenes/Slime.tscn")
var skeleton_preload = preload("res://Scenes/Skeleton.tscn")
var bg_wave1 = preload("res://assets/background/background.png")
var bg_wave2 = preload("res://assets/background/ladang.png")
var bg_wave3 = preload("res://assets/background/kutub.png")
var bg_wave4 = preload("res://assets/background/kerajaantua.png")

var tex_win_logo = preload("res://assets/ui/GreatWork_logo.png")
var tex_gameover_logo = preload("res://assets/buttons/game over_logo.png")

var shake_intensity: float = 0.0
var score: int = 0
var combo_count: int = 0
var combo_multiplier: float = 1.0
var current_health: int = 6 # 3 hearts * 2 halves
var max_health: int = 6
var screen_size: Vector2
var is_game_over_state: bool = false
var is_bonus_wave: bool = false

# Wave System
var current_wave: int = 1
var ducks_per_wave: int = 5
var ducks_spawned: int = 0
var ducks_resolved: int = 0 # Count of ducks captured + escaped
var max_wave: int = 5
var speed_multiplier: float = 1.0
var last_snapshot: ImageTexture = null
var shown_edu_cards: Array = []
var captured_species_this_wave: Array = []
var captured_snapshots_this_wave: Dictionary = {}
var edu_cards_queue: Array = []
var current_zonk_name: String = ""
var zonk_hit_this_wave: bool = false

# Edu Data Dictionary
var species_data = {
	"Duck": {"name": "Bebek Mallard", "latin": "Anas platyrhynchos", "desc": "Unggas air yang lincah dan berenang sangat cepat. Jangan biarkan dia kabur!"},
	"Chicken": {"name": "Ayam Ternak", "latin": "Gallus gallus domesticus", "desc": "Sangat panik jika didekati! Biasanya lari bergerombol bersama anak-anaknya."},
	"Chicks": {"name": "Anak Ayam", "latin": "Gallus gallus domesticus", "desc": "Masih kecil tapi sangat gesit! Selalu mengikuti induknya."},
	"Penguin": {"name": "Pinguin Kutub", "latin": "Aptenodytes forsteri", "desc": "Burung lucu yang beradaptasi di cuaca es ekstrem. Meluncur super cepat di atas salju."},
	"Bear": {"name": "Beruang Cokelat", "latin": "Ursus arctos", "desc": "Hewan masif yang sangat kuat! Butuh timing kamera yang pas untuk menangkap momennya."},
	"Panglima": {"name": "Panglima Orc", "latin": "Orcus bellator", "desc": "Raja dari segala hutan! Makhluk mitologi super langka yang memiliki kecepatan luar biasa."},
	"Frog": {"name": "Katak Hijau", "latin": "Lithobates clamitans", "desc": "Hewan yang sering merusak fokus lensa. Lebih baik dihindari!"},
	"Pig": {"name": "Babi Hutan", "latin": "Sus scrofa", "desc": "Hewan liar yang suka berkeliaran di semak-semak."},
	"PolarBear": {"name": "Beruang Kutub", "latin": "Ursus maritimus", "desc": "Predator puncak di wilayah salju."},
	"Kitty": {"name": "Kucing Liar", "latin": "Felis catus", "desc": "Kucing yang suka bermain di area peternakan. Lucu tapi bukan targetmu."},
	"Mushroom": {"name": "Jamur Ajaib", "latin": "Amanita muscaria", "desc": "Memotret jamur ini bisa menyembuhkan satu poin nyawa yang hilang!"},
	"Slime": {"name": "Slime Beku", "latin": "Gelatinum cryo", "desc": "Lendir dingin yang bisa membekukan kamera!"},
	"Skeleton": {"name": "Tengkorak Hidup", "latin": "Homo mortuus", "desc": "Makhluk astral yang sangat mengganggu."},
	"Bat": {"name": "Kelelawar Gua", "latin": "Chiroptera", "desc": "Penerbang malam yang sangat gesit."}
}

@onready var spawn_timer: Timer = $SpawnTimer
@onready var score_label: Label = $HUD/ScoreLabel
@onready var hearts_container: HBoxContainer = $HUD/HeartsContainer
@onready var hud: CanvasLayer = $HUD
@onready var background_layer = $BackgroundLayer
@onready var canvas_modulate = $CanvasModulate

@onready var lightning_flash = $LightningFlash
@onready var lightning_timer = $LightningTimer
@onready var camera_frame = $CameraFrame

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	screen_size = get_viewport().get_visible_rect().size

	if has_node("/root/Global"):
		var global = get_node("/root/Global")
		max_wave = global.max_waves
		speed_multiplier = global.difficulty_multiplier
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	start_wave(current_wave)
	update_hud()
	add_to_group("game_manager")

	if lightning_timer:
		lightning_timer.timeout.connect(_on_lightning_strike)	
	# Setup button effects
	var game_over_panel = $HUD.get_node_or_null("GameOverPanel")
	if game_over_panel:
		_add_button_effects(game_over_panel.get_node_or_null("HomeButton"))
		_add_button_effects(game_over_panel.get_node_or_null("RetryButton"))
		_add_button_effects(game_over_panel.get_node_or_null("SettingButton"))

func start_wave(wave: int):
	ducks_spawned = 0
	ducks_resolved = 0
	captured_snapshots_this_wave.clear()
	zonk_hit_this_wave = false
	last_snapshot = null
	
	# Play the appropriate BGM for this wave (cap at wave_4 if there are more waves)
	var track_name = "wave_" + str(min(wave, 4))
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm(track_name)
	
	
	# Environment Dynamics
	var target_bg: Texture2D
	var target_color: Color
	

	var is_final_wave = (wave == max_wave)
	var mod_wave = (wave - 1) % 3 + 1
	if is_final_wave:
		mod_wave = 4
	if mod_wave == 1:
		target_bg = bg_wave1
		target_color = Color(1.0, 1.0, 1.0)
	elif mod_wave == 2:
		target_bg = bg_wave2
		target_color = Color(1.0, 0.85, 0.7)
	elif mod_wave == 3:
		target_bg = bg_wave3
		target_color = Color(0.8, 0.85, 1.0)
	else:
		target_bg = bg_wave4
		target_color = Color(0.4, 0.35, 0.5)

		
	if background_layer:
		background_layer.texture = target_bg
	
	
	# Trigger Flashlight and Lightning
	if camera_frame and camera_frame.has_method("set_flashlight"):
		if mod_wave == 4:
			camera_frame.set_flashlight(true)
		else:
			camera_frame.set_flashlight(false)
			
	if wave >= 3:
		if lightning_timer and lightning_timer.is_stopped():
			lightning_timer.start(randf_range(3.0, 10.0))
	else:
		if lightning_timer:
			lightning_timer.stop()
	

	# Update Enemy Types Based on Wave
	if is_bonus_wave:
		ducks_per_wave = 15
		target_scenes = [duck_preload, chicken_preload, mushroom_preload, panglima_preload]
		zonk_scenes = []
		current_zonk_name = "TIDAK ADA"
		
		# Random background and frenzy effect (brighter, less yellow)
		var backgrounds = [bg_wave1, bg_wave2, bg_wave3]
		background_layer.texture = backgrounds[randi() % backgrounds.size()]
		canvas_modulate.color = Color(1.0, 1.0, 1.0) # Reset tint
		
		# Create a Shader-based Disco Blob Overlay
		var frenzy_glow = ColorRect.new()
		frenzy_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		frenzy_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var shader = Shader.new()
		shader.code = """
		shader_type canvas_item;
		render_mode blend_add;

		void fragment() {
			vec2 uv = UV;
			
			// Moving disco blobs
			float blob1 = sin(uv.x * 4.0 + TIME * 1.5) * cos(uv.y * 3.0 + TIME * 1.2);
			float blob2 = sin(uv.x * 5.0 - TIME * 1.3) * cos(uv.y * 4.0 - TIME * 1.6);
			float blob3 = sin(uv.x * 3.0 + TIME * 1.8) * cos(uv.y * 5.0 - TIME * 1.4);
			
			vec3 col = vec3(0.0);
			col += vec3(1.0, 0.1, 0.6) * smoothstep(0.1, 0.9, blob1); // Neon Pink
			col += vec3(0.1, 0.8, 1.0) * smoothstep(0.1, 0.9, blob2); // Neon Cyan
			col += vec3(0.8, 1.0, 0.1) * smoothstep(0.1, 0.9, blob3); // Neon Yellow
			
			COLOR = vec4(col, 0.4); // Additive intensity
		}
		"""
		
		var mat = ShaderMaterial.new()
		mat.shader = shader
		frenzy_glow.material = mat
		$HUD.add_child(frenzy_glow)
		
		if camera_frame and camera_frame.has_method("set_flashlight"):
			camera_frame.set_flashlight(false)
		if lightning_timer:
			lightning_timer.stop()
		
		spawn_interval = 0.5 / speed_multiplier
		spawn_timer.wait_time = spawn_interval
		spawn_timer.start()
		print("Starting BONUS WAVE!")
		update_hud()
		return

	if mod_wave == 1:
		target_scenes = [duck_preload]
		zonk_scenes = [frog_preload]
	elif mod_wave == 2:
		target_scenes = [duck_preload, chicken_preload, chicks_preload, pig_preload]
		zonk_scenes = [frog_preload, kitty_preload]
	elif mod_wave == 3:
		target_scenes = [penguin_preload, polarbear_preload]
		zonk_scenes = [slime_preload, bat_preload]
	else:
		target_scenes = [panglima_preload, bear_preload]
		zonk_scenes = [bat_preload, skeleton_preload]

	if zonk_scenes.size() > 0:
		var random_zonk = zonk_scenes[randi() % zonk_scenes.size()]
		var zonk_species = random_zonk.resource_path.get_file().get_basename()
		if zonk_species in species_data:
			current_zonk_name = species_data[zonk_species]["name"].to_upper()
		else:
			current_zonk_name = zonk_species.to_upper()
		zonk_scenes = [random_zonk] # ONLY spawn this zonk so warning makes sense!
	else:
		current_zonk_name = "JEBAKAN"
		
	if canvas_modulate:
		var tween = create_tween()
		tween.tween_property(canvas_modulate, "color", target_color, 2.0)

	# Increase difficulty
	spawn_interval = max(0.5, 2.0 - (wave * 0.2)) / speed_multiplier
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()
	print("Starting Wave: ", wave)
	update_hud()

func register_capture(snapshot: ImageTexture, target_node: Node2D = null):
	last_snapshot = snapshot
	if target_node:
		var species = ""
		if target_node.scene_file_path != "":
			species = target_node.scene_file_path.get_file().get_basename()
		else:
			species = target_node.name.rstrip("0123456789")
			
		if species not in captured_species_this_wave:
			captured_species_this_wave.append(species)
			print("Registered species: ", species)
		
		captured_snapshots_this_wave[species] = snapshot


func advance_wave():
	if current_wave == max_wave and not is_bonus_wave:
		is_bonus_wave = true
		start_wave(current_wave)
	elif is_bonus_wave:
		game_over(true)
	else:
		current_wave += 1
		start_wave(current_wave)

func duck_resolved():
	ducks_resolved += 1
	update_hud()
	if ducks_resolved >= ducks_per_wave:
		end_wave()

func end_wave():
	if is_game_over_state: return
	
	print("Wave ", current_wave, " complete!")
	update_hud() # Force HUD update to show [V] checkmarks
	
	# Delay sebentar biar pemain bisa liat ceklisnya
	await get_tree().create_timer(1.5).timeout
	
	var edu_card = $HUD.get_node_or_null("EduCard")
	
	edu_cards_queue.clear()
	if edu_card:
		for species in captured_species_this_wave:
			if species in species_data and species not in shown_edu_cards:
				edu_cards_queue.append(species)
				shown_edu_cards.append(species) # Mark as shown immediately so we don't queue duplicates
				
	captured_species_this_wave.clear()
				
	if edu_cards_queue.size() > 0:
		show_next_edu_card()
	else:
		# Fallback if card isn't ready or no new species
		advance_wave()

func show_next_edu_card():
	var edu_card = $HUD.get_node_or_null("EduCard")
	if edu_card and edu_cards_queue.size() > 0:
		var species_to_show = edu_cards_queue.pop_front()
		var species_snapshot = captured_snapshots_this_wave.get(species_to_show, last_snapshot)
		edu_card.show_card(species_data[species_to_show], species_snapshot)
	else:
		advance_wave()

func on_educard_next():
	show_next_edu_card()

func _on_spawn_timer_timeout():
	if ducks_spawned < ducks_per_wave:
		spawn_entity()
		ducks_spawned += 1
		
		if ducks_spawned >= ducks_per_wave:
			spawn_timer.stop() # Stop spawning for this wave


func spawn_entity():
	var scene_to_spawn = duck_scene
	var is_spawning_zonk = false
	var is_spawning_healer = false
	
	# 5% chance to spawn a Mushroom (Healer)
	if randf() < 0.05:
		scene_to_spawn = mushroom_preload
		is_spawning_healer = true
	# 20% chance to spawn a Zonk if zonk_scenes are provided
	elif zonk_scenes.size() > 0 and randf() < 0.2:
		scene_to_spawn = zonk_scenes[randi() % zonk_scenes.size()]
		is_spawning_zonk = true
	elif target_scenes.size() > 0:
		scene_to_spawn = target_scenes[randi() % target_scenes.size()]
		
	if not scene_to_spawn: return
	
	var entity = scene_to_spawn.instantiate()
	
	# Randomize Size (Tiny, Normal, Giant) for Normal Targets
	if not is_spawning_zonk and not is_spawning_healer:
		var scale_chance = randf()
		if scale_chance < 0.15:
			# Giant (Slow, Low points)
			entity.scale *= 2.0
			entity.base_speed *= 0.5
			entity.point_value = 50
		elif scale_chance < 0.30:
			# Tiny (Fast, High points)
			entity.scale *= 0.75
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
	combo_count += 1
	combo_multiplier = 1.0 + (combo_count * 0.2)
	var final_amount = int(amount * combo_multiplier)
	score += final_amount
	update_hud()
	show_combo_popup()

func lose_life():
	zonk_hit_this_wave = true
	combo_count = 0
	combo_multiplier = 1.0
	apply_shake(1.0)
	update_hud()
	current_health -= 1
	if current_health <= 0:
		game_over(false)

func add_life():
	if current_health < max_health:
		current_health = min(current_health + 2, max_health)
		update_hud()
		# Tampilkan popup "+1 NYAWA"
		var popup = Label.new()
		popup.text = "+1 NYAWA!"
		popup.add_theme_font_size_override("font_size", 30)
		popup.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		popup.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		popup.add_theme_constant_override("outline_size", 8)
		popup.position = Vector2(screen_size.x / 2 - 80, screen_size.y / 2)
		$HUD.add_child(popup)
		var tween = create_tween()
		tween.tween_property(popup, "position:y", popup.position.y - 100, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.0)
		tween.tween_callback(popup.queue_free)

func update_hud():
	if score_label:
		score_label.text = "SCORE: %05d" % score
		
	var wave_label = $HUD.get_node_or_null("WaveLabel")
	if wave_label:
		wave_label.text = "BONUS WAVE" if is_bonus_wave else "WAVE: " + str(current_wave)
		
	var combo_label = $HUD.get_node_or_null("ComboLabel")
	if combo_label:
		combo_label.text = "COMBO: " + str(combo_count)
		if combo_count > 1:
			combo_label.text += " (x" + str(snapped(combo_multiplier, 0.1)) + ")"
		
	var task_holder = $HUD.get_node_or_null("TaskHolder")
	var task_shadow = $HUD.get_node_or_null("TaskHolderShadow")
	if task_holder:
		if is_bonus_wave:
			task_holder.hide()
			if task_shadow: task_shadow.hide()
		else:
			task_holder.show()
			if task_shadow: task_shadow.show()

	var task_label = $HUD.get_node_or_null("TaskHolder/TaskLabel")
	if task_label:
		if current_health <= 0:
			task_label.text = "[center][color=#ff5555][X][/color] MISI GAGAL[/center]"
		elif ducks_resolved >= ducks_per_wave:
			var zonk_box = "[color=#ff5555][X][/color]" if zonk_hit_this_wave else "[color=#55ff55][V][/color]"
			task_label.text = "[center][color=#55ff55][V][/color] SEMUA TARGET TUNTAS!\n" + zonk_box + " AWAS " + current_zonk_name + "![/center]"
		else:
			var zonk_box = "[color=#ff5555][X][/color]" if zonk_hit_this_wave else "[ ]"
			task_label.text = "[center][ " + str(ducks_resolved) + " / " + str(ducks_per_wave) + " ] HEWAN LEWAT\n" + zonk_box + " AWAS " + current_zonk_name + "![/center]"
		
	if hearts_container:
		if is_bonus_wave:
			hearts_container.hide()
		else:
			hearts_container.show()
			
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

func game_over(is_win: bool = false):
	if is_game_over_state: return
	is_game_over_state = true
	print("Game Over! Final Score: ", score)
	spawn_timer.stop()

	if has_node("/root/AudioManager"):
		AudioManager.active_player.stop()
	
	var game_over_panel = $HUD.get_node_or_null("GameOverPanel")
	if game_over_panel:
		var final_score_label = game_over_panel.get_node_or_null("FinalScoreLabel")
		if final_score_label:
			final_score_label.text = "Final Score: " + str(score)
		game_over_panel.show()

		var game_over_image = game_over_panel.get_node_or_null("GameOverImage")
		if game_over_image:
			if is_win:
				game_over_image.texture = tex_win_logo
				spawn_confetti()
				if has_node("/root/AudioManager"):
					if score >= 5000:
						AudioManager.play_sfx("sfx_victory2")
					else:
						AudioManager.play_sfx("sfx_victory1")
			else:
				if has_node("/root/AudioManager"):
					AudioManager.play_sfx("sfx_gameover")
				game_over_image.texture = tex_gameover_logo

		var game_over_label = game_over_panel.get_node_or_null("Label")
		if game_over_label:
			if is_win:
				game_over_label.text = "YOU WIN!"
				game_over_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
			else:
				game_over_label.text = "GAME OVER"
				game_over_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

		# Handle Highscore Update
		var is_new_highscore = false
		if score > Global.highscore:
			Global.highscore = score
			Global.save_highscore()
			is_new_highscore = true
			
		_set_game_over_layout(is_new_highscore)
			
		var hs_label = game_over_panel.get_node_or_null("NewHighscoreLabel")
		if hs_label:
			if is_new_highscore:
				hs_label.show()
				hs_label.pivot_offset = hs_label.size / 2.0
				var hs_tween = create_tween().set_loops()
				hs_tween.tween_property(hs_label, "scale", Vector2(1.1, 1.1), 1.0).set_trans(Tween.TRANS_SINE)
				hs_tween.tween_property(hs_label, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)
			else:
				hs_label.hide()

	else:
		# Fallback if UI not created yet
		await get_tree().create_timer(2.0).timeout
		restart_game()

func restart_game():
	get_tree().reload_current_scene()

func return_to_menu():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_setting_button_pressed():
	var settings = $HUD.get_node_or_null("SettingsPanel")
	if settings:
		settings.show()

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


func _on_lightning_strike():
	if is_game_over_state or current_wave < 3: return
	
	if lightning_flash:
		var tween = create_tween()
		# Flash up
		tween.tween_property(lightning_flash, "modulate:a", 0.8, 0.05)
		# Fade out quickly
		tween.tween_property(lightning_flash, "modulate:a", 0.0, 0.3)
		
		# Optional double flash
		if randf() > 0.5:
			tween.tween_property(lightning_flash, "modulate:a", 0.6, 0.05)
			tween.tween_property(lightning_flash, "modulate:a", 0.0, 0.2)
			
	# Restart timer for next strike
	if lightning_timer:
		lightning_timer.start(randf_range(5.0, 15.0))

func show_combo_popup():
	if combo_count < 2: return
	
	var popup = Label.new()
	popup.text = "COMBO x" + str(combo_count) + "!"
	popup.add_theme_font_size_override("font_size", 40 + (combo_count * 5))
	popup.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	popup.add_theme_constant_override("outline_size", 8)
	
	# Position roughly center top
	popup.position = Vector2(screen_size.x / 2 - 100, screen_size.y / 2 - 200)
	$HUD.add_child(popup)
	
	var tween = create_tween()
	tween.tween_property(popup, "position:y", popup.position.y - 100, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tween.tween_callback(popup.queue_free)

func _process(delta):
	if shake_intensity > 0:
		shake_intensity = move_toward(shake_intensity, 0.0, delta * 3.0)
		var cam = get_node_or_null("Camera2D")
		if cam:
			cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity * 40.0
	else:
		var cam = get_node_or_null("Camera2D")
		if cam: cam.offset = Vector2.ZERO

	# Handle mouse visibility dynamically
	var hud = get_node_or_null("HUD")
	var is_ui_active = is_game_over_state or is_paused or (hud and hud.get_node_or_null("SettingsPanel") and hud.get_node("SettingsPanel").visible) or (hud and hud.get_node_or_null("EduCard") and hud.get_node("EduCard").visible)
	
	if is_ui_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func apply_shake(intensity: float = 1.0):
	shake_intensity = max(shake_intensity, intensity)

func spawn_confetti():
	var colors = [Color.RED, Color.YELLOW, Color.GREEN, Color.CYAN, Color.MAGENTA, Color.ORANGE]
	for c in colors:
		var confetti = CPUParticles2D.new()
		confetti.position = Vector2(screen_size.x / 2, -50)
		confetti.amount = 40
		confetti.lifetime = 5.0
		confetti.one_shot = true
		confetti.explosiveness = 0.9
		confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		confetti.emission_rect_extents = Vector2(screen_size.x / 2, 1)
		confetti.direction = Vector2(0, 1)
		confetti.spread = 180.0
		confetti.gravity = Vector2(0, 500)
		confetti.initial_velocity_min = 200.0
		confetti.initial_velocity_max = 600.0
		confetti.angular_velocity_min = -300.0
		confetti.angular_velocity_max = 300.0
		confetti.scale_amount_min = 10.0
		confetti.scale_amount_max = 20.0
		confetti.color = c
		$HUD.add_child(confetti)
		# Biar confetti hancur sendiri setelah kelar
		get_tree().create_timer(5.5).timeout.connect(confetti.queue_free)


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_N:
			print("[DEV MODE] Skipping to next wave...")
			advance_wave()
		elif event.keycode == KEY_B:
			print("[DEV MODE] Jumping to Bonus Wave!")
			current_wave = max_wave
			is_bonus_wave = true
			start_wave(current_wave)
		elif event.keycode == KEY_ESCAPE:
			toggle_pause()

var is_paused: bool = false

func toggle_pause():
	if is_game_over_state: return
	
	var game_over_panel = $HUD.get_node_or_null("GameOverPanel")
	if not game_over_panel: return
	
	is_paused = !is_paused
	
	if is_paused:
		get_tree().paused = true
		spawn_timer.stop()
		
		# Apply shifted-up layout since there is no highscore label shown
		_set_game_over_layout(false)
		
		# Show panel without game over stuff
		var game_over_image = game_over_panel.get_node_or_null("GameOverImage")
		if game_over_image: game_over_image.hide()
		
		var game_over_label = game_over_panel.get_node_or_null("Label")
		if game_over_label:
			game_over_label.text = "PAUSED"
			game_over_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		
		var final_score_label = game_over_panel.get_node_or_null("FinalScoreLabel")
		if final_score_label:
			final_score_label.text = "Score: " + str(score)
		
		var hs_label = game_over_panel.get_node_or_null("NewHighscoreLabel")
		if hs_label: hs_label.hide()
		
		game_over_panel.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		game_over_panel.hide()
		get_tree().paused = false
		spawn_timer.start()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _set_game_over_layout(has_highscore: bool):
	var panel = $HUD.get_node_or_null("GameOverPanel")
	if not panel: return
	
	var final_score_label = panel.get_node_or_null("FinalScoreLabel")
	var setting_btn = panel.get_node_or_null("SettingButton")
	var retry_btn = panel.get_node_or_null("RetryButton")
	var home_btn = panel.get_node_or_null("HomeButton")
	
	if has_highscore:
		if final_score_label:
			final_score_label.offset_top = 30
			final_score_label.offset_bottom = 70
		if setting_btn:
			setting_btn.offset_top = 90
			setting_btn.offset_bottom = 150
		if retry_btn:
			retry_btn.offset_top = 170
			retry_btn.offset_bottom = 240
		if home_btn:
			home_btn.offset_top = 170
			home_btn.offset_bottom = 240
	else:
		if final_score_label:
			# Shifted up directly under the wood board
			final_score_label.offset_top = -20
			final_score_label.offset_bottom = 20
		if setting_btn:
			setting_btn.offset_top = 40
			setting_btn.offset_bottom = 100
		if retry_btn:
			retry_btn.offset_top = 120
			retry_btn.offset_bottom = 190
		if home_btn:
			home_btn.offset_top = 120
			home_btn.offset_bottom = 190
