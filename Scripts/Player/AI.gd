extends "res://Scripts/Player/sonic.gd"

@export_group("Tails AI")
@export var leader: CharacterBody2D
@export var follow_delay_frames := 16
@export var follow_deadzone := 16.0
@export var jump_height_trigger := 32.0
@export var jump_interval_frames := 64
@export var lost_timeout := 5.0
@export var lost_margin := 32.0
@export var die_on_hit := false

@export_group("Tails Respawn")
@export var fly_start_margin := 48.0
@export var fly_apex_height := 96.0
@export var fly_side_offset := 32.0
@export var respawn_invincibility := 1.0

var _history: Array[Dictionary] = []
var _frame := 0
var _auto_jump := false
var _lost_time := 0.0
var _flying_in := false
var _fly_side := -1
var _base_layer := 0
var _base_mask := 0
var _base_z := 0
var _linked_leader: CharacterBody2D

func _ready() -> void:
	super._ready()
	uses_lives = false
	remove_from_group(&"player")
	add_to_group(&"tails")
	_base_layer = collision_layer
	_base_mask = collision_mask
	_base_z = z_index


func _find_leader() -> void:
	if leader == null:
		leader = get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	if leader == null or leader == _linked_leader:
		return
	_linked_leader = leader
	add_collision_exception_with(leader)
	leader.add_collision_exception_with(self)
	_exclude_from_rays(self, leader)
	_exclude_from_rays(leader, self)


func _exclude_from_rays(body: CharacterBody2D, other: CharacterBody2D) -> void:
	for q: PhysicsRayQueryParameters2D in body._rays:
		q.exclude = [body.get_rid(), other.get_rid()]


func _screen_rect() -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	return inv * get_viewport_rect()


func _read_input() -> void:
	_dir = 0
	_up = false
	_down = false
	_jump_pressed = false
	_jump_held = false

	if leader == null or leader != _linked_leader:
		_find_leader()
		if leader == null:
			return
	if state == State.DEAD or _flying_in or leader.state == State.DEAD:
		return

	if _screen_rect().grow(lost_margin).has_point(global_position):
		_lost_time = 0.0
	else:
		_lost_time += get_physics_process_delta_time()
		if _lost_time >= lost_timeout:
			_start_fly_in()
			return

	_frame += 1
	_history.push_back({
		"pos": leader.global_position,
		"dir": leader._dir,
		"up": leader._up,
		"down": leader._down,
		"jump": leader._jump_pressed,
		"held": leader._jump_held,
	})
	while _history.size() > follow_delay_frames + 1:
		_history.pop_front()
	var d: Dictionary = _history[0]

	var dx: float = d.pos.x - global_position.x
	if absf(dx) > follow_deadzone:
		_dir = int(signf(dx))
	else:
		_dir = d.dir
		_up = d.up
		_down = d.down

	if state == State.GROUND:
		_auto_jump = false

	if d.jump and (state == State.GROUND or state == State.ROLL):
		_jump_pressed = true

	var on_floor_state := state == State.GROUND and not is_crouching and not is_looking_up
	if on_floor_state and _frame % jump_interval_frames == 0:
		var leader_above := leader.global_position.y - global_position.y < -jump_height_trigger
		if leader_above or is_pushing:
			_jump_pressed = true
			_auto_jump = true

	_jump_held = d.held or _auto_jump


func is_vulnerable() -> bool:
	return not _flying_in and super.is_vulnerable()


func hurt(source_x: float, source: Node = null) -> void:
	if die_on_hit:
		super.hurt(source_x, source)
		return
	if not is_vulnerable():
		return
	_play_sound(hurt_sound)
	var side := 1 if global_position.x >= source_x else -1
	var v := Vector2(hurt_knockback.x * side, hurt_knockback.y)
	_enter_air()
	_set_state(State.HURT)
	velocity = v
	_invincible = invincibility_time


func die() -> void:
	if _flying_in:
		return
	super.die()


func _start_peelout() -> void:
	_jump()


func _on_respawn_timeout() -> void:
	pass


func add_rings(amount: int = 1) -> void:
	if leader != null:
		leader.add_rings(amount)
	else:
		super.add_rings(amount)


func _process_dead(delta: float) -> void:
	super._process_dead(delta)
	if not _flying_in and global_position.y > _screen_rect().end.y + fly_start_margin:
		_start_fly_in()


func _fly_target_x() -> float:
	return leader.global_position.x + _fly_side * fly_side_offset


func _start_fly_in() -> void:
	if leader == null:
		return
	_flying_in = true
	_lost_time = 0.0
	_fly_side = -int(signf(leader.facing))
	_reset_ground()
	_set_state(State.AIR)
	z_index = _base_z
	collision_layer = 0
	collision_mask = 0
	global_position = Vector2(_fly_target_x(), _screen_rect().end.y + fly_start_margin)
	var apex_y := leader.global_position.y - fly_apex_height
	var h := maxf(global_position.y - apex_y, 64.0)
	velocity = Vector2(0.0, -sqrt(2.0 * gravity_strength * h))
	is_spring = true


func _end_fly_in() -> void:
	_flying_in = false
	collision_layer = _base_layer
	collision_mask = _base_mask
	_invincible = respawn_invincibility


func _process_air(delta: float) -> void:
	if not _flying_in:
		super._process_air(delta)
		return
	velocity.y += gravity_strength * delta
	velocity.x = clampf((_fly_target_x() - global_position.x) * 4.0, -top_speed, top_speed)
	global_position += velocity * delta
	if absf(velocity.x) > 1.0:
		facing = int(signf(velocity.x))
	if velocity.y > 0.0:
		_end_fly_in()
