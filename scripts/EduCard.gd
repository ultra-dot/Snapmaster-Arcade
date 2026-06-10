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
	name_label.text = data["name"]
	latin_label.text = data["latin"]
	desc_label.text = data["desc"]
	
	if snapshot:
		photo_rect.texture = snapshot
		
	# Munculin dengan animasi pop-up (fade in)
	show()
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_next_button_pressed():
	hide()
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("advance_wave"):
		gm.advance_wave()
