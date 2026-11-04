extends CanvasLayer

const TITLE_SCREEN_PATH := "res://Scenes/Presentation/Title_Screen.tscn"

enum Option { RESUME, RESTART, QUIT }

@export_group("Nodes")
@export var dim_rect: ColorRect
@export var resume_label: Label
@export var restart_label: Label
@export var quit_label: Label

@export_group("Visual")
@export var font: Font
@export var font_size: int = 32
@export var selected_color: Color = Color.WHITE
@export var unselected_color: Color = Color.YELLOW
@export var dim_color: Color = Color(0, 0, 0, 0.6)
@export var dim_time: float = 0.15
@export var selected_scale: float = 1.15

@export_group("Input")
@export var pause_action: StringName = &"ui_accept"
@export var select_action: StringName = &"jump"

var _selected: int = Option.RESUME
var _busy := false
var _labels: Array[Label] = []
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_labels = [resume_label, restart_label, quit_label]

	for label in _labels:
		if label == null:
			continue
		if font:
			label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", font_size)
		label.pivot_offset = label.size / 2.0

	if dim_rect:
		dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim_rect.color = Color(dim_color, 0.0)

	ScreenFade.scene_changed.connect(_close_menu)
	_close_menu()


func _unhandled_input(event: InputEvent) -> void:
	if _busy or ScreenFade.is_fading():
		return

	if not get_tree().paused:
		if event.is_action_pressed(pause_action, false, true):
			_open_menu()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(select_action, false, true):
		_confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(pause_action, false, true):
		_close_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down", false, true):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up", false, true):
		_move_selection(-1)
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if get_tree().paused:
		_close_menu()
	else:
		_open_menu()


func _open_menu() -> void:
	_selected = Option.RESUME
	_update_labels(false)
	visible = true
	get_tree().paused = true
	if dim_rect:
		_kill_tween()
		_tween = create_tween()
		_tween.tween_property(dim_rect, "color", dim_color, dim_time)


func _close_menu() -> void:
	_kill_tween()
	visible = false
	get_tree().paused = false
	if dim_rect:
		dim_rect.color = Color(dim_color, 0.0)
	_busy = false


func _move_selection(direction: int) -> void:
	_selected = wrapi(_selected + direction, 0, _labels.size())
	_update_labels(true)


func _update_labels(animate: bool) -> void:
	for i in _labels.size():
		var label := _labels[i]
		if label == null:
			continue
		var is_selected := i == _selected
		label.add_theme_color_override(
			"font_color", selected_color if is_selected else unselected_color
		)
		var target_scale := Vector2.ONE * (selected_scale if is_selected else 1.0)
		if animate:
			var t := create_tween()
			t.tween_property(label, "scale", target_scale, 0.08)
		else:
			label.scale = target_scale


func _confirm() -> void:
	match _selected:
		Option.RESUME:
			_close_menu()
		Option.RESTART:
			_busy = true
			ScreenFade.reload_scene()
		Option.QUIT:
			_busy = true
			ScreenFade.change_scene(TITLE_SCREEN_PATH)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
