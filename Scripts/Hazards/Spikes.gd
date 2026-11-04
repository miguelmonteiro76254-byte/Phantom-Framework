class_name Spike
extends StaticBody2D


@export var size := Vector2(32.0, 16.0)
@export var hurt_height := 6.0
@export var side_inset := 2.0
@export var player_mask := 1
@export var draw_placeholder := true
@export var color := Color(0.78, 0.8, 0.88)

var _hurt_area: Area2D


func _ready() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var body_shape := CollisionShape2D.new()
		body_shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = size
		body_shape.shape = rect
		add_child(body_shape)

	_hurt_area = Area2D.new()
	_hurt_area.name = "HurtArea"
	_hurt_area.collision_layer = 0
	_hurt_area.collision_mask = player_mask
	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(maxf(size.x - side_inset * 2.0, 1.0), hurt_height)
	area_shape.shape = area_rect
	area_shape.position = Vector2(0.0, -size.y * 0.5 - hurt_height * 0.5)
	_hurt_area.add_child(area_shape)
	add_child(_hurt_area)
	queue_redraw()


func _physics_process(_delta: float) -> void:

	for body in _hurt_area.get_overlapping_bodies():
		if body.has_method("hurt") and body.has_method("is_vulnerable") and body.is_vulnerable():
			body.hurt(global_position.x, self)


func _draw() -> void:
	if not draw_placeholder:
		return
	var half := size * 0.5
	var teeth := maxi(int(size.x / 8.0), 1)
	var w := size.x / teeth
	for i in teeth:
		var x0 := -half.x + i * w
		draw_colored_polygon(PackedVector2Array([
			Vector2(x0, half.y),
			Vector2(x0 + w * 0.5, -half.y),
			Vector2(x0 + w, half.y),
		]), color)
