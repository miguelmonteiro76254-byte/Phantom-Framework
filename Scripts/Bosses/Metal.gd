class_name MetalSonicBoss
extends Node2D

signal race_started
signal activated
signal health_changed(current: int, maximum: int)
signal defeated

enum Stage { DORMANT, RACE, FIGHT, DEFEATED }
enum Move {
	ENTER, HOVER,
	SPIN_WINDUP, SPIN_DASH,
	FIELD_WINDUP, FIELD_ACTIVE,
	OD_POSITION, OD_CHARGE, OD_DASH,
	EXHAUST, HURT,
}

@export_group("Boss")
@export var max_health := 10
@export var defeat_score := 1000
@export var act_sign: Node2D
@export var hit_invincibility := 1.5
@export var hurt_knockback := Vector2(140.0, -120.0)
@export var hurt_stun_time := 0.6
@export var hurt_brake := 4.0
@export var bounce_min_speed := 240.0
@export var clash_cooldown := 0.3
@export var die_jump_speed := 420.0
@export var die_gravity := 787.5
@export var die_free_time := 4.0
@export_range(0.0, 1.0) var enrage_ratio := 0.5
@export var enrage_think_scale := 0.6

@export_group("Nodes")
@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer
@export var hitbox: Area2D
@export var hitbox_size := Vector2(24.0, 28.0)
@export_flags_2d_physics var player_mask := 1

@export_group("Animations")
@export var anim_fly: StringName = &"fly"
@export var anim_spin: StringName = &"spin"
@export var anim_field: StringName = &"ring_spark"
@export var anim_charge: StringName = &"overdrive_charge"
@export var anim_overdrive: StringName = &"overdrive"
@export var anim_exhaust: StringName = &"exhausted"
@export var anim_hurt: StringName = &"hurt"
@export var anim_die: StringName = &"die"
@export var blink_interval := 0.06
@export var shake_amount := 1.5
@export var draw_fx := true

@export_group("Sounds")
@export var hurt_sound: AudioStreamPlayer
@export var death_sound: AudioStreamPlayer
@export var clash_sound: AudioStreamPlayer
@export var charge_sound: AudioStreamPlayer
@export var dash_sound: AudioStreamPlayer
@export var field_sound: AudioStreamPlayer

@export_group("Boss Music")
@export var boss_music: AudioStreamPlayer
@export var pause_level_music := true
@export var resume_level_music := true
@export var stop_boss_music_on_defeat := true
@export var music_on_race := true

@export_group("Triggers")
@export var race_trigger: Area2D
@export var race_start_distance := 192.0
@export var fight_trigger: Area2D

@export_group("Race (Stage 1)")
@export_enum("Right:1", "Left:-1") var race_direction := 1
@export var hide_until_race := true
@export var race_spawn_distance := 260.0
@export var race_lead_distance := 130.0
@export var race_hover_height := 40.0
@export var race_follow_gain := 3.0
@export var race_max_speed := 900.0
@export var race_think_min := 0.8
@export var race_think_max := 1.6
@export var race_behind_distance := 150.0
@export var race_overshoot := 220.0
@export var race_field_chase_speed := 320.0

@export_group("Arena (Stage 2)")
@export var arena_camera_marker: Node2D
@export var arena_camera_offset := Vector2(-96.0, -32.0)
@export var arena_half_width := 176.0
@export var arena_floor_offset := 64.0
@export var hover_height := 56.0
@export var enter_time := 1.5
@export var barriers_enabled := true
@export_flags_2d_physics var barrier_layer := 1
@export var barrier_thickness := 64.0
@export var barrier_margin := 0.0

@export_group("Movement")
@export var fly_speed := 180.0
@export var follow_smoothing := 8.0
@export var brake_smoothing := 10.0
@export var hover_sweep_speed := 0.9
@export var bob_amplitude := 5.0
@export var bob_speed := 4.0
@export var think_min := 0.8
@export var think_max := 1.4

@export_group("Spin Dash (race only)")
@export var spin_windup := 0.5
@export var spin_speed := 420.0
@export var spin_time := 0.8

@export_group("Ring Spark Field")
@export var field_radius := 52.0
@export var field_windup := 0.5
@export var field_time := 3.0
@export var field_chase_speed := 70.0
@export var field_exhaust_time := 2.0

@export_group("Maximum Overdrive")
@export var od_speed_multiplier := 4.0
@export var od_charge_time := 0.9
@export var od_recharge_time := 0.5
@export var od_passes := 1
@export var od_passes_enraged := 2
@export var od_edge_inset := 24.0
@export var od_exit_margin := 24.0
@export var od_max_time := 3.0
@export var od_exhaust_time := 2.5

@export_group("Exhaustion")
@export var exhaust_speed_scale := 0.3
@export var exhaust_drift_speed := 80.0
@export var exhaust_height := 20.0

var health := 0

var _stage: Stage = Stage.DORMANT
var _move: Move = Move.HOVER
var _last_attack: Move = Move.HOVER
var _player: Player
var _vel := Vector2.ZERO
var _t := 0.0
var _clock := 0.0
var _invincible := 0.0
var _clash_timer := 0.0
var _facing := 1
var _home := Vector2.ZERO
var _lock_point := Vector2.ZERO
var _arena_active := false
var _field: Area2D
var _field_on := false
var _field_shape: CollisionShape2D
var _dash_dir := Vector2.ZERO
var _od_dir := 1
var _od_anchor_x := 0.0
var _od_passes_left := 0
var _od_charge_cur := 0.0
var _barriers: StaticBody2D
var _sprite_base := Vector2.ZERO
var _anim: StringName = &""
var _level_music_pos := 0.0
var _level_music_was_playing := false
var _music_started := false


func _ready() -> void:
	add_to_group(&"boss")
	health = max_health
	_home = global_position
	if sprite != null:
		_sprite_base = sprite.position
	hurt_sound = _find_sound(hurt_sound, "HurtSound")
	death_sound = _find_sound(death_sound, "DeathSound")
	clash_sound = _find_sound(clash_sound, "ClashSound")
	charge_sound = _find_sound(charge_sound, "ChargeSound")
	dash_sound = _find_sound(dash_sound, "DashSound")
	field_sound = _find_sound(field_sound, "FieldSound")
	_setup_hitbox()
	_setup_field()
	if race_trigger != null:
		race_trigger.body_entered.connect(_on_race_trigger)
	if fight_trigger != null:
		fight_trigger.body_entered.connect(_on_fight_trigger)
	_set_move(Move.HOVER)
	if hide_until_race:
		visible = false


func _find_sound(current: AudioStreamPlayer, node_name: String) -> AudioStreamPlayer:
	return current if current != null else get_node_or_null(node_name) as AudioStreamPlayer


func _play_sound(p: AudioStreamPlayer) -> void:
	if p != null:
		p.play()


func _setup_hitbox() -> void:
	if hitbox == null:
		hitbox = get_node_or_null("Hitbox") as Area2D
	if hitbox == null:
		hitbox = Area2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = hitbox_size
		shape.shape = rect
		hitbox.add_child(shape)
		add_child(hitbox)
	hitbox.collision_layer = 0
	hitbox.collision_mask = player_mask
	hitbox.monitorable = false
	hitbox.monitoring = false


func _setup_field() -> void:
	_field = Area2D.new()
	_field.name = "RingSparkField"
	_field.collision_layer = 0
	_field.collision_mask = player_mask
	_field.monitorable = false
	_field.monitoring = false
	_field_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = field_radius
	_field_shape.shape = circle
	_field_shape.disabled = true
	_field.add_child(_field_shape)
	add_child(_field)


func _acquire_player() -> bool:
	_player = get_tree().get_first_node_in_group(&"player") as Player
	return _player != null


func _is_player(body: Node) -> bool:
	return body.is_in_group(&"player")


func _on_race_trigger(body: Node) -> void:
	if _is_player(body):
		start_race()


func _on_fight_trigger(body: Node) -> void:
	if _is_player(body):
		begin_fight()


func start_race() -> void:
	if _stage != Stage.DORMANT or not _acquire_player():
		return
	_stage = Stage.RACE
	visible = true
	global_position = _player_center() + Vector2(race_direction * race_spawn_distance, -race_hover_height)
	_vel = Vector2.ZERO
	hitbox.set_deferred("monitoring", true)
	if music_on_race:
		_start_music()
	_enter_hover()
	race_started.emit()


func begin_fight() -> void:
	if _stage == Stage.FIGHT or _stage == Stage.DEFEATED or not _acquire_player():
		return
	_set_field(false)
	if arena_camera_marker != null:
		_lock_point = arena_camera_marker.global_position
	else:
		_lock_point = _home + arena_camera_offset
	if _stage == Stage.DORMANT:
		visible = true
		global_position = _lock_point + Vector2(race_direction * arena_half_width, -96.0)
		_vel = Vector2.ZERO
	_stage = Stage.FIGHT
	health = max_health
	health_changed.emit(health, max_health)
	_player.lock_camera_to(_lock_point)
	_start_music()
	_arena_active = true
	hitbox.set_deferred("monitoring", true)
	_set_move(Move.ENTER)
	_t = enter_time
	activated.emit()


func _tick_dormant() -> void:
	if race_trigger != null or race_start_distance <= 0.0:
		return
	if absf(_player.global_position.x - _home.x) <= race_start_distance:
		start_race()


func _physics_process(delta: float) -> void:
	_clock += delta
	_invincible = maxf(_invincible - delta, 0.0)
	_clash_timer = maxf(_clash_timer - delta, 0.0)
	if _player == null and not _acquire_player():
		return
	match _stage:
		Stage.DORMANT:
			_tick_dormant()
		Stage.RACE, Stage.FIGHT:
			if _player.is_dead():
				_brake(delta)
				_set_field(false)
			else:
				_tick_move(delta)
		Stage.DEFEATED:
			_tick_defeated(delta)
	global_position += _vel * delta
	if _stage == Stage.FIGHT:
		_keep_in_arena()
		_try_build_barriers()
	_check_contacts()
	_update_visual()


func _tick_move(delta: float) -> void:
	var race := _stage == Stage.RACE
	match _move:
		Move.ENTER:
			_face_player()
			_follow(Vector2(_lock_point.x, _hover_y()), 3.0, fly_speed * 2.0, delta)
			_t -= delta
			if _t <= 0.0:
				_enter_hover()

		Move.HOVER:
			_face_player()
			_hover_motion(delta)
			_t -= delta
			if _t <= 0.0:
				_begin_attack(_pick_attack())

		Move.SPIN_WINDUP:
			_face_player()
			_brake(delta)
			_t += delta
			if _t >= spin_windup:
				_dash_dir = (_player_center() - global_position).normalized()
				_vel = _dash_dir * spin_speed
				_facing = 1 if _dash_dir.x >= 0.0 else -1
				_play_sound(dash_sound)
				_set_move(Move.SPIN_DASH)

		Move.SPIN_DASH:
			_t += delta
			if _t >= spin_time:
				_finish_attack(0.0)

		Move.FIELD_WINDUP:
			_face_player()
			_brake(delta)
			_t += delta
			if _t >= field_windup:
				_set_field(true)
				_set_move(Move.FIELD_ACTIVE)

		Move.FIELD_ACTIVE:
			_face_player()
			var speed := race_field_chase_speed if race else field_chase_speed
			var target := _player_center()
			if not race:
				target.y = clampf(target.y, _hover_y(), _floor_y())
			_follow(target, 2.0, speed, delta)
			_t += delta
			if _t >= field_time:
				_finish_attack(field_exhaust_time)

		Move.OD_POSITION:
			_facing = _od_dir
			_follow(_od_target(), 5.0, _od_follow_speed(), delta)
			_t += delta
			if global_position.distance_to(_od_target()) < 12.0 or _t > 2.5:
				_play_sound(charge_sound)
				_set_move(Move.OD_CHARGE)

		Move.OD_CHARGE:
			_facing = _od_dir
			_follow(_od_target(), 6.0, _od_follow_speed(), delta)
			_t += delta
			if _t >= _od_charge_cur:
				_dash_dir = Vector2(_od_dir, 0.0)
				_vel = _dash_dir * _od_speed()
				_play_sound(dash_sound)
				_set_move(Move.OD_DASH)

		Move.OD_DASH:
			_t += delta
			_vel = _dash_dir * _od_speed()
			var done := _t > od_max_time
			if race:
				done = done or (global_position.x - _player.global_position.x) * race_direction >= race_overshoot
			else:
				done = done or (global_position.x - _lock_point.x) * _od_dir >= arena_half_width + od_exit_margin
			if done:
				_od_dash_done()

		Move.EXHAUST:
			_face_player()
			var x := clampf(global_position.x, _lock_point.x - arena_half_width + od_edge_inset, _lock_point.x + arena_half_width - od_edge_inset)
			_follow(Vector2(x, _floor_y() - exhaust_height), 2.0, maxf(fly_speed * exhaust_speed_scale, exhaust_drift_speed), delta)
			_t -= delta
			if _t <= 0.0:
				_enter_hover()

		Move.HURT:
			_vel = _vel.lerp(Vector2.ZERO, 1.0 - exp(-hurt_brake * delta))
			_t -= delta
			if _t <= 0.0:
				_enter_hover()


func _player_center() -> Vector2:
	return _player._focus_origin()


func _floor_y() -> float:
	return _lock_point.y + arena_floor_offset


func _hover_y() -> float:
	return _floor_y() - hover_height


func _face_player() -> void:
	_facing = 1 if _player.global_position.x >= global_position.x else -1


func _follow(target: Vector2, gain: float, max_speed: float, dt: float) -> void:
	var desired := ((target - global_position) * gain).limit_length(max_speed)
	_vel = _vel.lerp(desired, 1.0 - exp(-follow_smoothing * dt))


func _brake(dt: float) -> void:
	_vel = _vel.lerp(Vector2.ZERO, 1.0 - exp(-brake_smoothing * dt))


func _enraged() -> bool:
	return _stage == Stage.FIGHT and health <= ceili(max_health * enrage_ratio)


func _hover_motion(dt: float) -> void:
	var bob := sin(_clock * bob_speed) * bob_amplitude
	if _stage == Stage.RACE:
		var pc := _player_center()
		var target := Vector2(pc.x + race_direction * race_lead_distance, pc.y - race_hover_height + bob)
		_follow(target, race_follow_gain, race_max_speed, dt)
	else:
		var sweep := sin(_clock * hover_sweep_speed) * arena_half_width * 0.65
		var speed := fly_speed * (1.3 if _enraged() else 1.0)
		_follow(Vector2(_lock_point.x + sweep, _hover_y() + bob), 3.0, speed, dt)


func _keep_in_arena() -> void:
	match _move:
		Move.ENTER, Move.HOVER, Move.FIELD_WINDUP, Move.FIELD_ACTIVE, Move.HURT:
			var left := _lock_point.x - arena_half_width
			var right := _lock_point.x + arena_half_width
			if global_position.x < left or global_position.x > right:
				global_position.x = clampf(global_position.x, left, right)
				_vel.x = 0.0
			if global_position.y > _floor_y():
				global_position.y = _floor_y()
				_vel.y = minf(_vel.y, 0.0)


func _think_time() -> float:
	if _stage == Stage.RACE:
		return randf_range(race_think_min, race_think_max)
	var t := randf_range(think_min, think_max)
	return t * (enrage_think_scale if _enraged() else 1.0)


func _enter_hover() -> void:
	_set_move(Move.HOVER)
	_t = _think_time()


func _set_move(m: Move) -> void:
	_move = m
	_t = 0.0


func _pick_attack() -> Move:
	var pool: Array[Move] = [Move.FIELD_WINDUP, Move.OD_POSITION]
	if _stage == Stage.RACE:
		pool.append(Move.SPIN_WINDUP)
	var options: Array[Move] = []
	for m in pool:
		if m != _last_attack:
			options.append(m)
	if options.is_empty():
		options = pool
	var pick: Move = options.pick_random()
	return pick


func _begin_attack(attack: Move) -> void:
	_last_attack = attack
	match attack:
		Move.SPIN_WINDUP, Move.FIELD_WINDUP:
			_play_sound(charge_sound)
		Move.OD_POSITION:
			_od_passes_left = od_passes_enraged if _enraged() else od_passes
			_od_charge_cur = od_charge_time
			if _stage == Stage.RACE:
				_od_dir = race_direction
			else:
				var side := -1 if randf() < 0.5 else 1
				_od_dir = -side
				_od_anchor_x = _lock_point.x + side * (arena_half_width - od_edge_inset)
	_set_move(attack)


func _finish_attack(exhaust: float) -> void:
	_set_field(false)
	if _stage == Stage.FIGHT and exhaust > 0.0:
		_set_move(Move.EXHAUST)
		_t = exhaust
	else:
		_enter_hover()


func _od_speed() -> float:
	return fly_speed * od_speed_multiplier


func _od_follow_speed() -> float:
	return race_max_speed if _stage == Stage.RACE else fly_speed * 2.5


func _od_target() -> Vector2:
	var pc := _player_center()
	if _stage == Stage.RACE:
		return Vector2(pc.x - race_direction * race_behind_distance, pc.y)
	return Vector2(_od_anchor_x, clampf(pc.y, _hover_y(), _floor_y()))


func _od_dash_done() -> void:
	_od_passes_left -= 1
	if _stage == Stage.FIGHT and _od_passes_left > 0:
		_od_dir = -_od_dir
		_od_anchor_x = _lock_point.x - _od_dir * (arena_half_width - od_edge_inset)
		_od_charge_cur = od_recharge_time
		_set_move(Move.OD_POSITION)
	else:
		_finish_attack(od_exhaust_time)


func _set_field(on: bool) -> void:
	if _field_on == on:
		return
	_field_on = on
	_field.set_deferred("monitoring", on)
	_field_shape.set_deferred("disabled", not on)
	if on:
		_play_sound(field_sound)
	elif field_sound != null:
		field_sound.stop()


func is_vulnerable() -> bool:
	return _stage == Stage.FIGHT and _invincible <= 0.0 \
			and (_move == Move.HOVER or _move == Move.EXHAUST)


func _is_dangerous() -> bool:
	return _move == Move.SPIN_DASH or _move == Move.FIELD_ACTIVE or _move == Move.OD_DASH


func _check_contacts() -> void:
	if _stage == Stage.DEFEATED or _stage == Stage.DORMANT:
		return
	if hitbox != null and hitbox.monitoring:
		for body in hitbox.get_overlapping_bodies():
			if _stage == Stage.DEFEATED:
				return
			_touch(body)
	if _field_on and _field.monitoring:
		for body in _field.get_overlapping_bodies():
			if body.has_method(&"hurt"):
				body.hurt(global_position.x, self)


func _touch(body: Node2D) -> void:
	if not body.has_method(&"hurt"):
		return
	var attacking: bool = body.has_method(&"is_attacking") and body.is_attacking()
	if _is_dangerous():
		body.hurt(global_position.x, self)
	elif attacking:
		if is_vulnerable():
			_take_damage(body)
		elif _clash_timer <= 0.0:
			_clash_timer = clash_cooldown
			_play_sound(clash_sound)
			_bounce(body)
	elif _move != Move.HURT and _move != Move.ENTER:
		body.hurt(global_position.x, self)


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
	_set_field(false)
	_vel = Vector2(hurt_knockback.x * side, hurt_knockback.y)
	_set_move(Move.HURT)
	_t = hurt_stun_time


func _bounce(body: Node2D) -> void:
	if body is CharacterBody2D:
		var p := body as CharacterBody2D
		if not p.is_on_floor() and p.velocity.y > 0.0:
			p.velocity.y = -maxf(p.velocity.y, bounce_min_speed)


func _defeat() -> void:
	if _stage == Stage.DEFEATED:
		return
	_stage = Stage.DEFEATED
	_set_field(false)
	if hitbox != null:
		hitbox.set_deferred("monitoring", false)
	_invincible = 0.0
	z_index = 100
	_vel = Vector2(0.0, -die_jump_speed)
	_t = die_free_time
	_play_sound(death_sound)
	Score.add(defeat_score)
	_release_camera()
	_free_barriers()
	_end_music()
	if act_sign != null and _player != null:
		act_sign.set("player", _player)
		act_sign.call("_trigger")
	defeated.emit()


func _tick_defeated(delta: float) -> void:
	_t -= delta
	_vel.x = 0.0
	_vel.y += die_gravity * delta
	if _t <= 0.0 or global_position.y > _floor_y() + 600.0:
		set_physics_process(false)
		queue_free()


func _release_camera() -> void:
	if _player == null:
		return
	if _player.has_method(&"unlock_camera"):
		_player.call(&"unlock_camera")
	else:
		_player._cam_locked = false


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


func _suppress_level_music(on: bool) -> void:
	var level := get_tree().get_first_node_in_group(&"level")
	if level != null and level.has_method(&"suppress_music"):
		level.call(&"suppress_music", on)


func _level_music() -> AudioStreamPlayer:
	var level := get_tree().get_first_node_in_group(&"level")
	if level == null:
		return null
	return level.get("music_player") as AudioStreamPlayer


func _start_music() -> void:
	if _music_started:
		return
	_music_started = true
	if boss_music == null:
		boss_music = get_node_or_null("BossMusic") as AudioStreamPlayer
	if boss_music == null:
		boss_music = find_child("BossMusic", true, false) as AudioStreamPlayer
	if boss_music == null:
		push_warning("MetalSonicBoss: boss_music not set and no AudioStreamPlayer named BossMusic found.")
	elif boss_music.stream == null:
		push_warning("MetalSonicBoss: boss_music has no stream assigned.")
	_suppress_level_music(true)
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
	_suppress_level_music(false)
	var lm := _level_music()
	if lm != null and resume_level_music and act_sign == null and _level_music_was_playing:
		lm.play(_level_music_pos)
	_level_music_was_playing = false
	_music_started = false


func _update_visual() -> void:
	if sprite != null:
		sprite.flip_h = _facing < 0
		var shake := Vector2.ZERO
		match _move:
			Move.SPIN_WINDUP, Move.FIELD_WINDUP, Move.OD_CHARGE:
				shake = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_amount
		sprite.position = _sprite_base + shake
		if _invincible > 0.0 and _stage == Stage.FIGHT:
			sprite.visible = int(_invincible / blink_interval) % 2 == 0
		else:
			sprite.visible = true
	_update_animation()
	if draw_fx:
		queue_redraw()


func _update_animation() -> void:
	var anim := anim_fly
	match _move:
		Move.SPIN_WINDUP, Move.SPIN_DASH:
			anim = anim_spin
		Move.FIELD_WINDUP, Move.FIELD_ACTIVE:
			anim = anim_field
		Move.OD_CHARGE:
			anim = anim_charge
		Move.OD_DASH:
			anim = anim_overdrive
		Move.EXHAUST:
			anim = anim_exhaust
		Move.HURT:
			anim = anim_hurt
	if _stage == Stage.DEFEATED:
		anim = anim_die if animation_player != null and animation_player.has_animation(anim_die) else anim_hurt
	if animation_player == null or _anim == anim or not animation_player.has_animation(anim):
		return
	_anim = anim
	animation_player.play(anim)
