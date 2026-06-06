extends Control

@onready var play_button = $PlayButton
@onready var quit_button = $QuitButton

func _ready():
	# Tambahin efek ke tombol Play
	_add_button_effects(play_button)
	# Tambahin efek ke tombol Quit
	_add_button_effects(quit_button)

# Pindah ke layar permainan
func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

# Keluar dari game
func _on_quit_button_pressed():
	get_tree().quit()

# --- FUNGSI EFEK TOMBOL OTOMATIS ---
func _add_button_effects(btn: TextureButton):
	if not btn: return
	
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
