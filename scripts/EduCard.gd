extends TextureRect

@onready var photo_rect: TextureRect = $PhotoRect
@onready var name_label: Label = $NameLabel
@onready var latin_label: Label = $LatinLabel
@onready var desc_label: Label = $DescLabel
@onready var next_button: TextureButton = $NextButton

func _ready():
	hide() # Sembunyikan pas awal main
	next_button.pressed.connect(_on_next_button_pressed)
	
	# Tambahin efek hover dan click ke tombol Continue
	next_button.pivot_offset = next_button.size / 2.0
	next_button.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(next_button, "scale", Vector2(1.1, 1.1), 0.1)
		tween.parallel().tween_property(next_button, "modulate", Color(1.2, 1.2, 1.2), 0.1)
	)
	next_button.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(next_button, "scale", Vector2(1.0, 1.0), 0.1)
		tween.parallel().tween_property(next_button, "modulate", Color(1.0, 1.0, 1.0), 0.1)
	)
	next_button.button_down.connect(func():
		var tween = create_tween()
		tween.tween_property(next_button, "scale", Vector2(0.9, 0.9), 0.05)
		tween.parallel().tween_property(next_button, "modulate", Color(0.8, 0.8, 0.8), 0.05)
	)
	next_button.button_up.connect(func():
		var tween = create_tween()
		tween.tween_property(next_button, "scale", Vector2(1.1, 1.1), 0.1)
		tween.parallel().tween_property(next_button, "modulate", Color(1.2, 1.2, 1.2), 0.1)
	)

func show_card(data: Dictionary, snapshot: ImageTexture):
	name_label.text = data["name"].to_upper()
	latin_label.text = data["latin"]
	desc_label.text = data["desc"]
	
	if snapshot:
		photo_rect.texture = snapshot
		
	# Get the actual font from the theme
	var font = name_label.get_theme_font("font")
	
	if font:
		# Name Label (Max width: 800px, Default: 55px, Min: 24px)
		var name_size = 55
		while name_size > 24:
			var text_w = font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, name_size).x
			if text_w <= 800.0:
				break
			name_size -= 2
		name_label.add_theme_font_size_override("font_size", name_size)
		
		# Latin Label (Max width: 780px, Default: 36px, Min: 20px)
		var latin_size = 36
		while latin_size > 20:
			var text_w = font.get_string_size(latin_label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, latin_size).x
			if text_w <= 780.0:
				break
			latin_size -= 2
		latin_label.add_theme_font_size_override("font_size", latin_size)
		
		# Description Label (Max width: 780px, Max height: 230px, Default: 32px, Min: 18px)
		var desc_size = 32
		while desc_size > 18:
			# get_multiline_string_size is 100% accurate as it uses Godot's actual wrapping engine
			var text_size = font.get_multiline_string_size(desc_label.text, HORIZONTAL_ALIGNMENT_CENTER, 780.0, desc_size)
			if text_size.y <= 230.0:
				break
			desc_size -= 2
		desc_label.add_theme_font_size_override("font_size", desc_size)
	else:
		# Fallback if font is not loaded
		name_label.add_theme_font_size_override("font_size", 45)
		latin_label.add_theme_font_size_override("font_size", 28)
		desc_label.add_theme_font_size_override("font_size", 24)
	
	# Show the card with fade in
	show()
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)

func _on_next_button_pressed():
	hide()
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm:
		if gm.has_method("on_educard_next"):
			gm.on_educard_next()
		elif gm.has_method("advance_wave"):
			gm.advance_wave()
