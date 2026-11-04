class_name Monitor
extends CharacterBody2D

enum MonitorType { RINGS_10, SUPER, SHIELD }

const MONITOR_ANIMATIONS := {
	MonitorType.RINGS_10: &"rings",
	MonitorType.SUPER: &"super",
	MonitorType.SHIELD: &"shield",
}

@export_group("Monitor")
@export var monitor_type: MonitorType = MonitorType.RINGS_10

@export_group("Nodes")
@export var detector: Area2D
@export var visual: Node2D
@export var animation_player: AnimationPlayer
@export var break_sound: AudioStreamPlayer
@export var break_effect_scene: PackedScene

@export_group("Detection")
@export var roll_break_min_speed := 0.0
@export var contact_margin := 4.0

@export_group("Hit From Below")
@export var hit_pop_speed := 180.0
@export var gravity_strength := 787.5
@export var max_fall_speed := 960.0

@export_group("Hit From Above")
@export var bounce_min_speed := 240.0
@export var points := 10

var _half_size := Vector2(16.0, 16.0)
var _has_gravity := false
var _broken := false


func _ready() -> void:
	process_physics_priority = -1
	if detector == null:
		detector = get_node_or_null("Detector") as Area2D
	if visual == null:
		visual = get_node_or_null("Sprite") as Node2D
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if break_sound == null:
		break_sound = get_node_or_null("BreakSound") as AudioStreamPlayer
	_play_type_animation()


func _play_type_animation() -> void:
	if animation_player == null:
		return
	var anim: StringName = MONITOR_ANIMATIONS.get(monitor_type, &"")
	if anim == &"" or not animation_player.has_animation(anim):
		push_warning("Monito: no '%s' in AnimationPlayer." % anim)
		return
	animation_player.play(anim)


func _physics_process(delta: float) -> void:
	if _broken:
		return

	for node in get_tree().get_nodes_in_group(&"player"):
		var p := node as Player
		if p != null and _handle_player(p, delta):
			return

	if _has_gravity:
		_process_gravity(delta)


func _process_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity_strength * delta, max_fall_speed)
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0


func _handle_player(p: Player, delta: float) -> bool:
	if p.is_dead():
		return false

	var player_col: CollisionShape2D = p.col_normal
	if p.has_method(&"_active_col"):
		player_col = p.call(&"_active_col") as CollisionShape2D

	if player_col == null:
		return false

	var ph: Vector2 = _half_extents(player_col)
	var rel: Vector2 = player_col.global_position - global_position
	var reach: Vector2 = _half_size + ph + Vector2(contact_margin, contact_margin)
	var in_reach := absf(rel.x) <= reach.x and absf(rel.y) <= reach.y

	if p.state == Player.State.STOMP or p.stomp_hit_window > 0.0:
		var sweep := absf(p.velocity.y) * delta if p.state == Player.State.STOMP else 0.0
		var stomp_hit := absf(rel.x) <= reach.x \
				and rel.y >= -(reach.y + sweep) \
				and rel.y <= reach.y
		if stomp_hit:
			_break(p, false)
			return true
		return false

	if (p.state == Player.State.ROLL or p.state == Player.State.SPINDASH) and absf(p.ground_speed) >= roll_break_min_speed:
		if in_reach:
			_break(p, false)
			return true
		return false

	if p.state != Player.State.AIR:
		return false

	if p.velocity.y < 0.0 and rel.y > 0.0 and absf(rel.x) <= _half_size.x and in_reach:
		if not _has_gravity:
			_has_gravity = true
			velocity.y = -hit_pop_speed
		return false

	if not p.is_jumping:
		return false

	if p.velocity.y >= 0.0 and rel.y < 0.0 and absf(rel.x) <= _half_size.x + ph.x:
		var monitor_top: float = global_position.y - _half_size.y
		var next_bottom: float = player_col.global_position.y + ph.y + p.velocity.y * delta
		if next_bottom >= monitor_top - contact_margin:
			_break(p, true)
			return true

	if in_reach and absf(rel.x) > _half_size.x:
		_break(p, false)
		return true

	return false


func _half_extents(col: CollisionShape2D) -> Vector2:
	var s := col.shape
	var scale := col.global_scale.abs()
	if s is RectangleShape2D:
		return (s as RectangleShape2D).size * 0.5 * scale
	if s is CapsuleShape2D:
		var c := s as CapsuleShape2D
		return Vector2(c.radius, c.height * 0.5) * scale
	if s is CircleShape2D:
		return Vector2.ONE * (s as CircleShape2D).radius * scale
	return Vector2.ZERO


func _break(p: Player, bounce: bool) -> void:
	_broken = true
	if bounce:
		p.velocity.y = -maxf(absf(p.velocity.y), bounce_min_speed)
	_give_reward(p)

	collision_layer = 0
	collision_mask = 0
	if detector != null:
		detector.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	if animation_player != null:
		animation_player.stop()
	if visual != null:
		visual.hide()

	if break_effect_scene != null:
		var fx := break_effect_scene.instantiate() as Node2D
		fx.global_position = global_position
		get_parent().add_child(fx)

	if break_sound != null and break_sound.stream != null:
		break_sound.play()
		await break_sound.finished
	queue_free()


func _give_reward(p: Player) -> void:
	Score.add(points)
	match monitor_type:
		MonitorType.RINGS_10:
			p.add_rings(10)
		MonitorType.SUPER:
			p.add_rings(50)
			p.start_super()
		MonitorType.SHIELD:
			p.give_shield()
