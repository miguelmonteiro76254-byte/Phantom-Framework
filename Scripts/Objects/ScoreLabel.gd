class_name ScorePopup
extends Sprite2D

const FOLDER := "res://sprites/HUD/ScorePopup/"

@export var score_values: Array[int] = [100, 200, 500, 1000]
@export var rise_distance := 5.0
@export var rise_time := 0.2
@export var hold_time := 1.0

var points := 100


func _ready() -> void:
	z_index = 200
	hframes = 1
	vframes = 1
	frame = 0
	texture = _texture_for(points)
	var tween := create_tween()
	tween.tween_property(self, "position:y", -rise_distance, rise_time).as_relative()
	tween.tween_interval(hold_time)
	tween.tween_callback(queue_free)


func _texture_for(value: int) -> Texture2D:
	var path := "%s%d.png" % [FOLDER, value]
	if ResourceLoader.exists(path):
		return load(path)
	var best := 0
	for n in score_values:
		if n <= value and n > best:
			best = n
	path = "%s%d.png" % [FOLDER, best]
	if ResourceLoader.exists(path):
		return load(path)
	return null
