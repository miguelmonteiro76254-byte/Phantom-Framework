class_name Ring
extends Area2D


@export var value := 1
@export var radius := 8.0
@export var sound: AudioStreamPlayer
@export var draw_placeholder := true

var collectable := true
var collected := false
var _has_visual := false


func _ready() -> void:
	if sound == null:
		sound = get_node_or_null("Sound") as AudioStreamPlayer
	for c in get_children():
		if c is Sprite2D or c is AnimatedSprite2D:
			_has_visual = true
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		add_child(shape)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not collectable or collected:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("add_rings"):
			collect(body)
			return


func collect(player: Node) -> void:
	if collected:
		return
	collected = true
	player.add_rings(value)
	hide()
	set_deferred("monitoring", false)
	if sound != null:
		sound.play()
		await sound.finished
	queue_free()


func _draw() -> void:
	if _has_visual or not draw_placeholder:
		return
	draw_arc(Vector2.ZERO, radius - 1.5, 0.0, TAU, 24, Color(1.0, 0.82, 0.1), 3.0)
