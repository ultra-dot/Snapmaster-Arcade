extends CanvasLayer

@onready var master_slider = $Control/Panel/VBoxContainer/CenterContainer/MasterSlider

func _ready():
	hide()
	# Set slider to current master volume
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))

func _on_master_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_close_button_pressed():
	hide()
