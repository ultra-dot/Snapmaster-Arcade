extends Control

var logo_original_y: float
var time_passed: float = 0.0

@onready var play_button = $PlayButton
@onready var quit_button = $QuitButton
@onready var setting_button = $SettingButton
@onready var difficulty_panel = $DifficultyPanel

func _ready():
	var hs_label = get_node_or_null("HighscoreLabel")
	if hs_label:
		hs_label.text = "BEST SCORE: " + str(Global.highscore)

	var logo = get_node_or_null("Logo")
	if logo:
		logo_original_y = logo.position.y
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm("menu")
		
	# Tambahin efek ke tombol Play
	_add_button_effects(play_button)
	# Tambahin efek ke tombol Quit
	_add_button_effects(quit_button)
	# Tambahin efek ke tombol Setting
	if setting_button:
		_add_button_effects(setting_button)
		
	if difficulty_panel:
		var btn_easy = difficulty_panel.get_node_or_null("EasyButton")
		var btn_med = difficulty_panel.get_node_or_null("MediumButton")
		var btn_hard = difficulty_panel.get_node_or_null("HardButton")
		var btn_back = difficulty_panel.get_node_or_null("BackButton")
		
		_setup_click_mask(btn_easy)
		_setup_click_mask(btn_med)
		_setup_click_mask(btn_hard)
		_setup_click_mask(btn_back)
		
		_add_button_effects(btn_easy)
		_add_button_effects(btn_med)
		_add_button_effects(btn_hard)
		_add_button_effects(btn_back)

func _setup_click_mask(btn: TextureButton):
	if btn and btn.texture_normal:
		var img = btn.texture_normal.get_image()
		var bitmap = BitMap.new()
		bitmap.create_from_image_alpha(img)
		btn.texture_click_mask = bitmap

# Pindah ke layar permainan
func _on_play_button_pressed():
	if difficulty_panel:
		difficulty_panel.show()
		play_button.hide()
		quit_button.hide()
		if setting_button:
			setting_button.hide()

func _on_back_pressed():
	if difficulty_panel:
		difficulty_panel.hide()
		play_button.show()
		quit_button.show()
		if setting_button:
			setting_button.show()

func _start_game_with_difficulty(mult: float, waves: int):
	if has_node("/root/Global"):
		var global = get_node("/root/Global")
		global.difficulty_multiplier = mult
		global.max_waves = waves
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_easy_pressed():
	_start_game_with_difficulty(1.0, 5)

func _on_medium_pressed():
	_start_game_with_difficulty(1.3, 10)

func _on_hard_pressed():
	_start_game_with_difficulty(1.6, 15)

# Buka Setting
func _on_setting_button_pressed():

	var settings = get_node_or_null("SettingsPanel")
	if settings:
		settings.show()

# Keluar dari game
func _on_quit_button_pressed():
	get_tree().quit()

# --- FUNGSI EFEK TOMBOL OTOMATIS ---
func _add_button_effects(btn: TextureButton):
	if not btn: return
	
	# Otomatis atur titik pusat zoom (pivot) tepat di tengah ukuran tombol
	btn.pivot_offset = btn.size / 2.0
	
	var original_scale = btn.scale
	
	# Efek pas mouse masuk (Hover)
	btn.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", original_scale * 1.1, 0.1) # Membesar
		tween.parallel().tween_property(btn, "modulate", Color(1.2, 1.2, 1.2), 0.1) # Agak terang
	)
	
	# Efek pas mouse keluar
	btn.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", original_scale, 0.1) # Balik normal
		tween.parallel().tween_property(btn, "modulate", Color(1.0, 1.0, 1.0), 0.1) # Warna normal
	)
	
	# Efek pas tombol ditekan (Clicked)
	btn.button_down.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", original_scale * 0.9, 0.05) # Mengecil
		tween.parallel().tween_property(btn, "modulate", Color(0.8, 0.8, 0.8), 0.05) # Agak gelap
	)
	
	# Efek pas tombol dilepas
	btn.button_up.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", original_scale * 1.1, 0.1) # Balik ke ukuran hover
		tween.parallel().tween_property(btn, "modulate", Color(1.2, 1.2, 1.2), 0.1)
	)

func _process(delta):
	time_passed += delta
	var logo = get_node_or_null("Logo")
	if logo:
		# Floating effect
		logo.position.y = logo_original_y + sin(time_passed * 2.0) * 15.0
