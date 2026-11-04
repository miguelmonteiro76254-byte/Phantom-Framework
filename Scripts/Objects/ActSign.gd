extends Node2D

signal triggered
signal landed
signal act_cleared

enum TriggerMode { PASS_BY, TOUCH }

@export_group("Nodes")
@export var board: Node2D
@export var animation_player: AnimationPlayer
@export var spin_sound: AudioStreamPlayer
@export var clear_sound: AudioStreamPlayer
@export var touch_area: Area2D

@export_group("Animations")
@export var anim_idle: StringName = &"eggman"
@export var anim_spin: StringName = &"spinning"
@export var anim_end: StringName = &"sonic"

@export_group("Trigger")
@export var trigger_mode: TriggerMode = TriggerMode.PASS_BY
@export var trigger_vertical_range := 512.0
@export var touch_rect := Rect2(-24.0, -48.0, 48.0, 96.0)
@export_file("*.tscn") var next_scene: String

@export_group("Spin")
@export var spin_time := 2.0
@export var hop_height := 48.0
@export_range(0.05, 0.95) var hop_up_fraction := 0.35

@export_group("Camera")
@export var lock_camera := true
@export var camera_offset := Vector2(0.0, -32.0)
@export var wall_layer := 1
@export var wall_thickness := 128.0
@export var wall_reach := 4096.0

@export_group("Finish")
@export var stop_delay := 1.0
@export var post_audio_delay := 1.0

var player: Node2D
var _triggered := false
var _board_rest := Vector2.ZERO


func _ready() -> void:
	if board == null:
		board = get_node_or_null("Board") as Node2D
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if spin_sound == null:
		spin_sound = get_node_or_null("SpinSound") as AudioStreamPlayer
	if clear_sound == null:
		clear_sound = get_node_or_null("ClearSound") as AudioStreamPlayer
	if touch_area == null:
		touch_area = get_node_or_null("TouchArea") as Area2D
	if board != null:
		_board_rest = board.position
	if trigger_mode == TriggerMode.TOUCH and touch_area != null:
		touch_area.body_entered.connect(_on_touch_body_entered)
	_play(anim_idle)


func _physics_process(_delta: float) -> void:
	if _triggered:
		return
	if player == null:
		player = get_tree().get_first_node_in_group(&"player") as Node2D
		if player == null:
			return
	if player.call("is_dead"):
		return
	match trigger_mode:
		TriggerMode.PASS_BY:
			if _player_passed():
				_trigger()
		TriggerMode.TOUCH:
			if touch_area == null and _player_touching():
				_trigger()


func _player_passed() -> bool:
	if player.global_position.x < global_position.x:
		return false
	return absf(player.global_position.y - global_position.y) <= trigger_vertical_range


func _player_touching() -> bool:
	var p := player.global_position
	var c: Variant = player.get("col")
	if c is Node2D:
		p = (c as Node2D).global_position
	var rect := Rect2(global_position + touch_rect.position, touch_rect.size)
	return rect.has_point(p)


func _on_touch_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group(&"player"):
		return
	if body.call("is_dead"):
		return
	player = body
	_trigger()


func _trigger() -> void:
	if _triggered:
		return
	_triggered = true
	_run_sequence()


func _run_sequence() -> void:
	triggered.emit()
	_stop_level_music()
	if spin_sound != null:
		spin_sound.play()
	if lock_camera:
		_lock_camera()
	_play(anim_spin)
	_hop_board()

	await _wait_spin_end()
	_play(anim_end)
	landed.emit()

	await get_tree().create_timer(stop_delay).timeout
	if is_instance_valid(player) and not player.call("is_dead"):
		player.call("finish_act")
	act_cleared.emit()

	await _wait_for_sound(spin_sound)
	if clear_sound != null:
		clear_sound.play()
	await _wait_for_sound(clear_sound)
	await get_tree().create_timer(post_audio_delay).timeout
	_change_scene()


func _hop_board() -> void:
	if board == null:
		return
	var tw := create_tween()
	tw.tween_property(board, "position:y", _board_rest.y - hop_height, spin_time * hop_up_fraction) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(board, "position:y", _board_rest.y, spin_time * (1.0 - hop_up_fraction)) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _wait_spin_end() -> void:
	if animation_player != null and animation_player.has_animation(anim_spin):
		var anim := animation_player.get_animation(anim_spin)
		if anim.loop_mode == Animation.LOOP_NONE:
			while true:
				var finished_name: StringName = await animation_player.animation_finished
				if finished_name == anim_spin:
					return
	await get_tree().create_timer(spin_time).timeout


func _wait_for_sound(sound: AudioStreamPlayer) -> void:
	if sound != null and sound.playing:
		await sound.finished


func _change_scene() -> void:
	if next_scene.is_empty():
		push_warning("%s: no scene bro." % name)
		return
	ScreenFade.change_scene(next_scene)


func _stop_level_music() -> void:
	var level := get_tree().get_first_node_in_group(&"level")
	if level != null and level.has_method("stop_music"):
		level.call("stop_music")


func _lock_camera() -> void:
	player.call("lock_camera_to", global_position + camera_offset)
	var cam := player.get("camera") as Camera2D
	if cam != null:
		_build_right_wall(cam)


func _build_right_wall(cam: Camera2D) -> void:
	var half_w := get_viewport_rect().size.x / cam.zoom.x * 0.5
	var x := minf(global_position.x + half_w, float(cam.limit_right))
	var body := StaticBody2D.new()
	body.name = "ActEndWall"
	body.top_level = true
	body.collision_layer = wall_layer
	body.collision_mask = 0
	add_child(body)
	body.position = Vector2.ZERO
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(wall_thickness, wall_reach * 2.0)
	shape.shape = rect
	shape.position = Vector2(x + wall_thickness * 0.5, global_position.y)
	body.add_child(shape)


func _play(anim: StringName) -> void:
	if animation_player != null and animation_player.has_animation(anim):
		animation_player.play(anim)
