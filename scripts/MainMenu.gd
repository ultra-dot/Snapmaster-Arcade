extends Control

# Pindah ke layar permainan
func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

# Keluar dari game
func _on_quit_button_pressed():
	get_tree().quit()
