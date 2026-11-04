class_name Shield
extends Node2D

@export var animation_player: AnimationPlayer
@export var animation_name: StringName = &"idle"


func _ready() -> void:
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player != null and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
