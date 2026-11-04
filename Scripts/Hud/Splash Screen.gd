extends Control

@export_file("*.tscn") var target_scene: String
@export var music_player: AudioStreamPlayer

var _rect: ColorRect
var _transition_triggered := false

func _ready() -> void:
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.color = Color(0, 0, 0, 0)
	_rect.visible = false
	add_child(_rect)
	
	if music_player:
		music_player.finished.connect(_on_music_finished)

func _on_music_finished() -> void:
	if _transition_triggered:
		return
	_transition_triggered = true
	
	_rect.visible = true
	ScreenFade.change_scene(target_scene)
