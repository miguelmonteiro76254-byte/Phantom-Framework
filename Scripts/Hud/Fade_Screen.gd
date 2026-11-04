extends CanvasLayer

signal scene_changed

var fade_time := 0.5
var fade_in_time := 0.0
var start_color := Color(0.02, 0.03, 0.12, 0.0)
var mid_color := Color(0.02, 0.03, 0.12, 0.85)
var end_color := Color.BLACK

var _rect: ColorRect
var _tween: Tween
var _covered := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.color = start_color
	_rect.visible = false
	add_child(_rect)


func is_fading() -> bool:
	return _covered


func fade_out(time: float = -1.0) -> void:
	if _tween and _tween.is_running():
		await _tween.finished
		return
	if _covered:
		return
	_covered = true
	var t := fade_time if time < 0.0 else time
	_rect.color = start_color
	_rect.visible = true
	_tween = create_tween()
	_tween.tween_property(_rect, "color", mid_color, t * 0.6)
	_tween.tween_property(_rect, "color", end_color, t * 0.4)
	await _tween.finished


func change_scene(path: String, do_fade: bool = true) -> void:
	if not ResourceLoader.exists(path):
		push_warning("ScreenFade: scene not found: %s" % path)
		return
	if do_fade:
		await fade_out()
	var tree := get_tree()
	tree.paused = false
	tree.change_scene_to_file(path)
	await tree.process_frame
	await tree.process_frame
	scene_changed.emit()
	await _reveal()


func reload_scene(do_fade: bool = true) -> void:
	if do_fade:
		await fade_out()
	var tree := get_tree()
	tree.paused = false
	tree.reload_current_scene()
	await tree.process_frame
	await tree.process_frame
	scene_changed.emit()
	await _reveal()


func clear() -> void:
	_kill_tween()
	_rect.visible = false
	_rect.color = start_color
	_covered = false


func _reveal() -> void:
	if fade_in_time > 0.0:
		_kill_tween()
		_tween = create_tween()
		_tween.tween_property(_rect, "color", Color(end_color, 0.0), fade_in_time)
		await _tween.finished
	clear()


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
