extends Camera3D

@export var parallax_speed: Vector2 = Vector2(0.2, 0.05) 

var target_camera_2d: Camera2D = null

var initial_pos_2d: Vector2 = Vector2.ZERO
var initial_pos_3d: Vector3 = Vector3.ZERO
var is_configured: bool = false

func _ready() -> void:
	initial_pos_3d = global_position
	
	for i in range(10):
		await get_tree().process_frame
		var players = get_tree().get_nodes_in_group(&"player")
		if players.size() > 0:
			var sonic = players[0]
			if "camera" in sonic and sonic.camera != null:
				target_camera_2d = sonic.camera
				initial_pos_2d = target_camera_2d.get_screen_center_position()
				is_configured = true
				break

func _process(_delta: float) -> void:
	if not is_configured:
		var players = get_tree().get_nodes_in_group(&"player")
		if players.size() > 0:
			var sonic = players[0]
			if "camera" in sonic and sonic.camera != null:
				target_camera_2d = sonic.camera
				initial_pos_2d = target_camera_2d.get_screen_center_position()
				is_configured = true
		return
		
	var current_pos_2d = target_camera_2d.get_screen_center_position()
	var displacement_2d = current_pos_2d - initial_pos_2d
	
	var motion_3d_x = displacement_2d.x * parallax_speed.x
	var motion_3d_y = -displacement_2d.y * parallax_speed.y
	
	global_position.x = initial_pos_3d.x + motion_3d_x
	global_position.y = initial_pos_3d.y + motion_3d_y
