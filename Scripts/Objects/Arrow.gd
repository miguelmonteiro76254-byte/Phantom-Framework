class_name Arrow
extends Node2D

signal killed_enemy(enemy: Node)
signal stuck
signal vanished

enum ArrowState { FLYING, STUCK, FALLING }

@export_group("Nodes")
@export var skin: Node2D
@export var platform: StaticBody2D
@export var platform_shape: CollisionShape2D

@export_group("Flight")
@export var speed := 600.0
@export var flight_gravity := 0.0
@export var max_flight_time := 3.0
@export var sprite_faces_right := true

@export_group("Enemies")
@export var enemy_groups: Array[StringName] = [&"splats", &"motobug"]
@export var hit_radius := 16.0
@export var award_score := true

@export_group("Surface")
@export_flags_2d_physics var world_mask := 1
@export var stick_to_walls := false
@export var stick_time := 5.0
@export var stick_depth := 4.0
@export var fall_gravity := 787.5
@export var fall_max_speed := 960.0
@export var fall_spin_speed_deg := 0.0
@export var fall_max_time := 6.0

@export_group("Platform")
@export var make_platform := false
@export var platform_size := Vector2(24.0, 4.0)
@export var platform_offset := Vector2.ZERO
@export_flags_2d_physics var platform_layer := 1

@export_group("Debug")
@export var debug_print := false

var direction := Vector2.RIGHT
var shooter: Node2D
var velocity := Vector2.ZERO
var state: ArrowState = ArrowState.FLYING

var _timer := 0.0
var _ray := PhysicsRayQueryParameters2D.new()
var _notifier: VisibleOnScreenNotifier2D


func _ready() -> void:
	add_to_group(&"arrows")
	if skin == null:
		skin = get_node_or_null("Skin") as Node2D
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	velocity = direction * speed
	_timer = max_flight_time
	_update_skin_orientation()
	_setup_platform()
	_setup_ray()
	_setup_notifier()
	if debug_print:
		print("Arrow: spawned at ", global_position, " dir ", direction)


func _setup_platform() -> void:
	if not make_platform:
		return
	if platform == null:
		platform = get_node_or_null("Platform") as StaticBody2D
	if platform == null:
		platform = StaticBody2D.new()
		platform.name = "Platform"
		add_child(platform)
	if platform_shape == null:
		platform_shape = platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if platform_shape == null:
		platform_shape = CollisionShape2D.new()
		platform_shape.name = "CollisionShape2D"
		platform.add_child(platform_shape)
	var rect := RectangleShape2D.new()
	rect.size = platform_size
	platform_shape.shape = rect
	platform_shape.position = platform_offset
	platform_shape.one_way_collision = true
	platform_shape.disabled = true
	platform.collision_layer = platform_layer
	platform.collision_mask = 0


func _setup_ray() -> void:
	_ray.collision_mask = world_mask
	_ray.collide_with_areas = false
	_ray.collide_with_bodies = true
	var ignore: Array[RID] = []
	if shooter is CollisionObject2D:
		ignore.append((shooter as CollisionObject2D).get_rid())
	if platform != null:
		ignore.append(platform.get_rid())
	_ray.exclude = ignore


func _setup_notifier() -> void:
	_notifier = VisibleOnScreenNotifier2D.new()
	_notifier.rect = Rect2(-16.0, -16.0, 32.0, 32.0)
	_notifier.screen_exited.connect(_on_screen_exited)
	add_child(_notifier)


func _on_screen_exited() -> void:
	if state != ArrowState.STUCK:
		_vanish()


func _update_skin_orientation() -> void:
	if skin == null:
		return
	var angle := direction.angle()
	if not sprite_faces_right:
		angle += PI
	skin.rotation = angle
	skin.set("flip_v", direction.x < 0.0)


func _physics_process(delta: float) -> void:
	match state:
		ArrowState.FLYING: _process_flying(delta)
		ArrowState.STUCK: _process_stuck(delta)
		ArrowState.FALLING: _process_falling(delta)


func _process_flying(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_vanish()
		return

	velocity.y += flight_gravity * delta
	var start := global_position
	var end := start + velocity * delta

	_ray.from = start
	_ray.to = end
	var wall := get_world_2d().direct_space_state.intersect_ray(_ray)
	var hit_wall := not wall.is_empty()
	if hit_wall:
		end = wall.position

	var enemy := _find_enemy(start, end)
	if enemy != null:
		_kill(enemy)
		return

	if hit_wall:
		if debug_print:
			print("Arrow: hit wall ", wall.collider)
		if stick_to_walls:
			_stick(wall.position, velocity.normalized())
		else:
			_vanish()
		return

	global_position = end
	if flight_gravity != 0.0 and velocity.length() > 0.001:
		direction = velocity.normalized()
		_update_skin_orientation()


func _enemy_center(enemy: Node2D) -> Vector2:
	var hb: Variant = enemy.get("hitbox")
	if hb is Area2D:
		for c in (hb as Area2D).get_children():
			if c is CollisionShape2D:
				return (c as CollisionShape2D).global_position
		return (hb as Area2D).global_position
	return enemy.global_position


func _find_enemy(a: Vector2, b: Vector2) -> Node2D:
	for group in enemy_groups:
		for node in get_tree().get_nodes_in_group(group):
			var enemy := node as Node2D
			if enemy == null or enemy.is_queued_for_deletion():
				continue
			var center := _enemy_center(enemy)
			var closest := Geometry2D.get_closest_point_to_segment(center, a, b)
			if closest.distance_to(center) <= hit_radius:
				return enemy
	return null


func _kill(enemy: Node2D) -> void:
	if debug_print:
		print("Arrow: killed ", enemy)
	if award_score and is_instance_valid(shooter) and shooter.has_method(&"hit_badnik"):
		shooter.hit_badnik()
	if enemy.has_method(&"destroy"):
		enemy.destroy()
	else:
		enemy.queue_free()
	killed_enemy.emit(enemy)
	_vanish()


func _stick(point: Vector2, dir: Vector2) -> void:
	state = ArrowState.STUCK
	velocity = Vector2.ZERO
	global_position = point + dir * stick_depth
	_timer = stick_time
	if platform_shape != null:
		platform_shape.set_deferred("disabled", false)
	stuck.emit()


func _process_stuck(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	state = ArrowState.FALLING
	velocity = Vector2.ZERO
	_timer = fall_max_time
	if platform_shape != null:
		platform_shape.set_deferred("disabled", true)


func _process_falling(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_vanish()
		return
	velocity.y = minf(velocity.y + fall_gravity * delta, fall_max_speed)
	global_position += velocity * delta
	if skin != null and fall_spin_speed_deg != 0.0:
		skin.rotation += deg_to_rad(fall_spin_speed_deg) * delta


func _vanish() -> void:
	if is_queued_for_deletion():
		return
	vanished.emit()
	queue_free()
