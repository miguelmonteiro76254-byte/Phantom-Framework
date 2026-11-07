extends Area2D

@export var spawn_offset := Vector2(0.0, -16.0)

var activated := false

@export var sprite: AnimationPlayer
@export var sound: AudioStreamPlayer2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.animation_finished.connect(_on_animation_finished)
	if Checkpoint.is_valid_here() and Checkpoint.checkpoint_position == global_position + spawn_offset:
		activated = true
		sprite.play("after")
	else:
		sprite.play("before")

func _on_body_entered(body: Node2D) -> void:
	if activated:
		return
	if not body.is_in_group("player"):
		return
	activated = true
	Checkpoint.set_checkpoint(global_position + spawn_offset)
	sound.play()
	sprite.play("transition")

func _on_animation_finished() -> void:
	if sprite.animation == "transition":
		sprite.play("after")
