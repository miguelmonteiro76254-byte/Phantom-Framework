extends Node

var has_checkpoint := false
var checkpoint_position := Vector2.ZERO
var checkpoint_scene := ""

func set_checkpoint(pos: Vector2) -> void:
	has_checkpoint = true
	checkpoint_position = pos
	checkpoint_scene = get_tree().current_scene.scene_file_path

func is_valid_here() -> bool:
	if not has_checkpoint:
		return false
	if checkpoint_scene != get_tree().current_scene.scene_file_path:
		reset_checkpoint()
		return false
	return true

func reset_checkpoint() -> void:
	has_checkpoint = false
	checkpoint_position = Vector2.ZERO
	checkpoint_scene = ""
