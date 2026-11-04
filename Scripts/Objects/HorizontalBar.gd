class_name HorizontalBar
extends Area2D

@export var spin_speed_threshold := 300.0
@export var spin_rate_min := 8.0
@export var spin_rate_max := 20.0
@export var spin_rate_max_speed := 780.0
@export var grab_extra_height := 16.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	collision_layer = 0
	var shape := RectangleShape2D.new()
	var size := sprite.texture.get_size() * sprite.scale
	size.y += grab_extra_height
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = sprite.position
	add_child(col)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		var player := body as Player
		if player == null or not player.can_grab_bar():
			continue
		var speed := player.velocity.length()
		var rate := 0.0
		if speed >= spin_speed_threshold:
			var t := clampf(inverse_lerp(spin_speed_threshold, spin_rate_max_speed, speed), 0.0, 1.0)
			rate = lerpf(spin_rate_min, spin_rate_max, t)
		player.grab_bar(self, rate)
		return
