extends TextureRect

@onready var photo_rect: TextureRect = $PhotoRect
@onready var name_label: Label = $NameLabel
@onready var latin_label: Label = $LatinLabel
@onready var desc_label: RichTextLabel = $DescLabel
@onready var next_button: Button = $NextButton

func _ready():
	hide() # Sembunyikan pas awal main
	next_button.pressed.connect(_on_next_button_pressed)

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
	if gm:
		gm.current_wave += 1
		gm.start_wave(gm.current_wave)
