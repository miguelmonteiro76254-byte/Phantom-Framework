class_name LevelSelect
extends Control

enum Stage { ZONE, PLAYER, CPU }

const MAX_ACTS := 3

static var has_selection := false
static var selected_room := ""
static var selected_zone := ""
static var selected_act := 1
static var selected_player := ""
static var selected_cpu := ""

@export_group("Content")
@export var zones: Array[LevelSelectZone] = []
@export var scene_folders: Array[String] = [
	"res://Scenes/Presentation",
	"res://Scenes/Zones",
]
@export var zone_order: Array[String] = []
@export var zone_names: Dictionary = {}
@export_dir var icon_folder := ""
@export var default_icon: Texture2D
@export var player_folder := "res://Entities/Player"
@export var cpu_folder := "res://Entities/CPU"
@export_file("*.tscn") var title_scene: String
@export var title_text := ""
@export var player_title_text := "PLAYER SELECT"
@export var cpu_title_text := "CPU SELECT"
@export var null_option_name := "NULL"
@export var items_per_page := 7

@export_group("Audio")
@export var music: AudioStream
@export var music_volume_db := 0.0
@export var music_bus: StringName = &"Master"
@export var music_fade_time := 0.5
@export var move_sound: AudioStream
@export var confirm_sound: AudioStream

@export_group("Input")
@export var input_accept: StringName = &"ui_accept"
@export var input_cancel: StringName = &"ui_cancel"
@export var input_up: StringName = &"ui_up"
@export var input_down: StringName = &"ui_down"
@export var input_left: StringName = &"ui_left"
@export var input_right: StringName = &"ui_right"

@export_group("Look")
@export var font: Font
@export var background_color := Color("0828a8")
@export var background_texture: Texture2D
@export var background_scroll := Vector2.ZERO
@export var title_color := Color.WHITE
@export var selected_color := Color("f8f800")
@export var unselected_color := Color.WHITE
@export var blink_color := Color("f89000")
@export var blink_interval := 0.0

@export_group("Layout")
@export var column_sizes: Array[int] = [7, 6]
@export var name_x: Array[float] = [0.075, 0.545]
@export var act_x: Array[float] = [0.45, 0.92]
@export var first_row_y := 0.13
@export var row_spacing := 0.107
@export var font_size := 0
@export var icon_center := Vector2(0.69, 0.85)
@export var icon_size := 0.345
@export var title_y := 0.2
@export var page_y := 0.3
@export var list_y := 0.4
@export var list_line_height := 0.07

var _zones: Array[LevelSelectZone] = []
var _zone_index := 0
var _act := 0

var _entries: Array[Dictionary] = []
var _index := 0

var _busy := false
var _stage := Stage.ZONE
var _blink_on := true
var _blink_time := 0.0
var _scroll := Vector2.ZERO
var _act_step := 0.0

var _bg: ColorRect
var _bg_tex: TextureRect
var _title: Label
var _zone_page_label: Label
var _page_label: Label
var _icon: TextureRect
var _name_labels: Array[Label] = []
var _act_labels: Array[Label] = []
var _rows: Array[Label] = []
var _sfx: AudioStreamPlayer
var _music: AudioStreamPlayer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	_build_zones()
	_build_ui()
	_layout()
	get_viewport().size_changed.connect(_layout)
	_start_music()
	_enter_stage(Stage.ZONE)


func _process(delta: float) -> void:
	if background_texture != null and background_scroll != Vector2.ZERO:
		_scroll += background_scroll * delta
		_apply_bg_scroll()
	if blink_interval > 0.0:
		_blink_time += delta
		if _blink_time >= blink_interval:
			_blink_time = 0.0
			_blink_on = not _blink_on
			_update_colors()


func _build_zones() -> void:
	_zones.clear()
	if zones.is_empty():
		_zones_from_folders()
	else:
		for z in zones:
			if z != null:
				_zones.append(z)
	if _zones.is_empty():
		push_warning("LevelSelect: nenhuma zona configurada ou encontrada")
	else:
		_act = _nav_acts(_zones[0])[0]


func _zones_from_folders() -> void:
	var regex := RegEx.create_from_string("^(.*?)[ _\\-]*(?:act|ato)?[ _\\-]*([1-3])$")
	var groups := {}
	for folder in scene_folders:
		var found: Array[String] = []
		_collect(folder, found)
		found.sort()
		for path in found:
			if path == scene_file_path:
				continue
			var key := path.get_file().get_basename().to_lower()
			var act := 1
			var m := regex.search(key)
			if m != null and not m.get_string(1).is_empty():
				key = m.get_string(1)
				act = m.get_string(2).to_int()
			if not groups.has(key):
				groups[key] = {}
			groups[key][act] = path
	var names := {}
	for k in zone_names:
		names[String(k).to_lower()] = String(zone_names[k])
	var order: Array[String] = []
	for k in zone_order:
		var lowered := k.to_lower()
		if groups.has(lowered) and not order.has(lowered):
			order.append(lowered)
	var rest: Array[String] = []
	for k in groups:
		if not order.has(String(k)):
			rest.append(String(k))
	rest.sort()
	order.append_array(rest)
	for key in order:
		var zone := LevelSelectZone.new()
		zone.zone_name = String(names.get(key, String(key).to_upper().replace("_", " ").replace("-", " ")))
		var acts: Dictionary = groups[key]
		zone.acts.resize(MAX_ACTS)
		for n in acts.keys():
			zone.acts[clampi(int(n) - 1, 0, MAX_ACTS - 1)] = acts[n]
		if not icon_folder.is_empty():
			var icon_path := icon_folder.path_join(String(key) + ".png")
			if ResourceLoader.exists(icon_path):
				zone.icon = load(icon_path) as Texture2D
		_zones.append(zone)


func _scan_entities(folder: String, with_null: bool) -> void:
	if with_null:
		_entries.append({"name": null_option_name, "path": ""})
	var found: Array[String] = []
	_collect(folder, found)
	found.sort()
	for path in found:
		_entries.append({"name": _display_name(path), "path": path})
	if found.is_empty():
		push_warning("LevelSelect: no scene found %s" % folder)


func _display_name(path: String) -> String:
	return path.get_file().get_basename().to_upper().replace(" ", "_")


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("LevelSelect: no folder found: %s" % dir_path)
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


func _per_page() -> int:
	return column_sizes[0] + column_sizes[1]


func _col_start(col: int) -> int:
	return 0 if col == 0 else column_sizes[0]


func _local_col(local: int) -> int:
	return 0 if local < column_sizes[0] else 1


func _col_count(page: int, col: int) -> int:
	var first := page * _per_page() + _col_start(col)
	return clampi(_zones.size() - first, 0, column_sizes[col])


func _slot_center_y(slot: int) -> float:
	var row := slot - _col_start(_local_col(slot))
	return get_viewport_rect().size.y * (first_row_y + row * row_spacing)


func _valid_acts(zone: LevelSelectZone) -> Array[int]:
	var out: Array[int] = []
	for k in mini(zone.acts.size(), MAX_ACTS):
		if not zone.acts[k].is_empty():
			out.append(k)
	return out


func _nav_acts(zone: LevelSelectZone) -> Array[int]:
	var out := _valid_acts(zone)
	if out.is_empty():
		out.append(0)
	return out


func _closest_act(zone: LevelSelectZone, wanted: int) -> int:
	var acts := _nav_acts(zone)
	return wanted if acts.has(wanted) else acts[0]


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = background_color
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_bg_tex = TextureRect.new()
	_bg_tex.texture = background_texture
	_bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_tex.stretch_mode = TextureRect.STRETCH_TILE
	_bg_tex.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_bg_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_tex.visible = background_texture != null
	add_child(_bg_tex)

	_title = _make_label(title_color, HORIZONTAL_ALIGNMENT_CENTER)
	_page_label = _make_label(unselected_color, HORIZONTAL_ALIGNMENT_CENTER)
	_zone_page_label = _make_label(unselected_color, HORIZONTAL_ALIGNMENT_CENTER)

	for i in items_per_page:
		_rows.append(_make_label(unselected_color, HORIZONTAL_ALIGNMENT_CENTER))

	for slot in _per_page():
		_name_labels.append(_make_label(unselected_color, HORIZONTAL_ALIGNMENT_LEFT))
		for k in MAX_ACTS:
			_act_labels.append(_make_label(unselected_color, HORIZONTAL_ALIGNMENT_CENTER))

	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)

	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)


func _make_label(color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	if font != null:
		label.add_theme_font_override("font", font)
	add_child(label)
	return label


func _place_label(label: Label, pos: Vector2, label_size: Vector2, size_px: int) -> void:
	label.add_theme_font_size_override("font_size", size_px)
	label.position = pos
	label.size = label_size


func _layout() -> void:
	var s := get_viewport_rect().size
	var lh := s.y * row_spacing
	var name_px := font_size if font_size > 0 else int(round(s.y * 0.045))
	var act_px := int(round(name_px * 0.8))
	_act_step = s.y * 0.04

	_apply_bg_scroll()

	var list_lh := s.y * list_line_height
	_place_label(_title, Vector2(0, s.y * title_y - list_lh), Vector2(s.x, list_lh * 2.0), int(round(name_px * 1.15)))
	_place_label(_page_label, Vector2(0, s.y * page_y - list_lh * 0.5), Vector2(s.x, list_lh), name_px)
	for i in _rows.size():
		_place_label(_rows[i], Vector2(0, s.y * list_y + i * list_lh - list_lh * 0.5), Vector2(s.x, list_lh), name_px)

	_place_label(_zone_page_label, Vector2(0, s.y * 0.005), Vector2(s.x, s.y * 0.06), act_px)
	for slot in _name_labels.size():
		var col := _local_col(slot)
		var cy := _slot_center_y(slot)
		var width := s.x * maxf(0.1, act_x[col] - name_x[col] - 0.02)
		_place_label(_name_labels[slot], Vector2(s.x * name_x[col], cy - lh * 0.5), Vector2(width, lh), name_px)
		for k in MAX_ACTS:
			_place_label(_act_labels[slot * MAX_ACTS + k], Vector2.ZERO, Vector2(act_px * 1.5, _act_step), act_px)

	var icon_px := s.y * icon_size
	_icon.size = Vector2(icon_px, icon_px)
	_icon.position = Vector2(s.x * icon_center.x, s.y * icon_center.y) - _icon.size * 0.5

	_refresh()


func _apply_bg_scroll() -> void:
	if background_texture == null:
		return
	var ts := background_texture.get_size()
	_bg_tex.size = get_viewport_rect().size + ts
	_bg_tex.position = -Vector2(fposmod(_scroll.x, ts.x), fposmod(_scroll.y, ts.y))


func _start_music() -> void:
	if music == null:
		return
	if music is AudioStreamWAV:
		(music as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif "loop" in music:
		music.set("loop", true)
	_music = AudioStreamPlayer.new()
	_music.stream = music
	_music.volume_db = music_volume_db
	if AudioServer.get_bus_index(music_bus) != -1:
		_music.bus = music_bus
	add_child(_music)
	_music.play()


func _fade_music() -> void:
	if _music == null:
		return
	create_tween().tween_property(_music, "volume_db", -60.0, music_fade_time)


func _play(stream: AudioStream) -> void:
	if stream == null or _sfx == null:
		return
	_sfx.stream = stream
	_sfx.play()


func _enter_stage(stage: Stage) -> void:
	_stage = stage
	_entries.clear()
	match stage:
		Stage.ZONE:
			_title.text = title_text
		Stage.PLAYER:
			_index = 0
			_title.text = player_title_text
			_scan_entities(player_folder, false)
		Stage.CPU:
			_index = 0
			_title.text = cpu_title_text
			_scan_entities(cpu_folder, true)
	_refresh()


func _zone_page() -> int:
	return floori(float(_zone_index) / _per_page())


func _list_page() -> int:
	return floori(float(_index) / items_per_page)


func _page_count() -> int:
	if _stage == Stage.ZONE:
		return maxi(1, ceili(float(_zones.size()) / _per_page()))
	return maxi(1, ceili(float(_entries.size()) / items_per_page))


func _refresh() -> void:
	if _rows.is_empty():
		return
	var zone_mode := _stage == Stage.ZONE
	_title.visible = not _title.text.is_empty()
	_page_label.visible = not zone_mode
	for r in _rows:
		r.visible = not zone_mode
	_icon.visible = false
	_zone_page_label.visible = false
	for l in _name_labels:
		l.visible = false
	for l in _act_labels:
		l.visible = false

	if zone_mode:
		_refresh_zones()
	else:
		_refresh_list()
	_update_colors()


func _refresh_zones() -> void:
	var s := get_viewport_rect().size
	var page := _zone_page()
	var pages := _page_count()
	_zone_page_label.text = "<  %d - %d  >" % [page + 1, pages]
	_zone_page_label.visible = pages > 1

	for slot in _name_labels.size():
		var idx := page * _per_page() + slot
		if idx >= _zones.size():
			continue
		var zone := _zones[idx]
		var name_label := _name_labels[slot]
		name_label.text = zone.zone_name
		name_label.visible = true

		var valid := _valid_acts(zone)
		var n := valid.size()
		var col := _local_col(slot)
		var cy := _slot_center_y(slot)
		for k in MAX_ACTS:
			var a := _act_labels[slot * MAX_ACTS + k]
			a.visible = k < n
			if k < n:
				a.text = str(valid[k] + 1)
				var center := Vector2(s.x * act_x[col], cy + (k - (n - 1) * 0.5) * _act_step)
				a.position = center - a.size * 0.5

	if not _zones.is_empty():
		var current := _zones[_zone_index]
		_icon.texture = current.icon if current.icon != null else default_icon
		_icon.visible = _icon.texture != null


func _refresh_list() -> void:
	var page := _list_page()
	_page_label.text = "(%d - %d)" % [page + 1, _page_count()]
	for i in _rows.size():
		var idx := page * items_per_page + i
		_rows[i].text = _entries[idx]["name"] if idx < _entries.size() else ""


func _update_colors() -> void:
	if _name_labels.is_empty():
		return
	var sel := selected_color if _blink_on else blink_color
	if _stage == Stage.ZONE:
		var first := _zone_page() * _per_page()
		for slot in _name_labels.size():
			var idx := first + slot
			if idx >= _zones.size():
				continue
			var is_sel := idx == _zone_index
			_name_labels[slot].add_theme_color_override("font_color", sel if is_sel else unselected_color)
			var valid := _valid_acts(_zones[idx])
			for k in valid.size():
				var chosen := is_sel and valid[k] == _act
				_act_labels[slot * MAX_ACTS + k].add_theme_color_override(
					"font_color", sel if chosen else unselected_color
				)
	else:
		var first := _list_page() * items_per_page
		for i in _rows.size():
			_rows[i].add_theme_color_override(
				"font_color", sel if first + i == _index else unselected_color
			)


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if _stage == Stage.ZONE:
		_input_zone(event)
	else:
		_input_list(event)


func _input_zone(event: InputEvent) -> void:
	if event.is_action_pressed(input_down, true):
		_move_v(1)
	elif event.is_action_pressed(input_up, true):
		_move_v(-1)
	elif event.is_action_pressed(input_right, true):
		_move_h(1)
	elif event.is_action_pressed(input_left, true):
		_move_h(-1)
	elif event.is_action_pressed(input_accept):
		_confirm()
	elif event.is_action_pressed(input_cancel):
		_back()


func _input_list(event: InputEvent) -> void:
	if event.is_action_pressed(input_down, true):
		_move_list(1)
	elif event.is_action_pressed(input_up, true):
		_move_list(-1)
	elif event.is_action_pressed(input_right):
		_change_list_page(1)
	elif event.is_action_pressed(input_left):
		_change_list_page(-1)
	elif event.is_action_pressed(input_accept):
		_confirm()
	elif event.is_action_pressed(input_cancel):
		_back()


func _set_selection(index: int, act: int) -> void:
	if index == _zone_index and act == _act:
		return
	_zone_index = index
	_act = act
	_play(move_sound)
	_refresh()


func _move_v(direction: int) -> void:
	if _zones.is_empty():
		return
	var per := _per_page()
	var page := _zone_page()
	var local := _zone_index % per
	var col := _local_col(local)
	var base := page * per + _col_start(col)
	var acts := _nav_acts(_zones[_zone_index])
	var new_pos := maxi(acts.find(_act), 0) + direction
	if new_pos >= 0 and new_pos < acts.size():
		_set_selection(_zone_index, acts[new_pos])
		return
	var target := base + posmod(_zone_index - base + direction, _col_count(page, col))
	var target_acts := _nav_acts(_zones[target])
	_set_selection(target, target_acts[0] if direction > 0 else target_acts[target_acts.size() - 1])


func _move_h(direction: int) -> void:
	if _zones.is_empty():
		return
	var per := _per_page()
	var page := _zone_page()
	var local := _zone_index % per
	var col := _local_col(local)
	var row := local - _col_start(col)

	var new_page := page
	var new_col := col + direction
	if new_col < 0 or new_col > 1 or _col_count(page, new_col) == 0:
		new_page = posmod(page + direction, _page_count())
		new_col = 1 if direction < 0 else 0
		if _col_count(new_page, new_col) == 0:
			new_col = 0
	var new_row := mini(row, _col_count(new_page, new_col) - 1)
	var target := new_page * per + _col_start(new_col) + new_row
	_set_selection(target, _closest_act(_zones[target], _act))


func _move_list(direction: int) -> void:
	if _entries.is_empty():
		return
	_index = posmod(_index + direction, _entries.size())
	_play(move_sound)
	_refresh()


func _change_list_page(direction: int) -> void:
	if _entries.is_empty() or _page_count() <= 1:
		return
	var row := _index % items_per_page
	var new_page := posmod(_list_page() + direction, _page_count())
	_index = mini(new_page * items_per_page + row, _entries.size() - 1)
	_play(move_sound)
	_refresh()


func _confirm() -> void:
	match _stage:
		Stage.ZONE:
			if _zones.is_empty():
				return
			var zone := _zones[_zone_index]
			var act := _act
			if act >= zone.acts.size() or zone.acts[act].is_empty():
				push_warning("LevelSelect: a zona %s nao tem o ato %d" % [zone.zone_name, act + 1])
				return
			var room_path := zone.acts[act]
			if not ResourceLoader.exists(room_path):
				push_warning("LevelSelect: cena nao encontrada: %s" % room_path)
				return
			selected_room = room_path
			selected_zone = zone.zone_name
			selected_act = act + 1
			_play(confirm_sound)
			_enter_stage(Stage.PLAYER)
		Stage.PLAYER:
			if _entries.is_empty():
				return
			var path: String = _entries[_index]["path"]
			if not ResourceLoader.exists(path):
				push_warning("LevelSelect: cena nao encontrada: %s" % path)
				return
			selected_player = path
			_play(confirm_sound)
			_enter_stage(Stage.CPU)
		Stage.CPU:
			if _entries.is_empty():
				return
			var path: String = _entries[_index]["path"]
			if not path.is_empty() and not ResourceLoader.exists(path):
				push_warning("LevelSelect: cena nao encontrada: %s" % path)
				return
			selected_cpu = path
			has_selection = true
			_busy = true
			_play(confirm_sound)
			_fade_music()
			ScreenFade.change_scene(selected_room)


func _back() -> void:
	match _stage:
		Stage.CPU:
			_play(move_sound)
			_enter_stage(Stage.PLAYER)
		Stage.PLAYER:
			_play(move_sound)
			_enter_stage(Stage.ZONE)
		Stage.ZONE:
			if title_scene.is_empty() or not ResourceLoader.exists(title_scene):
				return
			_busy = true
			_fade_music()
			ScreenFade.change_scene(title_scene)
