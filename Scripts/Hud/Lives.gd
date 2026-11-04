@tool
extends CanvasLayer

@export_category("Title Card")
@export var word1_label: Label:
	set(v):
		word1_label = v
		_update()
@export var word2_label: Label:
	set(v):
		word2_label = v
		_update()
@export var act_label: Label:
	set(v):
		act_label = v
		_update()
@export var act_sprite: Sprite2D:
	set(v):
		act_sprite = v
		_update()
@export var encore_node: CanvasItem:
	set(v):
		encore_node = v
		_update()
@export var zone_name_word := "GREEN HILL":
	set(v):
		zone_name_word = v
		_update()
@export var act_texture_1: Texture2D:
	set(v):
		act_texture_1 = v
		_update()
@export var act_texture_2: Texture2D:
	set(v):
		act_texture_2 = v
		_update()
@export var act_texture_3: Texture2D:
	set(v):
		act_texture_3 = v
		_update()
@export_range(0, 3) var act_number := 1:
	set(v):
		act_number = v
		_update()
@export var encore := true:
	set(v):
		encore = v
		_update()

@export_category("Lives")
@export var lives_label: Label:
	set(v):
		lives_label = v
		_refresh()
@export var icon_node: CanvasItem
@export var icon_folder := "res://sprites/HUD/life_icons"
@export var name_node: CanvasItem
@export var name_folder := "res://sprites/HUD/life_names"
@export var prefix := "":
	set(v):
		prefix = v
		_refresh()

@export_category("Timer")
@export var min_label: Label:
	set(v):
		min_label = v
		_update_timer_labels()
@export var sec_label: Label:
	set(v):
		sec_label = v
		_update_timer_labels()
@export var ms_label: Label:
	set(v):
		ms_label = v
		_update_timer_labels()
@export var time_limit := 600.0

@export_category("Score")
@export var score_label: Label:
	set(v):
		score_label = v
		_refresh_score()
@export var bonus_panel: CanvasItem
@export var time_bonus_label: Label
@export var ring_bonus_label: Label
@export var extra_life_sound: AudioStreamPlayer
@export var time_bonus_limits: Array[float] = [30.0, 45.0, 60.0, 90.0, 120.0, 150.0, 180.0, 300.0]
@export var time_bonus_values: Array[int] = [50000, 10000, 5000, 4000, 3000, 2000, 1000, 500]
@export var ring_bonus_min_rings := 50
@export var ring_bonus_per_ring := 100

var elapsed := 0.0
var timer_running := true

var _last := -1
var _player: Player
var _icon_applied := false
var _name_applied := false


func _ready() -> void:
	layer = 50
	_refresh()
	_refresh_score()
	_update()
	_update_timer_labels()
	if not Engine.is_editor_hint():
		_player = get_tree().get_first_node_in_group(&"player") as Player
		Score.changed.connect(_on_score_changed)
		Score.extra_life_earned.connect(_on_extra_life)
		if bonus_panel:
			bonus_panel.hide()
		_apply_life_icon()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if Lives.count != _last:
		_refresh()
	if not _icon_applied or not _name_applied:
		if _player == null:
			_player = get_tree().get_first_node_in_group(&"player") as Player
		_apply_life_icon()
	_process_timer(delta)


func _character_name() -> String:
	if LevelSelect.has_selection and not LevelSelect.selected_player.is_empty():
		return LevelSelect.selected_player.get_file().get_basename()
	if _player != null:
		if not _player.scene_file_path.is_empty():
			return _player.scene_file_path.get_file().get_basename()
		return String(_player.name)
	return ""


func _apply_life_icon() -> void:
	if (icon_node == null or _icon_applied) and (name_node == null or _name_applied):
		return
	var character := _character_name()
	if character.is_empty():
		return
	if icon_node != null and not _icon_applied:
		_icon_applied = true
		_apply_texture(icon_node, icon_folder, character, "icone de vida", "icon_node")
	if name_node != null and not _name_applied:
		_name_applied = true
		_apply_texture(name_node, name_folder, character, "nome de vida", "name_node")


func _apply_texture(node: CanvasItem, folder: String, character: String, label: String, prop: String) -> void:
	var path := folder.path_join(character + ".png")
	if not ResourceLoader.exists(path):
		push_warning("HUD: %s nao encontrado: %s" % [label, path])
		return
	var tex := load(path) as Texture2D
	if node is TextureRect:
		(node as TextureRect).texture = tex
	elif node is Sprite2D:
		(node as Sprite2D).texture = tex
	else:
		push_warning("HUD: %s precisa ser TextureRect ou Sprite2D" % prop)


func _refresh() -> void:
	if lives_label == null:
		return
	if Engine.is_editor_hint():
		lives_label.text = prefix + "3"
		return
	_last = Lives.count
	lives_label.text = prefix + str(_last)


func _refresh_score() -> void:
	if score_label == null:
		return
	if Engine.is_editor_hint():
		score_label.text = "0"
		return
	score_label.text = str(Score.points)


func _on_score_changed(_points: int) -> void:
	_refresh_score()


func _on_extra_life() -> void:
	if extra_life_sound:
		extra_life_sound.play()


func _process_timer(delta: float) -> void:
	if not timer_running:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Player
		if _player == null:
			return
	if _player.act_cleared or _player.state == Player.State.DEAD:
		timer_running = false
		if _player.act_cleared and _player.state != Player.State.DEAD:
			_award_act_bonuses()
		return
	elapsed += delta
	if elapsed >= time_limit:
		elapsed = time_limit
		timer_running = false
		_update_timer_labels()
		_player.die()
		return
	_update_timer_labels()


func _time_bonus() -> int:
	for i in time_bonus_limits.size():
		if elapsed < time_bonus_limits[i]:
			return time_bonus_values[i] if i < time_bonus_values.size() else 0
	return 0


func _award_act_bonuses() -> void:
	var time_bonus := _time_bonus()
	var ring_bonus := 0
	if _player.rings >= ring_bonus_min_rings:
		ring_bonus = _player.rings * ring_bonus_per_ring
	if time_bonus_label:
		time_bonus_label.text = str(time_bonus)
	if ring_bonus_label:
		ring_bonus_label.text = str(ring_bonus)
	if bonus_panel:
		bonus_panel.show()
	Score.add(time_bonus + ring_bonus)


func _update_timer_labels() -> void:
	var total_ms := int(elapsed * 1000.0)
	var minutes := total_ms / 60000
	var seconds := (total_ms / 1000) % 60
	var ms := (total_ms % 1000) / 10
	if min_label:
		min_label.text = "%d" % minutes
	if sec_label:
		sec_label.text = "%02d" % seconds
	if ms_label:
		ms_label.text = "%02d" % ms


func _update() -> void:
	if word1_label:
		word1_label.text = zone_name_word
	if encore_node:
		encore_node.visible = encore
	if act_sprite:
		match act_number:
			1: act_sprite.texture = act_texture_1
			2: act_sprite.texture = act_texture_2
			3: act_sprite.texture = act_texture_3
			_: act_sprite.texture = null
		act_sprite.visible = act_number != 0 and act_sprite.texture != null
