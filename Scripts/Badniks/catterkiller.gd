class_name Caterkiller
extends Node2D

signal destroyed

enum Phase { SCRUNCH, HOLD_SCRUNCHED, STRETCH, HOLD_STRETCHED }

const TURN := 128.0
const DEFAULT_SCATTER_SPEEDS := [2.0, 1.5, -1.5, -2.0]
const SEGMENT_NAMES := ["Head", "Body1", "Body2", "Body3"]

class Segment:
	var node: Node2D
	var skin: Node2D
	var hitbox: Area2D
	var x := 0.0
	var y := 0.0
	var dir := -1
	var vel := Vector2.ZERO
	var queue: Array[float] = []

@export_group("Movement")
@export_enum("Left:-1", "Right:1") var start_direction := -1
@export var sprite_faces_right := false
@export var move_frames := 16
@export var wait_frames := 8
@export var head_speed := 0.75
@export var speed_step := 0.25
@export var segment_spacing := 12
@export var left_turn_offset := -1.0

@export_group("Sensor")
@export_flags_2d_physics var ground_mask := 1
@export var floor_up := 8.0
@export var floor_down := 12.0

@export_group("Hitbox")
@export_flags_2d_physics var player_mask := 1
@export var head_radius := Vector2(8.0, 7.0)
@export var body_radius := Vector2(8.0, 8.0)

@export_group("Animation")
@export var rise_table := PackedInt32Array([0, 0, 0, 0, 1, 1, 2, 3, 4, 4, 5, 6, 6, 7, 7, 7])
@export var attack_frame := 1
@export var normal_frame := 0

@export_group("Scatter")
@export var scatter_speeds := PackedFloat32Array([2.0, 1.5, -1.5, -2.0])
@export var scatter_bounce := 4.0
@export var scatter_gravity := 0.21875
@export var scatter_frames := 240

@export_group("Destroy")
@export var explosion_scene: PackedScene
@export var destroy_sound: AudioStream
@export var destroy_sound_volume_db := 0.0
@export var bounce_min_speed := 0.0

var _segs: Array[Segment] = []
var _phase := Phase.SCRUNCH
var _frame := 0
var _dead := false
var _snapped := false
var _scattered := false
var _scatter_timer := 0


func _ready() -> void:
	add_to_group(&"caterkiller")
	var dir := -1 if start_direction < 0 else 1
	for i in SEGMENT_NAMES.size():
		var seg := Segment.new()
		seg.node = get_node_or_null(NodePath(SEGMENT_NAMES[i])) as Node2D
		if seg.node == null:
			seg.node = Node2D.new()
			seg.node.name = SEGMENT_NAMES[i]
			add_child(seg.node)
		seg.skin = seg.node.get_node_or_null("Skin") as Node2D
		seg.hitbox = _make_hitbox(seg.node, i)
		seg.dir = dir
		seg.x = global_position.x - dir * segment_spacing * i
		seg.y = global_position.y
		if i > 0:
			seg.queue.resize(segment_spacing)
			seg.queue.fill(0.0)
		_segs.append(seg)
	_apply()
	_update_head_frame()


func _make_hitbox(parent: Node2D, index: int) -> Area2D:
	var area := parent.get_node_or_null("Hitbox") as Area2D
	if area == null:
		area = Area2D.new()
		area.name = "Hitbox"
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		var radius := head_radius if index == 0 else body_radius
		rect.size = radius * 2.0 + Vector2.ONE
		shape.shape = rect
		area.add_child(shape)
		parent.add_child(area)
	area.collision_layer = 0
	area.collision_mask = player_mask
	area.monitorable = false
	return area


func _physics_process(_delta: float) -> void:
	if _dead:
		return
	if _scattered:
		_scatter_step()
		return
	if not _snapped:
		_snapped = true
		_snap_to_floor()
	_move()
	_apply()
	_update_head_frame()
	_check_player()
	_advance_phase()


func _snap_to_floor() -> void:
	var dist := _floor_distance(_segs[0])
	if is_inf(dist) or dist < -floor_up:
		return
	for seg in _segs:
		seg.y += dist


func _move() -> void:
	var scrunching := _phase == Phase.SCRUNCH
	var stretching := _phase == Phase.STRETCH
	if not scrunching and not stretching:
		return
	var s := 0.0 if scrunching else head_speed
	var step := speed_step if scrunching else -speed_step
	for i in _segs.size():
		if i > 0:
			s += step
		_move_segment(i, s)


func _move_segment(index: int, s: float) -> void:
	var seg := _segs[index]
	var before := floori(seg.x)
	seg.x += seg.dir * s
	if floori(seg.x) == before:
		return
	if index == 0:
		_head_pixel(seg)
	else:
		_follow_pixel(index, seg)


func _head_pixel(seg: Segment) -> void:
	var dist := _floor_distance(seg)
	if dist > floor_down or dist < -floor_up:
		_push(1, TURN)
		_turn(seg)
	else:
		seg.y += dist
		_push(1, dist)


func _follow_pixel(index: int, seg: Segment) -> void:
	if seg.queue.is_empty():
		return
	var value: float = seg.queue.pop_front()
	if value == TURN:
		_turn(seg)
	else:
		seg.y += value
	_push(index + 1, value)


func _push(index: int, value: float) -> void:
	if index < _segs.size():
		_segs[index].queue.push_back(value)


func _turn(seg: Segment) -> void:
	var base := floorf(seg.x)
	seg.x = base + (1.0 - (seg.x - base))
	seg.dir = -seg.dir
	if seg.dir < 0:
		seg.x += left_turn_offset


func _floor_distance(seg: Segment) -> float:
	var foot := seg.y + head_radius.y
	var x := floorf(seg.x) + 0.5
	var hit := _cast(Vector2(x, foot - floor_up - 1.0), Vector2(x, foot + floor_down + 0.5), true)
	if hit.is_empty():
		return INF
	return hit.position.y - foot


func _cast(from: Vector2, to: Vector2, from_inside := false) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, ground_mask)
	query.hit_from_inside = from_inside
	return get_world_2d().direct_space_state.intersect_ray(query)


func _advance_phase() -> void:
	var moving := _phase == Phase.SCRUNCH or _phase == Phase.STRETCH
	_frame += 1
	if _frame >= (move_frames if moving else wait_frames):
		_frame = 0
		_phase = ((_phase + 1) % 4) as Phase


func _update_head_frame() -> void:
	var head := _segs[0]
	if head.skin == null:
		return
	var attacking := false
	for node in get_tree().get_nodes_in_group(&"player"):
		if node.has_method(&"is_attacking") and node.is_attacking():
			attacking = true
			break
	head.skin.set("frame", attack_frame if attacking else normal_frame)


func _raise() -> float:
	if rise_table.is_empty():
		return 0.0
	var last := rise_table.size() - 1
	match _phase:
		Phase.SCRUNCH:
			return rise_table[mini(_frame, last)]
		Phase.HOLD_SCRUNCHED:
			return rise_table[last]
		Phase.STRETCH:
			return rise_table[maxi(last - _frame, 0)]
	return 0.0


func _place() -> void:
	for i in _segs.size():
		var seg := _segs[i]
		var lift := 0.0 if i == 0 or _scattered else head_radius.y - body_radius.y
		seg.node.global_position = Vector2(floorf(seg.x), roundf(seg.y + lift))
		if seg.skin != null:
			seg.skin.set("flip_h", (seg.dir > 0) != sprite_faces_right)


func _apply() -> void:
	_place()
	var raise := _raise()
	for i in _segs.size():
		var seg := _segs[i]
		if seg.skin != null:
			seg.skin.position.y = -raise if i == 0 or i == 2 else 0.0


func _check_player() -> void:
	for i in _segs.size():
		var seg := _segs[i]
		for body in seg.hitbox.get_overlapping_bodies():
			if _dead or _scattered:
				return
			if not body.has_method(&"hurt"):
				continue
			var attacking: bool = body.has_method(&"is_attacking") and body.is_attacking()
			if i == 0 and attacking:
				if body.has_method(&"hit_badnik"):
					body.hit_badnik()
				_bounce(body)
				destroy()
				return
			body.hurt(seg.x)
			scatter()
			return


func _bounce(body: Node2D) -> void:
	if body is CharacterBody2D:
		var player := body as CharacterBody2D
		if not player.is_on_floor() and player.velocity.y > 0.0:
			player.velocity.y = -maxf(player.velocity.y, bounce_min_speed)


func scatter() -> void:
	if _dead or _scattered:
		return
	_scattered = true
	for i in _segs.size():
		var seg := _segs[i]
		seg.hitbox.set_deferred("monitoring", false)
		if seg.skin != null:
			seg.skin.position.y = 0.0
		var speed: float = scatter_speeds[i] if i < scatter_speeds.size() else DEFAULT_SCATTER_SPEEDS[i]
		seg.vel = Vector2(speed * -seg.dir, -scatter_bounce)


func _scatter_step() -> void:
	for seg in _segs:
		seg.vel.y += scatter_gravity
		seg.x += seg.vel.x
		seg.y += seg.vel.y
		if seg.vel.y > 0.0:
			var hit := _cast(Vector2(seg.x, seg.y - body_radius.y), Vector2(seg.x, seg.y + body_radius.y))
			if not hit.is_empty():
				seg.y = hit.position.y - body_radius.y
				seg.vel.y = -scatter_bounce
	_place()
	_scatter_timer += 1
	if _scatter_timer >= scatter_frames:
		queue_free()


func destroy() -> void:
	if _dead:
		return
	_dead = true
	for seg in _segs:
		seg.hitbox.set_deferred("monitoring", false)
	var scene := get_tree().current_scene
	var parent := get_parent()
	var head := _segs[0]
	if explosion_scene != null:
		var fx := explosion_scene.instantiate() as Node2D
		if fx != null:
			fx.global_position = Vector2(head.x, head.y)
			parent.add_child.call_deferred(fx)
	if destroy_sound != null:
		var sfx := AudioStreamPlayer.new()
		sfx.stream = destroy_sound
		sfx.volume_db = destroy_sound_volume_db
		sfx.finished.connect(sfx.queue_free)
		scene.add_child.call_deferred(sfx)
		sfx.play.call_deferred()
	destroyed.emit()
	queue_free()
