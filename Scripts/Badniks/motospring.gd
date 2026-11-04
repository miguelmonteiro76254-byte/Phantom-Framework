class_name Motospring
extends Motobug

@export_group("Spring")
@export var spring_area: Area2D
@export var spring_area_size := Vector2(28.0, 10.0)
@export var spring_area_offset := Vector2(0.0, -14.0)
@export var spring_strength := 960.0
@export var spring_cooldown := 0.15
@export var anim_bounce: StringName = &"bounce"
@export var bounce_sound: AudioStreamPlayer

@export_group("Kill")
@export var spindash_kill_speed := 470.0

var _spring_cd := 0.0


func _ready() -> void:
	super._ready()

	if spring_area == null:
		spring_area = get_node_or_null("SpringArea") as Area2D
	if spring_area == null:
		spring_area = Area2D.new()
		spring_area.name = "SpringArea"
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = spring_area_size
		shape.shape = rect
		shape.position = spring_area_offset
		spring_area.add_child(shape)
		add_child(spring_area)
	spring_area.collision_layer = 0
	spring_area.collision_mask = player_mask
	spring_area.monitorable = false

	if bounce_sound == null:
		bounce_sound = get_node_or_null("BounceSound") as AudioStreamPlayer
	if animation_player != null:
		animation_player.animation_finished.connect(_on_bounce_finished)


func _physics_process(delta: float) -> void:
	_spring_cd = maxf(_spring_cd - delta, 0.0)
	super._physics_process(delta)


func _check_player() -> void:
	for body in spring_area.get_overlapping_bodies():
		if _dead:
			return
		_touch(body)
	if _dead:
		return
	super._check_player()


func _touch(body: Node2D) -> void:
	if not body.has_method(&"hurt"):
		return

	var attacking: bool = body.has_method(&"is_attacking") and body.is_attacking()
	var jumping: bool = body.get("is_jumping") == true
	var roll_speed: float = absf(float(body.get("ground_speed")))

	if attacking and not jumping and roll_speed >= spindash_kill_speed:
		destroy()
		return

	if _in_spring_area(body):
		var rising := false
		if body is CharacterBody2D:
			var cb := body as CharacterBody2D
			rising = not cb.is_on_floor() and cb.velocity.y < 0.0
		if not rising and _spring_cd <= 0.0 and body.has_method(&"spring"):
			_spring_cd = spring_cooldown
			body.spring(Vector2(0.0, -spring_strength))
			_play_bounce()
		return

	if attacking and not jumping:
		return

	body.hurt(global_position.x)


func _in_spring_area(body: Node2D) -> bool:
	return spring_area.overlaps_body(body)


func _play_bounce() -> void:
	if animation_player != null and animation_player.has_animation(anim_bounce):
		_current_anim = anim_bounce
		animation_player.stop()
		animation_player.play(anim_bounce)
	if bounce_sound != null:
		bounce_sound.play()


func _on_bounce_finished(anim_name: StringName) -> void:
	if anim_name == anim_bounce:
		_current_anim = &""
