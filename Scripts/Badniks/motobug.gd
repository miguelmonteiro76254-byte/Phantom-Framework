class_name Motobug
extends CharacterBody2D

signal destroyed

enum MotoState { MOVE, WAIT }

@export_group("Nodes")
@export var skin: Node2D
@export var animation_player: AnimationPlayer
@export var hitbox: Area2D

@export_group("Movement")
@export var speed := 60.0
@export var wait_time := 1.0
@export_enum("Left:-1", "Right:1") var start_direction := -1
@export var sprite_faces_right := false
@export var gravity_strength := 787.5
@export var max_fall_speed := 960.0
@export var ledge_ray_offset := Vector2(14.0, 0.0)
@export var ledge_ray_length := 28.0

@export_group("Hitbox")
@export_flags_2d_physics var player_mask := 1
@export var hitbox_size := Vector2(28.0, 22.0)
@export var hitbox_offset := Vector2.ZERO

@export_group("Animations")
@export var anim_move: StringName = &"move"
@export var anim_wait: StringName = &"wait"

@export_group("Destroy")
@export var explosion_scene: PackedScene
@export var destroy_sound: AudioStream
@export var destroy_sound_volume_db := 0.0
@export var bounce_min_speed := 0.0

var _state := MotoState.MOVE
var _dir := -1
var _timer := 0.0
var _dead := false
var _ledge_ray: RayCast2D
var _current_anim: StringName = &""


func _ready() -> void:
	add_to_group(&"motobug")
	collision_layer = 0
	motion_mode = MOTION_MODE_GROUNDED
	floor_snap_length = 8.0
	_dir = -1 if start_direction < 0 else 1

	if skin == null:
		skin = get_node_or_null("Skin") as Node2D
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if hitbox == null:
		hitbox = get_node_or_null("Hitbox") as Area2D
	if hitbox == null:
		hitbox = Area2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = hitbox_size
		shape.shape = rect
		shape.position = hitbox_offset
		hitbox.add_child(shape)
		add_child(hitbox)
	hitbox.collision_layer = 0
	hitbox.collision_mask = player_mask
	hitbox.monitorable = false

	_ledge_ray = RayCast2D.new()
	_ledge_ray.collision_mask = collision_mask
	add_child(_ledge_ray)
	_update_ledge_ray()
	_update_visuals()

	get_tree().node_added.connect(_ignore_body)
	_ignore_existing.call_deferred()


func _ignore_existing() -> void:
	for group in [&"player", &"motobug"]:
		for node in get_tree().get_nodes_in_group(group):
			_ignore_body(node)


func _ignore_body(node: Node) -> void:
	if node == self or not node is CharacterBody2D:
		return
	if node is Motobug or (node.has_method(&"hurt") and node.has_method(&"is_attacking")):
		add_collision_exception_with(node as PhysicsBody2D)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	velocity.y = minf(velocity.y + gravity_strength * delta, max_fall_speed)

	match _state:
		MotoState.MOVE:
			velocity.x = _dir * speed
		MotoState.WAIT:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_dir = -_dir
				_state = MotoState.MOVE

	move_and_slide()

	if _state == MotoState.MOVE and is_on_floor():
		_update_ledge_ray()
		var blocked := is_on_wall() and get_wall_normal().x * _dir < 0.0
		if blocked or not _ledge_ray.is_colliding():
			_state = MotoState.WAIT
			_timer = wait_time
			velocity.x = 0.0

	_update_visuals()
	_check_player()


func _update_ledge_ray() -> void:
	_ledge_ray.collision_mask = collision_mask
	_ledge_ray.position = Vector2(_dir * ledge_ray_offset.x, ledge_ray_offset.y)
	_ledge_ray.target_position = Vector2(0.0, ledge_ray_length)
	_ledge_ray.force_raycast_update()


func _update_visuals() -> void:
	if skin != null:
		skin.set("flip_h", (_dir > 0) != sprite_faces_right)
	if animation_player != null:
		var anim := anim_move if _state == MotoState.MOVE else anim_wait
		if anim != _current_anim and animation_player.has_animation(anim):
			_current_anim = anim
			animation_player.play(anim)


func _check_player() -> void:
	for body in hitbox.get_overlapping_bodies():
		if _dead:
			return
		_touch(body)


func _touch(body: Node2D) -> void:
	if not body.has_method(&"hurt"):
		return
	var attacking: bool = body.has_method(&"is_attacking") and body.is_attacking()
	if attacking:
		if body.has_method(&"hit_badnik"):
			body.hit_badnik()
		_bounce(body)
		destroy()
	else:
		body.hurt(global_position.x)


func _bounce(body: Node2D) -> void:
	if body is CharacterBody2D:
		var player := body as CharacterBody2D
		if not player.is_on_floor() and player.velocity.y > 0.0:
			player.velocity.y = -maxf(player.velocity.y, bounce_min_speed)


func destroy() -> void:
	if _dead:
		return
	_dead = true
	hitbox.set_deferred("monitoring", false)
	var scene := get_tree().current_scene
	var parent := get_parent()
	if explosion_scene != null:
		var fx := explosion_scene.instantiate() as Node2D
		if fx != null:
			fx.global_position = global_position
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
