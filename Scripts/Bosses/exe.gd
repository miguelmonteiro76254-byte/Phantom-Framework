extends "res://Scripts/Player/sonic.gd"

signal activated
signal health_changed(current: int, maximum: int)
signal defeated

enum Phase { DORMANT, INTRO, IDLE, SWEEP, SPIN_CHARGE, SPIN_ROLL, JUMP_AT, ROLL_AT, STUN, DEFEATED }

@export_group("Boss")
@export var max_health := 8
@export var defeat_score := 1000
@export var act_sign: Node2D
@export var hit_invincibility := 1.2
@export var stun_time := 0.0
@export var bounce_min_speed := 240.0
@export var defeat_duration := 1.5
@export var explosion_scene: PackedScene
@export var anim_sweep: StringName = &"sweep"

@export_group("Boss Music")
@export var boss_music: AudioStreamPlayer
@export var pause_level_music := true
@export var resume_level_music := true
@export var stop_boss_music_on_defeat := true

@export_group("Boss Hitbox")
@export var hitbox: Area2D
@export_flags_2d_physics var player_mask := 1
@export var hitbox_size := Vector2(28.0, 32.0)
@export var sweep_hitbox_size := Vector2(40.0, 14.0)

@export_group("Boss Arena")
@export var trigger_distance := 192.0
@export var trigger_height := 128.0
@export var intro_delay := 1.0
@export var arena_camera_marker: Node2D
@export var arena_camera_offset := Vector2(-96.0, -32.0)
@export var arena_half_width := 176.0
@export var barriers_enabled := true
@export_flags_2d_physics var barrier_layer := 1
@export var barrier_thickness := 64.0
@export var barrier_margin := 0.0

@export_group("Boss Behaviour")
@export var think_time_min := 0.3
@export var think_time_max := 0.6
@export var approach_distance := 112.0
@export var sweep_range := 96.0
@export var jump_enabled := false

@export_subgroup("Movement")
@export var idle_move_speed := 140.0
@export var pace_time_min := 0.3
@export var pace_time_max := 0.7
@export var arena_edge_margin := 16.0

@export_subgroup("Punish Idle Player")
@export var still_trigger_time := 0.4
@export var still_speed_threshold := 10.0

@export_subgroup("Sweep")
@export var sweep_windup := 0.25
@export var sweep_duration := 0.45
@export var sweep_speed := 300.0
@export var sweep_brake := 900.0

@export_subgroup("Spindash")
@export var spin_charge_time := 0.7
@export var spin_revs := 2
@export var spin_rev_interval := 0.25
@export var spin_roll_time := 1.2
@export var spin_brake := 500.0

@export_subgroup("Roll")
@export var roll_attack_speed := 420.0
@export var roll_attack_time := 1.0

@export_subgroup("Roll Clash")
@export var clash_sound: AudioStreamPlayer
@export var clash_knockback := Vector2(180.0, -200.0)
@export var clash_grace := 0.5

@export_subgroup("Jump")
@export var jump_count := 2
@export var jump_prep_time := 0.25
@export var jump_gap := 0.3
@export var jump_aim := 1.0
@export var jump_max_speed := 260.0

var health := 0

var _phase: Phase = Phase.DORMANT
var _last_attack: Phase = Phase.IDLE
var _player: Player
var _home := Vector2.ZERO
var _lock_point := Vector2.ZERO
var _arena_active := false
var _t := 0.0
var _fx_timer := 0.0
var _hit_shape: CollisionShape2D
var _hit_size := Vector2.ZERO
var _hit_pos := Vector2.ZERO
var _spin_started := false
var _revs := 0
var _rev_timer := 0.0
var _clash_timer := 0.0
var _roll_started := false
var _roll_limit := 0.0
var _pace_dir := 0
var _pace_timer := 0.0
var _player_still_time := 0.0
var _jumps_left := 0
var _jump_issued := false
var _jump_wait := 0.0
var _jump_fail := 0.0
var _in_air := false
var _barriers: StaticBody2D
var _level_music_pos := 0.0
var _level_music_was_playing := false


func _ready() -> void:
	camera_enabled = false
	super._ready()
	if camera != null:
		camera.enabled = false
	uses_lives = false
	remove_from_group(&"player")
	add_to_group(&"boss")
	collision_layer = 0
	health = max_health
	clash_sound = _find_sound(clash_sound, "ClashSound")
	_home = global_position
	_setup_hitbox()
	_set_phase(Phase.DORMANT)


func _setup_hitbox() -> void:
	if hitbox == null:
		hitbox = get_node_or_null("Hitbox") as Area2D
	if hitbox == null:
		hitbox = Area2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = hitbox_size
		shape.shape = rect
		shape.position = Vector2(0.0, -hitbox_size.y * 0.5)
		hitbox.add_child(shape)
		add_child(hitbox)
	hitbox.collision_layer = 0
	hitbox.collision_mask = player_mask
	hitbox.monitorable = false
	hitbox.monitoring = false
	for c in hitbox.get_children():
		var cs := c as CollisionShape2D
		if cs != null and cs.shape is RectangleShape2D:
			_hit_shape = cs
			_hit_shape.shape = _hit_shape.shape.duplicate()
			_hit_size = (_hit_shape.shape as RectangleShape2D).size
			_hit_pos = _hit_shape.position
			break


func _set_phase(p: Phase) -> void:
	_phase = p
	if _hit_shape == null:
		return
	var size := sweep_hitbox_size if p == Phase.SWEEP else _hit_size
	(_hit_shape.shape as RectangleShape2D).size = size
	var bottom := _hit_pos.y + _hit_size.y * 0.5
	_hit_shape.position = Vector2(_hit_pos.x, bottom - size.y * 0.5)


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player == null:
		return
	var bodies: Array[Node] = [_player]
	bodies.append_array(get_tree().get_nodes_in_group(&"tails"))
	var ex: Array[RID] = [get_rid()]
	for b in bodies:
		if b == self or not b is PhysicsBody2D:
			continue
		add_collision_exception_with(b as PhysicsBody2D)
		(b as PhysicsBody2D).add_collision_exception_with(self)
		ex.append((b as PhysicsBody2D).get_rid())
	for q in _rays:
		q.exclude = ex


func _physics_process(delta: float) -> void:
	_clash_timer = maxf(_clash_timer - delta, 0.0)
	super._physics_process(delta)
	_check_contacts()


func _read_input() -> void:
	_dir = 0
	_up = false
	_down = false
	_jump_pressed = false
	_jump_held = false

	if _player == null:
		_find_player()
		if _player == null:
			return

	var dt := get_physics_process_delta_time()
	if _phase == Phase.DEFEATED:
		_tick_defeated(dt)
		return
	if _player.is_dead():
		return

	_update_player_still(dt)

	match _phase:
		Phase.DORMANT: _tick_dormant()
		Phase.INTRO: _tick_intro(dt)
		Phase.IDLE: _tick_idle(dt)
		Phase.SWEEP: _tick_sweep(dt)
		Phase.SPIN_CHARGE: _tick_spin_charge(dt)
		Phase.SPIN_ROLL: _tick_spin_roll(dt)
		Phase.JUMP_AT: _tick_jump(dt)
		Phase.ROLL_AT: _tick_roll_attack(dt)
		Phase.STUN: _tick_stun(dt)

	_keep_in_arena()
	_try_build_barriers()


func _update_player_still(dt: float) -> void:
	var on_ground := _player.state == State.GROUND \
			or _player.state == State.SPINDASH \
			or _player.state == State.PEELOUT
	if on_ground and absf(_player.ground_speed) <= still_speed_threshold:
		_player_still_time += dt
	else:
		_player_still_time = 0.0


func _view_span() -> Vector2:
	var center := _lock_point
	var half := get_viewport_rect().size
	if _player.camera != null:
		center = _player._clamp_camera_to_limits(_lock_point)
		half /= _player.camera.zoom
	half *= 0.5
	return Vector2(center.x - half.x - barrier_margin, center.x + half.x + barrier_margin)


func _try_build_barriers() -> void:
	if not barriers_enabled or _barriers != null or not _arena_active:
		return
	var span := _view_span()
	var px := _player.global_position.x
	if px < span.x or px > span.y:
		return
	_barriers = StaticBody2D.new()
	_barriers.name = "BossBarriers"
	_barriers.top_level = true
	_barriers.collision_layer = barrier_layer
	_barriers.collision_mask = 0
	add_child(_barriers)
	_barriers.global_position = Vector2.ZERO
	var size := Vector2(barrier_thickness, 4096.0)
	_add_barrier(Vector2(span.x - barrier_thickness * 0.5, _lock_point.y), size)
	_add_barrier(Vector2(span.y + barrier_thickness * 0.5, _lock_point.y), size)


func _add_barrier(center: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = center
	_barriers.add_child(shape)


func _free_barriers() -> void:
	if _barriers != null:
		_barriers.queue_free()
		_barriers = null


func _face_player() -> void:
	facing = 1 if _player.global_position.x >= global_position.x else -1


func _tick_dormant() -> void:
	var d := _player.global_position - global_position
	if absf(d.x) <= trigger_distance and absf(d.y) <= trigger_height:
		_activate()


func _activate() -> void:
	if arena_camera_marker != null:
		_lock_point = arena_camera_marker.global_position
	else:
		_lock_point = _home + arena_camera_offset
	_player.lock_camera_to(_lock_point)
	_start_music()
	_arena_active = true
	_face_player()
	_t = intro_delay
	_set_phase(Phase.INTRO)
	activated.emit()


func _tick_intro(dt: float) -> void:
	_t -= dt
	if _t <= 0.0:
		hitbox.set_deferred("monitoring", true)
		_set_phase(Phase.IDLE)
		_t = 0.0
		_player_still_time = 0.0


func _tick_idle(dt: float) -> void:
	if state == State.GROUND:
		if _player_still_time >= still_trigger_time:
			_player_still_time = 0.0
			_begin_attack(Phase.SPIN_CHARGE)
			return
		_move_idle(dt)
	_t -= dt
	if _t <= 0.0 and state == State.GROUND:
		_begin_attack(_pick_attack())


func _move_idle(dt: float) -> void:
	var dx := _player.global_position.x - global_position.x
	if absf(dx) > approach_distance:
		_pace_dir = int(signf(dx))
		_pace_timer = 0.0
	else:
		_pace_timer -= dt
		if _pace_timer <= 0.0 or _pace_dir == 0:
			_pace_timer = randf_range(pace_time_min, pace_time_max)
			if _pace_dir == 0:
				_pace_dir = 1 if randf() < 0.5 else -1
			else:
				_pace_dir = -_pace_dir
		ground_speed = clampf(ground_speed, -idle_move_speed, idle_move_speed)

	if _arena_active:
		var left := _lock_point.x - arena_half_width + arena_edge_margin
		var right := _lock_point.x + arena_half_width - arena_edge_margin
		if global_position.x <= left:
			_pace_dir = 1
		elif global_position.x >= right:
			_pace_dir = -1
	_dir = _pace_dir


func _pick_attack() -> Phase:
	var dx := absf(_player.global_position.x - global_position.x)
	var pool: Array[Phase] = [Phase.SWEEP, Phase.SPIN_CHARGE, Phase.ROLL_AT]
	if jump_enabled:
		pool.append(Phase.JUMP_AT)
	if dx < sweep_range:
		pool.append(Phase.SWEEP)
	else:
		pool.append(Phase.SPIN_CHARGE)
		pool.append(Phase.ROLL_AT)
	var options: Array[Phase] = []
	for p in pool:
		if p != _last_attack:
			options.append(p)
	if options.is_empty():
		options = pool
	var pick: Phase = options.pick_random()
	return pick


func _begin_attack(attack: Phase) -> void:
	_face_player()
	_last_attack = attack
	_t = 0.0
	ground_speed = 0.0
	match attack:
		Phase.SPIN_CHARGE:
			_spin_started = false
			_revs = 0
			_rev_timer = 0.0
		Phase.ROLL_AT:
			_roll_started = false
		Phase.JUMP_AT:
			_jumps_left = maxi(jump_count, 1)
			_jump_issued = false
			_in_air = false
			_jump_wait = jump_prep_time
	_set_phase(attack)


func _end_attack() -> void:
	control_lock = 0.0
	_set_phase(Phase.IDLE)
	_t = randf_range(think_time_min, think_time_max)


func _tick_sweep(dt: float) -> void:
	if state != State.GROUND:
		_end_attack()
		return
	_t += dt
	control_lock = maxf(control_lock, 0.1)
	if _t < sweep_windup:
		ground_speed = 0.0
	elif _t < sweep_windup + sweep_duration:
		ground_speed = facing * sweep_speed
	else:
		ground_speed = move_toward(ground_speed, 0.0, sweep_brake * dt)
		if absf(ground_speed) < 10.0:
			ground_speed = 0.0
			_end_attack()


func _tick_spin_charge(dt: float) -> void:
	_t += dt
	match state:
		State.GROUND:
			if not _spin_started:
				_spin_started = true
				_down = true
				_jump_pressed = true
			elif _t > 0.3:
				_end_attack()
		State.SPINDASH:
			_down = _t < spin_charge_time
			_rev_timer -= dt
			if _revs < spin_revs and _rev_timer <= 0.0:
				_jump_pressed = true
				_revs += 1
				_rev_timer = spin_rev_interval
		State.ROLL:
			_t = 0.0
			_roll_limit = spin_roll_time
			_set_phase(Phase.SPIN_ROLL)
		_:
			_end_attack()


func _tick_roll_attack(dt: float) -> void:
	_t += dt
	match state:
		State.GROUND:
			if not _roll_started:
				_roll_started = true
				ground_speed = facing * roll_attack_speed
				_down = true
			elif _t > 0.3:
				_end_attack()
		State.ROLL:
			_t = 0.0
			_roll_limit = roll_attack_time
			_set_phase(Phase.SPIN_ROLL)
		_:
			_end_attack()


func _tick_spin_roll(dt: float) -> void:
	if state != State.ROLL:
		_end_attack()
		return
	_t += dt
	if _t >= _roll_limit:
		ground_speed = move_toward(ground_speed, 0.0, spin_brake * dt)


func _tick_jump(dt: float) -> void:
	_t += dt
	if _t > 5.0:
		_end_attack()
		return
	var dx := _player.global_position.x - global_position.x
	match state:
		State.GROUND:
			if not _jump_issued:
				_jump_wait -= dt
				if _jump_wait <= 0.0:
					_face_player()
					ground_speed = clampf(dx * jump_aim, -jump_max_speed, jump_max_speed)
					_jump_pressed = true
					_jump_held = true
					_jump_issued = true
					_in_air = false
					_jump_fail = 0.3
			elif _in_air:
				ground_speed = 0.0
				_jumps_left -= 1
				if _jumps_left > 0:
					_jump_issued = false
					_jump_wait = jump_gap
				else:
					_end_attack()
			else:
				_jump_fail -= dt
				if _jump_fail <= 0.0:
					_end_attack()
		State.AIR:
			_in_air = true
			_jump_held = true
			if absf(dx) > 8.0:
				_dir = int(signf(dx))


func _tick_stun(dt: float) -> void:
	if state != State.GROUND:
		return
	_t -= dt
	if _t <= 0.0:
		_end_attack()


func _keep_in_arena() -> void:
	if not _arena_active:
		return
	var left := _lock_point.x - arena_half_width
	var right := _lock_point.x + arena_half_width
	var out_left := global_position.x < left
	var out_right := global_position.x > right
	match state:
		State.ROLL:
			if (out_left and ground_speed < 0.0) or (out_right and ground_speed > 0.0):
				ground_speed = -ground_speed
				facing = int(signf(ground_speed))
		State.GROUND:
			if (out_left and ground_speed < 0.0) or (out_right and ground_speed > 0.0):
				ground_speed = 0.0
		State.AIR, State.HURT:
			if (out_left and velocity.x < 0.0) or (out_right and velocity.x > 0.0):
				velocity.x = 0.0


func is_vulnerable() -> bool:
	return false


func die() -> void:
	_defeat()


func _check_contacts() -> void:
	if hitbox == null or not hitbox.monitoring:
		return
	for body in hitbox.get_overlapping_bodies():
		if _phase == Phase.DEFEATED:
			return
		_touch(body)


func _touch(body: Node2D) -> void:
	if body == self or not body.has_method(&"hurt"):
		return
	if _clash_timer > 0.0:
		return
	var attacking: bool = body.has_method(&"is_attacking") and body.is_attacking()
	if attacking and _is_clash_pose(body):
		_clash(body)
		return
	if attacking:
		if _invincible <= 0.0:
			_take_damage(body)
	elif _phase != Phase.STUN:
		body.hurt(global_position.x)


func _boss_jumping() -> bool:
	return state == State.AIR and is_jumping


func _player_jumping(body: Node2D) -> bool:
	var p := body as Player
	return p != null and p.state == State.AIR and p.is_jumping


func _is_clash_pose(body: Node2D) -> bool:
	if state == State.ROLL:
		return true
	return _boss_jumping() and _player_jumping(body)

func _take_damage(body: Node2D) -> void:
	health = maxi(health - 1, 0)
	health_changed.emit(health, max_health)
	_play_sound(hurt_sound)
	_bounce(body)
	_invincible = hit_invincibility
	if health <= 0:
		_defeat()
		return
	var side := 1 if global_position.x >= body.global_position.x else -1
	_enter_air()
	_set_state(State.HURT)
	velocity = Vector2(hurt_knockback.x * side, hurt_knockback.y)
	ground_speed = 0.0
	control_lock = 0.0
	_t = stun_time
	_set_phase(Phase.STUN)


func _clash(body: Node2D) -> void:
	_clash_timer = clash_grace
	_play_sound(clash_sound)
	var boss_side := 1 if global_position.x >= body.global_position.x else -1

	var p := body as Player
	if p != null:
		p._enter_air()
		p._clear_air_animation()
		p.velocity = Vector2(clash_knockback.x * -boss_side, clash_knockback.y)
		p.is_jumping = true
		p._current_anim = &""

	_enter_air()
	_set_state(State.HURT)
	velocity = Vector2(clash_knockback.x * boss_side, clash_knockback.y)
	ground_speed = 0.0
	control_lock = 0.0
	_t = 0.0
	_set_phase(Phase.STUN)


func _bounce(body: Node2D) -> void:
	if body is CharacterBody2D:
		var p := body as CharacterBody2D
		if not p.is_on_floor() and p.velocity.y > 0.0:
			p.velocity.y = -maxf(p.velocity.y, bounce_min_speed)


func _defeat() -> void:
	if _phase == Phase.DEFEATED:
		return
	_set_phase(Phase.DEFEATED)
	if hitbox != null:
		hitbox.set_deferred("monitoring", false)
	if state == State.ROLL or state == State.SPINDASH:
		_set_state(State.GROUND)
	ground_speed = 0.0
	_invincible = 0.0
	_t = defeat_duration
	_fx_timer = 0.0
	_play_sound(death_sound)
	Score.add(defeat_score)
	_release_camera()
	_free_barriers()
	_end_music()
	if act_sign != null and _player != null:
		act_sign.set("player", _player)
		act_sign.call("_trigger")
	defeated.emit()


func _start_music() -> void:
	if boss_music == null:
		boss_music = get_node_or_null("BossMusic") as AudioStreamPlayer
	var lm := _level_music()
	if lm != null and pause_level_music and lm.playing:
		_level_music_pos = lm.get_playback_position()
		_level_music_was_playing = true
		lm.stop()
	if boss_music != null:
		boss_music.play()


func _end_music() -> void:
	if boss_music != null and stop_boss_music_on_defeat:
		boss_music.stop()
	var lm := _level_music()
	if lm != null and resume_level_music and act_sign == null and _level_music_was_playing:
		lm.play(_level_music_pos)
	_level_music_was_playing = false


func _level_music() -> AudioStreamPlayer:
	var level := get_tree().get_first_node_in_group(&"level")
	if level == null:
		return null
	return level.get("music_player") as AudioStreamPlayer


func _release_camera() -> void:
	if _player == null:
		return
	if _player.has_method(&"unlock_camera"):
		_player.call(&"unlock_camera")
	else:
		_player._cam_locked = false


func _tick_defeated(dt: float) -> void:
	if state == State.GROUND:
		ground_speed = 0.0
	_t -= dt
	_fx_timer -= dt
	if _fx_timer <= 0.0:
		_fx_timer = 0.12
		_spawn_explosion(Vector2(randf_range(-24.0, 24.0), randf_range(-40.0, 0.0)))
	if _t <= 0.0:
		_spawn_explosion(Vector2(0.0, -16.0))
		set_physics_process(false)
		queue_free()


func _spawn_explosion(offset: Vector2) -> void:
	if explosion_scene == null:
		return
	var fx := explosion_scene.instantiate() as Node2D
	if fx == null:
		return
	get_parent().add_child(fx)
	fx.global_position = to_global(offset)


func _update_balance() -> void:
	is_balancing = false


func _standing_animation() -> StringName:
	return anim_idle


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == anim_idle:
		_current_anim = &""


func _update_animation() -> void:
	var ap := _current_player()
	if ap != null and _phase == Phase.SWEEP and ap.has_animation(anim_sweep):
		ap.speed_scale = 1.0
		_play(anim_sweep)
		return
	super._update_animation()
