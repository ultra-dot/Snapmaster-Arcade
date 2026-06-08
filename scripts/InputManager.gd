extends Node

signal photo_taken(target_pos)

var target_pos: Vector2 = Vector2.ZERO
var is_trigger_pulled: bool = false
var is_trigger_held: bool = false

# TCP Server
var tcp_server: TCPServer
var client: StreamPeerTCP
var last_packet_time: float = 0.0
var buffer: String = ""
var hand_tracking_active: bool = false

# Debounce
var fist_hold_timer: float = 0.0
const FIST_HOLD_MIN: float = 0.1

var tracker_pid: int = -1
var server_started: bool = false

func _ready():
	# Default = mouse only. Hand tracking started via Settings.
	pass

func start_hand_tracking():
	if server_started: return
	
	# Start TCP server
	tcp_server = TCPServer.new()
	var err = tcp_server.listen(5050, "127.0.0.1")
	if err != OK:
		print("InputManager: ERROR - Could not start TCP server on port 5050")
		return
	print("InputManager: TCP Server listening on 127.0.0.1:5050")
	server_started = true
	
	# Launch tracker.py headless
	var tracker_path = ProjectSettings.globalize_path("res://tracker.py")
	tracker_pid = OS.create_process("python", [tracker_path, "--headless"])
	if tracker_pid > 0:
		print("InputManager: Tracker launched (PID: ", tracker_pid, ")")
	else:
		print("InputManager: Could not launch tracker.py - run manually")

func stop_hand_tracking():
	# Kill python process
	if tracker_pid > 0:
		OS.kill(tracker_pid)
		tracker_pid = -1
		print("InputManager: Tracker killed")
	
	# Close TCP
	if client:
		client = null
	if tcp_server:
		tcp_server.stop()
		tcp_server = null
	
	server_started = false
	hand_tracking_active = false
	buffer = ""
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("InputManager: Hand tracking stopped")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if tracker_pid > 0:
			OS.kill(tracker_pid)

func _process(delta):
	var received_hand_data = false
	var raw_clicking = false
	
	# Hand tracking mode
	if server_started and tcp_server:
		if tcp_server.is_connection_available():
			client = tcp_server.take_connection()
			print("InputManager: Python tracker connected!")
		
		if client and client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			client.poll()
			var available = client.get_available_bytes()
			if available > 0:
				var data = client.get_utf8_string(available)
				buffer += data
				
				while buffer.find("\n") >= 0:
					var newline_pos = buffer.find("\n")
					var line = buffer.substr(0, newline_pos)
					buffer = buffer.substr(newline_pos + 1)
					
					var parts = line.split(",")
					if parts.size() >= 3:
						var nx = parts[0].to_float()
						var ny = parts[1].to_float()
						raw_clicking = (parts[2].to_int() == 1)
						
						var screen_size = get_viewport().get_visible_rect().size
						var raw_target = Vector2(nx * screen_size.x, ny * screen_size.y)
						
						# Speed-adaptive smoothing
						var distance = target_pos.distance_to(raw_target)
						var speed_factor = clampf(distance / 50.0, 0.0, 1.0)
						var smooth = lerpf(8.0, 60.0, speed_factor)
						target_pos = target_pos.lerp(raw_target, smooth * delta)
						
						received_hand_data = true
						last_packet_time = Time.get_ticks_msec() / 1000.0
	
	# Debounce fist
	var new_trigger_held = false
	if raw_clicking:
		fist_hold_timer = FIST_HOLD_MIN
		new_trigger_held = true
	elif fist_hold_timer > 0:
		fist_hold_timer -= delta
		new_trigger_held = true
	
	# Fallback to mouse
	var current_time = Time.get_ticks_msec() / 1000.0
	if not received_hand_data and (not server_started or current_time - last_packet_time > 0.5):
		target_pos = get_viewport().get_mouse_position()
		new_trigger_held = Input.is_action_pressed("click")
		
	# Trigger logic
	if new_trigger_held and not is_trigger_held:
		is_trigger_pulled = true
		photo_taken.emit(target_pos)
		if server_started:
			_inject_mouse_event(true)
	elif not new_trigger_held and is_trigger_held:
		is_trigger_pulled = false
		if server_started:
			_inject_mouse_event(false)
	else:
		is_trigger_pulled = false
		
	is_trigger_held = new_trigger_held
	
	# Confine mouse when hand tracking
	if server_started:
		if received_hand_data and not hand_tracking_active:
			hand_tracking_active = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		elif not received_hand_data and hand_tracking_active and (current_time - last_packet_time > 1.0):
			hand_tracking_active = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		if received_hand_data:
			Input.warp_mouse(target_pos)

func _inject_mouse_event(pressed: bool):
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = target_pos
	event.global_position = target_pos
	Input.parse_input_event(event)
