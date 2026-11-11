extends Node

enum Option { START, LEVEL_SELECT }

@export_file("*.tscn") var next_scene: String
@export_file("*.tscn") var level_select_scene: String
@export var music: AudioStreamPlayer
@export var start_label: Label
@export var level_select_label: Label
@export var input_accept: StringName = &"ui_accept"
@export var input_up: StringName = &"ui_up"
@export var input_down: StringName = &"ui_down"
@export var play_music_on_start := true
@export var move_sound: AudioStream
@export_range(-40.0, 6.0, 0.5) var move_sound_volume_db := 0.0
@export_group("Selection Colors")
@export var selected_color := Color(1.0, 0.9, 0.2)
@export var unselected_color := Color(1.0, 1.0, 1.0, 0.6)

var _starting := false
var _selected: Option = Option.START
var _move_player: AudioStreamPlayer


func _ready() -> void:
	Emeralds.reset()
	Lives.reset()
	if music == null:
		music = get_node_or_null("Music") as AudioStreamPlayer
	if start_label == null:
		start_label = get_node_or_null("Start") as Label
	if level_select_label == null:
		level_select_label = get_node_or_null("Level Select") as Label
	if music != null and play_music_on_start and not music.playing:
		music.play()
	if move_sound != null:
		_move_player = AudioStreamPlayer.new()
		_move_player.stream = move_sound
		_move_player.volume_db = move_sound_volume_db
		add_child(_move_player)
	_update_selection()


func _unhandled_input(event: InputEvent) -> void:
	if _starting:
		return
	if event.is_echo():
		return
	if event.is_action_pressed(input_down):
		_move_selection(1)
	elif event.is_action_pressed(input_up):
		_move_selection(-1)
	elif event.is_action_pressed(input_accept):
		_confirm()


func _move_selection(direction: int) -> void:
	var count := Option.size()
	_selected = ((_selected + direction + count) % count) as Option
	_update_selection()
	if _move_player != null:
		_move_player.play()


func _update_selection() -> void:
	_set_label_color(start_label, _selected == Option.START)
	_set_label_color(level_select_label, _selected == Option.LEVEL_SELECT)


func _set_label_color(label: Label, is_selected: bool) -> void:
	if label == null:
		return
	label.add_theme_color_override(
		"font_color", selected_color if is_selected else unselected_color
	)


func _confirm() -> void:
	match _selected:
		Option.START:
			_go_to_scene(next_scene)
		Option.LEVEL_SELECT:
			_go_to_scene(level_select_scene)


func _go_to_scene(scene_path: String) -> void:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("TitleScreen: no scene bro")
		return
	_starting = true
	if music != null:
		music.stop()
	ScreenFade.change_scene(scene_path)
