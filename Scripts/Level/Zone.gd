@tool
extends Node2D

@export_group("Boundaries")
@export var bounds := Rect2i(0, 0, 4096, 1024):
	set(value):
		bounds = value
		if _gizmo != null:
			_gizmo.queue_redraw()
@export var wall_layer := 1
@export var wall_thickness := 128.0
@export var wall_reach := 4096.0
@export var death_margin := 64.0

@export_group("Camera")
@export var camera_smoothed := true

@export_group("Music")
@export var music: AudioStream
@export var music_volume_db := 0.0
@export var music_bus: StringName = &"Master"
@export var play_music_on_start := true
@export var stop_music_on_death := true
var _music_resume_pos := 0.0

@export_group("Super Music")
@export var super_music: AudioStream
@export var super_music_volume_db := 0.0

@export_group("Debug")
@export var debug_draw := false:
	set(value):
		debug_draw = value
		if is_inside_tree():
			_update_gizmo()

var player: Node2D
var music_player: AudioStreamPlayer
var super_music_player: AudioStreamPlayer
var _walls: StaticBody2D
var _gizmo: Node2D
var _music_stopped := false

func _ready() -> void:
	add_to_group(&"level")
	_update_gizmo()
	if Engine.is_editor_hint():
		return
	_build_walls()
	_setup_music()
	_setup_super_music()
	while player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			await get_tree().process_frame
	_setup_player()


func _update_gizmo() -> void:
	var show := Engine.is_editor_hint() or debug_draw
	if show and _gizmo == null:
		_gizmo = Node2D.new()
		_gizmo.name = "BoundsGizmo"
		_gizmo.top_level = true
		_gizmo.z_as_relative = false
		_gizmo.z_index = 4096
		add_child(_gizmo)
		_gizmo.draw.connect(_draw_bounds)
	if _gizmo != null:
		_gizmo.visible = show
		_gizmo.queue_redraw()


func _draw_bounds() -> void:
	var tl := Vector2(bounds.position)
	var br := Vector2(bounds.end)
	var tr := Vector2(br.x, tl.y)
	var bl := Vector2(tl.x, br.y)
	_gizmo.draw_rect(Rect2(tl, br - tl), Color(1.0, 0.85, 0.2, 0.06), true)
	var wall_color := Color(1.0, 0.85, 0.2)
	_gizmo.draw_line(tl, tr, wall_color, 6.0)
	_gizmo.draw_line(tl, bl, wall_color, 6.0)
	_gizmo.draw_line(tr, br, wall_color, 6.0)
	_gizmo.draw_line(bl, br, Color(1.0, 0.2, 0.2), 6.0)


func play_music() -> void:
	_music_stopped = false
	if music_player != null and not music_player.playing:
		music_player.play()


func stop_music() -> void:
	_music_stopped = true
	if music_player != null:
		music_player.stop()
	if super_music_player != null:
		super_music_player.stop()


func _setup_player() -> void:
	player.set("kill_y", float(bounds.end.y) + death_margin)
	for f in get_tree().get_nodes_in_group("follower"):
		f.set("kill_y", float(bounds.end.y) + death_margin)

	var cam := player.get_node_or_null("Camera") as Camera2D
	if cam == null:
		for c in player.get_children():
			if c is Camera2D:
				cam = c as Camera2D
				break
	if cam != null:
		cam.limit_left = bounds.position.x
		cam.limit_top = bounds.position.y
		cam.limit_right = bounds.end.x
		cam.limit_bottom = bounds.end.y
		cam.limit_smoothed = camera_smoothed

	if player.has_signal("died"):
		player.connect("died", _on_player_died)
	if player.has_signal("super_started"):
		player.connect("super_started", _on_super_started)
	if player.has_signal("super_ended"):
		player.connect("super_ended", _on_super_ended)


func _on_player_died() -> void:
	if stop_music_on_death:
		stop_music()


func _on_super_started() -> void:
	if super_music_player == null or _music_stopped:
		return
	if music_player != null and music_player.playing:
		_music_resume_pos = music_player.get_playback_position()
		music_player.stop()
	super_music_player.play()


func _on_super_ended() -> void:
	if super_music_player == null:
		return
	super_music_player.stop()
	if _music_stopped:
		return
	if music_player != null:
		music_player.play()

func _build_walls() -> void:
	_walls = StaticBody2D.new()
	_walls.name = "BoundaryWalls"
	_walls.top_level = true
	_walls.collision_layer = wall_layer
	_walls.collision_mask = 0
	add_child(_walls)
	_walls.position = Vector2.ZERO

	var left := float(bounds.position.x)
	var right := float(bounds.end.x)
	var top := float(bounds.position.y)
	var bottom := float(bounds.end.y)
	var t := wall_thickness
	var mid_y := (top + bottom) * 0.5
	var tall := bottom - top + wall_reach * 2.0

	_add_wall(Vector2(left - t * 0.5, mid_y), Vector2(t, tall))
	_add_wall(Vector2(right + t * 0.5, mid_y), Vector2(t, tall))
	_add_wall(Vector2((left + right) * 0.5, top - t * 0.5), Vector2(right - left + t * 2.0, t))


func _add_wall(center: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = center
	_walls.add_child(shape)


func _setup_music() -> void:
	if music == null:
		return
	if "loop" in music:
		music.set("loop", true)
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	music_player.stream = music
	music_player.volume_db = music_volume_db
	music_player.bus = music_bus
	add_child(music_player)
	music_player.finished.connect(music_player.play)
	if play_music_on_start:
		music_player.play()


func _setup_super_music() -> void:
	if super_music == null:
		return
	if "loop" in super_music:
		super_music.set("loop", true)
	super_music_player = AudioStreamPlayer.new()
	super_music_player.name = "SuperMusic"
	super_music_player.stream = super_music
	super_music_player.volume_db = super_music_volume_db
	super_music_player.bus = music_bus
	add_child(super_music_player)
	super_music_player.finished.connect(super_music_player.play)
