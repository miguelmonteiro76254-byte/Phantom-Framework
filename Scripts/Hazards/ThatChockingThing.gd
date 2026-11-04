class_name Antenna
extends Node2D

enum Phase { IDLE, WARN, SHOCK }

@export_group("Nodes")
@export var animation_player: AnimationPlayer
@export var warn_sound: AudioStreamPlayer2D
@export var shock_sound: AudioStreamPlayer2D

@export_group("Animations")
@export var anim_idle: StringName = &"idle"
@export var anim_warn: StringName = &"warn"
@export var anim_shock: StringName = &"shock"

@export_group("Timing")
@export var idle_time := 2.0
@export var warn_time := 0.5
@export var shock_time := 0.7
@export var start_offset := 0.0

@export_group("Beam")
@export var beam_length := 160.0
@export var beam_thickness := 10.0
@export var beam_start_gap := 4.0
@export var beam_offset := Vector2.ZERO
@export var beam_color := Color(0.4, 0.9, 1.0, 0.9)
@export var beam_core_color := Color(1.0, 1.0, 1.0, 1.0)
@export var warn_color := Color(0.4, 0.9, 1.0, 0.5)
@export var warn_blink_interval := 0.08
@export var beam_fade_time := 0.08
@export var zigzag_step := 8.0
@export var zigzag_amplitude := 3.0
@export var tip_spark_count := 3
@export var tip_spark_length := 8.0

@export_group("Damage")
@export_flags_2d_physics var player_mask := 1

var _phase := Phase.IDLE
var _timer := 0.0
var _phase_time := 0.0
var _area: Area2D
var _shapes: Array[CollisionShape2D] = []


func _ready() -> void:
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if warn_sound == null:
		warn_sound = get_node_or_null("WarnSound") as AudioStreamPlayer2D
	if shock_sound == null:
		shock_sound = get_node_or_null("ShockSound") as AudioStreamPlayer2D
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = player_mask
	_area.monitoring = true
	add_child(_area)
	for r in _beam_rects():
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = r.size
		shape.shape = box
		shape.position = r.get_center()
		shape.disabled = true
		_area.add_child(shape)
		_shapes.append(shape)
	_phase = Phase.IDLE
	_timer = idle_time + start_offset
	_play_anim(anim_idle)


func _physics_process(delta: float) -> void:
	_timer -= delta
	_phase_time += delta
	if _timer <= 0.0:
		_next_phase()
	if _phase == Phase.SHOCK:
		_hurt_overlapping()
	if _phase != Phase.IDLE:
		queue_redraw()


func _next_phase() -> void:
	match _phase:
		Phase.IDLE:
			if warn_time > 0.0:
				_set_phase(Phase.WARN)
			else:
				_set_phase(Phase.SHOCK)
		Phase.WARN:
			_set_phase(Phase.SHOCK)
		Phase.SHOCK:
			_set_phase(Phase.IDLE)


func _set_phase(p: Phase) -> void:
	_phase = p
	_phase_time = 0.0
	match p:
		Phase.IDLE:
			_timer = idle_time
			_set_beams_active(false)
			_stop_sound(warn_sound)
			_stop_sound(shock_sound)
			_play_anim(anim_idle)
		Phase.WARN:
			_timer = warn_time
			_play_sound(warn_sound)
			_play_anim(anim_warn)
		Phase.SHOCK:
			_timer = shock_time
			_set_beams_active(true)
			_stop_sound(warn_sound)
			_play_sound(shock_sound)
			_play_anim(anim_shock)
	queue_redraw()


func _set_beams_active(active: bool) -> void:
	for s in _shapes:
		s.set_deferred("disabled", not active)


func _hurt_overlapping() -> void:
	for body in _area.get_overlapping_bodies():
		if body.is_in_group(&"player") and body.has_method("hurt"):
			body.hurt(global_position.x)


func _play_anim(anim: StringName) -> void:
	if animation_player == null or not animation_player.has_animation(anim):
		return
	animation_player.play(anim)


func _play_sound(player: AudioStreamPlayer2D) -> void:
	if player != null:
		player.play()


func _stop_sound(player: AudioStreamPlayer2D) -> void:
	if player != null:
		player.stop()


func _beam_rects() -> Array[Rect2]:
	var y := beam_offset.y - beam_thickness * 0.5
	var size := Vector2(beam_length, beam_thickness)
	var right := Rect2(Vector2(beam_offset.x + beam_start_gap, y), size)
	var left := Rect2(Vector2(beam_offset.x - beam_start_gap - beam_length, y), size)
	return [left, right]


func _shock_fade() -> float:
	if beam_fade_time <= 0.0:
		return 1.0
	var fade_in := clampf(_phase_time / beam_fade_time, 0.0, 1.0)
	var fade_out := clampf(_timer / beam_fade_time, 0.0, 1.0)
	return minf(fade_in, fade_out)


func _draw() -> void:
	match _phase:
		Phase.WARN:
			_draw_warn()
		Phase.SHOCK:
			_draw_shock()


func _draw_warn() -> void:
	if warn_blink_interval > 0.0 and int(_phase_time / warn_blink_interval) % 2 != 0:
		return
	for r in _beam_rects():
		var y := r.get_center().y
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), warn_color, 1.0)


func _draw_shock() -> void:
	var fade := _shock_fade()
	var glow := beam_color
	glow.a *= 0.35 * fade
	var main := beam_color
	main.a *= fade
	var core := beam_core_color
	core.a *= fade
	var rects := _beam_rects()
	for i in rects.size():
		var r := rects[i]
		draw_rect(r, glow)
		var points := _zigzag(r)
		draw_polyline(points, main, 3.0)
		draw_polyline(points, core, 1.0)
		var tip := Vector2(r.end.x if i == 1 else r.position.x, r.get_center().y)
		_draw_tip_sparks(tip, 1.0 if i == 1 else -1.0, main)


func _draw_tip_sparks(tip: Vector2, side: float, color: Color) -> void:
	for i in tip_spark_count:
		var angle := randf_range(-PI * 0.5, PI * 0.5)
		var dir := Vector2(cos(angle) * side, sin(angle))
		draw_line(tip, tip + dir * randf_range(tip_spark_length * 0.4, tip_spark_length), color, 1.0)


func _zigzag(r: Rect2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var y := r.get_center().y
	var step := maxf(zigzag_step, 1.0)
	var count := maxi(int(r.size.x / step), 1)
	for i in count + 1:
		var x := r.position.x + minf(i * step, r.size.x)
		var off := 0.0 if i == 0 or i == count else randf_range(-zigzag_amplitude, zigzag_amplitude)
		pts.append(Vector2(x, y + off))
	return pts
