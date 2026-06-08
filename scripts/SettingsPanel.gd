extends CanvasLayer

@onready var master_slider = $Control/Panel/VBoxContainer/CenterContainer/MasterSlider
@onready var hand_toggle = $Control/Panel/VBoxContainer/HandTrackingToggle

func _ready():
	hide()
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	if hand_toggle:
		hand_toggle.button_pressed = Global.hand_tracking_enabled

func _on_master_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_hand_tracking_toggle_toggled(toggled_on: bool):
	Global.hand_tracking_enabled = toggled_on
	if toggled_on:
		InputManager.start_hand_tracking()
	else:
		InputManager.stop_hand_tracking()

func _on_close_button_pressed():
	hide()
