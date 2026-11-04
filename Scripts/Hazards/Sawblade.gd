class_name SawBlade
extends Area2D

@export_category("References")
@export var sprite: Sprite2D
@export var animationPlayer: AnimationPlayer
@export var audioPlayer: AudioStreamPlayer2D

@export_category("Behavior")
@export var working: bool = true

@onready var _hurt_area = $Area2D
var _wasWorking: bool

func _process(_delta: float) -> void :
	if working != _wasWorking:
		_wasWorking = working
		_update_animation()

func _physics_process(_delta: float) -> void:

	for body in _hurt_area.get_overlapping_bodies():
		if body.has_method("hurt") and body.has_method("is_vulnerable") and body.is_vulnerable():
			body.hurt(global_position.x, self)

func _update_animation() -> void :
	if animationPlayer:
		if working:
			if animationPlayer.has_animation("default"):
				animationPlayer.play("default")
		else:
			if animationPlayer.has_animation("stop"):
				animationPlayer.play("stop")
	if audioPlayer:
		if working:
			if not audioPlayer.playing:
				audioPlayer.play()
		else:
			audioPlayer.stop()
