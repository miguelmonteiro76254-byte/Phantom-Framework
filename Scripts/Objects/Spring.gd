@tool
class_name Spring
extends StaticBody2D

enum Direction { UP, RIGHT, LEFT }

@export var direction: Direction = Direction.UP:
	set(value):
		direction = value
		queue_redraw()
@export var size := Vector2(32.0, 16.0):
	set(value):
		size = value
		queue_redraw()
@export var strength := 960.0
@export var animation_player: AnimationPlayer
@export var anim_bounce: StringName = &"bounce"
@export var sound: Node
@export_flags_2d_physics var trigger_mask := 1
@export var trigger_overlap := 2.0
@export var trigger_thickness := 8.0
@export var draw_placeholder := true


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if sound == null:
		sound = get_node_or_null("Sound")

	var body_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	body_shape.shape = rect
	add_child(body_shape)

	var n := _normal()
	var half_along := (absf(n.x) * size.x + absf(n.y) * size.y) * 0.5
	var area = $Area2D
	area.collision_layer = 0
	area.collision_mask = trigger_mask
	area.monitorable = false
	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	if n.y != 0.0:
		area_rect.size = Vector2(maxf(size.x - 4.0, 1.0), trigger_thickness)
	else:
		area_rect.size = Vector2(trigger_thickness, maxf(size.y - 4.0, 1.0))
	area_shape.shape = area_rect
	area_shape.position = n * (half_along + trigger_thickness * 0.5 - trigger_overlap)
	area.add_child(area_shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _normal() -> Vector2:
	match direction:
		Direction.RIGHT:
			return Vector2.RIGHT
		Direction.LEFT:
			return Vector2.LEFT
	return Vector2.UP


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method(&"spring"):
		return
	body.spring(_normal() * strength)
	_play_feedback()


func _play_feedback() -> void:
	if animation_player != null and animation_player.has_animation(anim_bounce):
		animation_player.stop()
		animation_player.play(anim_bounce)
	if sound != null and sound.has_method(&"play"):
		sound.play()


func _draw() -> void:
	if not draw_placeholder:
		return
	for c in get_children():
		if c is Sprite2D or c is AnimatedSprite2D:
			return
	draw_rect(Rect2(-size * 0.5, size), Color(0.9, 0.7, 0.1))
	var n := _normal()
	var half := size * 0.5
	var face := Rect2(-half, size)
	if n.y != 0.0:
		face = Rect2(Vector2(-half.x, -half.y), Vector2(size.x, 4.0))
	elif n.x > 0.0:
		face = Rect2(Vector2(half.x - 4.0, -half.y), Vector2(4.0, size.y))
	else:
		face = Rect2(Vector2(-half.x, -half.y), Vector2(4.0, size.y))
	draw_rect(face, Color(0.9, 0.15, 0.15))
