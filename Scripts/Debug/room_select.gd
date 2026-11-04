class_name RoomSelect
extends Control

enum Stage { ROOM, PLAYER, CPU }

static var has_selection := false
static var selected_room := ""
static var selected_player := ""
static var selected_cpu := ""

@export var scene_folders: Array[String] = [
	"res://Scenes/Presentation",
	"res://Scenes/Zones",
]
@onready var player_folder := "res://Entities/Player"
@onready var cpu_folder := "res://Entities/CPU"
@export_file("*.tscn") var title_scene: String
@export var title_text := "ROOM SELECT"
@export var player_title_text := "PLAYER SELECT"
@export var cpu_title_text := "CPU SELECT"
@export var null_option_name := "NULL"
@export var name_prefix := ""
@export var items_per_page := 7
@export var font: Font
@export var move_sound: AudioStream
@export var confirm_sound: AudioStream
@export_group("Input")
@export var input_accept: StringName = &"ui_accept"
@export var input_cancel: StringName = &"ui_cancel"
@export var input_up: StringName = &"ui_up"
@export var input_down: StringName = &"ui_down"
@export var input_left: StringName = &"ui_left"
@export var input_right: StringName = &"ui_right"
@export_group("Colors")
@export var background_color := Color.BLACK
@export var title_color := Color.WHITE
@export var selected_color := Color.WHITE
@export var unselected_color := Color(0.4, 0.4, 0.4)
@export_group("Layout")
@export var title_y := 0.25
@export var page_y := 0.385
@export var list_y := 0.45
@export var line_height := 0.0335
@export var font_size := 0

var _entries: Array[Dictionary] = []
var _index := 0
var _busy := false
var _stage := Stage.ROOM

var _bg: ColorRect
var _title: Label
var _page_label: Label
var _rows: Array[Label] = []
var _player: AudioStreamPlayer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_layout()
	get_viewport().size_changed.connect(_layout)
	_enter_stage(Stage.ROOM)


func _enter_stage(stage: Stage) -> void:
	_stage = stage
	_index = 0
	_entries.clear()
	match stage:
		Stage.ROOM:
			_title.text = title_text
			_scan_rooms()
		Stage.PLAYER:
			_title.text = player_title_text
			_scan_entities(player_folder, false)
		Stage.CPU:
			_title.text = cpu_title_text
			_scan_entities(cpu_folder, true)
	_refresh()


func _scan_rooms() -> void:
	for folder in scene_folders:
		var found: Array[String] = []
		_collect(folder, found)
		found.sort()
		for path in found:
			if path == scene_file_path:
				continue
			_entries.append({"name": name_prefix + _display_name(path), "path": path})
	if _entries.is_empty():
		push_warning("LevelSelect: nenhuma cena encontrada em %s" % str(scene_folders))


func _scan_entities(folder: String, with_null: bool) -> void:
	if with_null:
		_entries.append({"name": null_option_name, "path": ""})
	var found: Array[String] = []
	_collect(folder, found)
	found.sort()
	for path in found:
		_entries.append({"name": _display_name(path), "path": path})
	if found.is_empty():
		push_warning("LevelSelect: nenhuma cena encontrada em %s" % folder)


func _display_name(path: String) -> String:
	return path.get_file().get_basename().to_upper().replace(" ", "_")


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("LevelSelect: pasta nao encontrada: %s" % dir_path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			if dir.current_is_dir():
				_collect(dir_path.path_join(entry), out)
			else:
				var file_name := entry.trim_suffix(".remap")
				if file_name.ends_with(".tscn"):
					out.append(dir_path.path_join(file_name))
		entry = dir.get_next()
	dir.list_dir_end()


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = background_color
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_title = _make_label(title_color)
	_title.text = title_text
	_page_label = _make_label(unselected_color)
	for i in items_per_page:
		_rows.append(_make_label(unselected_color))

	_player = AudioStreamPlayer.new()
	add_child(_player)


func _make_label(color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 0.0
	label.anchor_bottom = 0.0
	label.add_theme_color_override("font_color", color)
	if font != null:
		label.add_theme_font_override("font", font)
	add_child(label)
	return label


func _layout() -> void:
	var h := get_viewport_rect().size.y
	var lh := h * line_height
	var size_px := font_size if font_size > 0 else int(round(lh))
	_place(_title, h * title_y, lh * 1.5, int(round(size_px * 1.15)))
	_place(_page_label, h * page_y, lh, size_px)
	for i in _rows.size():
		_place(_rows[i], h * list_y + i * lh, lh, size_px)


func _place(label: Label, center_y: float, height: float, size_px: int) -> void:
	label.add_theme_font_size_override("font_size", size_px)
	label.offset_left = 0.0
	label.offset_right = 0.0
	label.offset_top = center_y - height * 0.5
	label.offset_bottom = center_y + height * 0.5


func _page_count() -> int:
	return maxi(1, ceili(float(_entries.size()) / items_per_page))


func _current_page() -> int:
	return floori(float(_index) / items_per_page)


func _refresh() -> void:
	var page := _current_page()
	_page_label.text = "(%d/%d)" % [page + 1, _page_count()]
	for i in _rows.size():
		var idx := page * items_per_page + i
		var row := _rows[i]
		if idx < _entries.size():
			row.text = _entries[idx]["name"]
			row.add_theme_color_override(
				"font_color", selected_color if idx == _index else unselected_color
			)
		else:
			row.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed(input_down, true):
		_move(1)
	elif event.is_action_pressed(input_up, true):
		_move(-1)
	elif event.is_action_pressed(input_right):
		_change_page(1)
	elif event.is_action_pressed(input_left):
		_change_page(-1)
	elif event.is_action_pressed(input_accept):
		_confirm()
	elif event.is_action_pressed(input_cancel):
		_back()


func _move(direction: int) -> void:
	if _entries.is_empty():
		return
	_index = posmod(_index + direction, _entries.size())
	_play(move_sound)
	_refresh()


func _change_page(direction: int) -> void:
	if _entries.is_empty() or _page_count() <= 1:
		return
	var row := _index % items_per_page
	var new_page := posmod(_current_page() + direction, _page_count())
	_index = mini(new_page * items_per_page + row, _entries.size() - 1)
	_play(move_sound)
	_refresh()


func _confirm() -> void:
	if _entries.is_empty():
		return
	var path: String = _entries[_index]["path"]
	match _stage:
		Stage.ROOM:
			if not ResourceLoader.exists(path):
				push_warning("RoomSelect: no scene brah: %s" % path)
				return
			selected_room = path
			_play(confirm_sound)
			_enter_stage(Stage.PLAYER)
		Stage.PLAYER:
			if not ResourceLoader.exists(path):
				push_warning("RoomSelect: no scene brah: %s" % path)
				return
			selected_player = path
			_play(confirm_sound)
			_enter_stage(Stage.CPU)
		Stage.CPU:
			if not path.is_empty() and not ResourceLoader.exists(path):
				push_warning("RoomSelect: no scene brah: %s" % path)
				return
			selected_cpu = path
			has_selection = true
			_busy = true
			_play(confirm_sound)
			ScreenFade.change_scene(selected_room)


func _back() -> void:
	match _stage:
		Stage.CPU:
			_play(move_sound)
			_enter_stage(Stage.PLAYER)
		Stage.PLAYER:
			_play(move_sound)
			_enter_stage(Stage.ROOM)
		Stage.ROOM:
			if title_scene.is_empty() or not ResourceLoader.exists(title_scene):
				return
			_busy = true
			ScreenFade.change_scene(title_scene)


func _play(stream: AudioStream) -> void:
	if stream == null or _player == null:
		return
	_player.stream = stream
	_player.play()
