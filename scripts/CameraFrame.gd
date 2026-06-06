extends Area2D

@export var capture_time: float = 0.5
var current_capture_timer: float = 0.0
var targeted_duck: Area2D = null

# User will add this node manually later
@onready var progress_bar = get_node_or_null("TextureProgressBar")

func _process(delta):
	# Update position to follow InputManager
	global_position = InputManager.target_pos
	
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.is_game_over_state:
		# Reset UI and stop capturing if game over
		if progress_bar: progress_bar.value = 0
		return
		
	# Hold and Steady Mechanic
	if InputManager.is_trigger_held:
		var overlapping_areas = get_overlapping_areas()
		var valid_duck = null
		
		# Find first valid duck in the frame
		for area in overlapping_areas:
			if area.has_method("capture") and not area.is_captured:
				valid_duck = area
				break
				
		if valid_duck:
			if targeted_duck == valid_duck:
				# Keep focusing on the same duck
				current_capture_timer += delta
				
				# Capture triggered!
				if current_capture_timer >= capture_time:
					# Sembunyiin 100% semua isi kamera (crosshair, progress bar)
					self.visible = false
					
					# Kasih jeda waktu super singkat (0.05 detik) biar Godot 100% yakin layarnya udah digambar ulang tanpa UI kamera
					await get_tree().create_timer(0.05).timeout
					
					# Pastiin bebeknya belum dihapus pas kita nunggu
					if is_instance_valid(valid_duck):
						var snapshot = take_snapshot(valid_duck)
						valid_duck.capture()
						if gm:
							gm.add_score(100)
							if snapshot:
								gm.register_capture(snapshot)
						print("Snap! Captured target.")
					
					# Munculin crosshair lagi
					self.visible = true
					current_capture_timer = 0.0
					targeted_duck = null
			else:
				# Started looking at a new duck, reset timer
				targeted_duck = valid_duck
				current_capture_timer = 0.0
		else:
			# Holding click, but not looking at any duck
			current_capture_timer = 0.0
			targeted_duck = null
	else:
		# Not holding click, reset everything
		current_capture_timer = 0.0
		targeted_duck = null
		
	# Update UI Progress Bar if the user has added it
	if progress_bar:
		progress_bar.step = 1
		progress_bar.max_value = capture_time * 100.0
		progress_bar.value = current_capture_timer * 100.0

func take_snapshot(target: Area2D) -> ImageTexture:
	var viewport = get_viewport()
	var img = viewport.get_texture().get_image()
	
	# Overframe size (dilebarin biar bebeknya masuk semua & estetik)
	# Ukuran ini bisa lu ganti-ganti. 250x200 biasanya pas buat resolusi 720p.
	var snapshot_width = 250
	var snapshot_height = 200
	
	# Otomatis center ke posisi bebek, bukan posisi mouse!
	var center_pos = global_position
	if target:
		center_pos = target.global_position
	
	var capture_rect = Rect2i(
		int(center_pos.x - snapshot_width/2),
		int(center_pos.y - snapshot_height/2),
		int(snapshot_width),
		int(snapshot_height)
	)
	
	# Clamp to image boundaries to prevent errors
	var img_rect = Rect2i(0, 0, img.get_width(), img.get_height())
	capture_rect = capture_rect.intersection(img_rect)
	
	if capture_rect.size.x > 0 and capture_rect.size.y > 0:
		var cropped_img = img.get_region(capture_rect)
		return ImageTexture.create_from_image(cropped_img)
	return null
