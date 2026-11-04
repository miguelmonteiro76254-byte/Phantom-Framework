@tool
class_name LayerSwitchSensor
extends Area2D

enum Mode { RED, BLUE }

@export var mode: Mode = Mode.RED:
	set(value):
		mode = value
		_update_sprite()
@export var sprite: Sprite2D:
	set(value):
		sprite = value
		_update_sprite()
@export var layer_a := 11
@export var layer_b := 12
@export var red_color := Color.RED
@export var blue_color := Color.BLUE


func _ready() -> void:
	_update_sprite()
	if Engine.is_editor_hint():
		return
	var s := _get_sprite()
	if s != null:
		s.visible = false
	body_entered.connect(_on_body_entered)


func _get_sprite() -> Sprite2D:
	if sprite != null:
		return sprite
	if is_inside_tree():
		return get_node_or_null("Sprite2D") as Sprite2D
	return null


func _update_sprite() -> void:
	var s := _get_sprite()
	if s == null:
		return
	s.modulate = red_color if mode == Mode.RED else blue_color


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var red := mode == Mode.RED
	body.set_collision_mask_value(layer_a, not red)
	body.set_collision_mask_value(layer_b, red)
