extends Node

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("DebugMenu"):
		ScreenFade.change_scene("res://Scenes/Presentation/Title_Screen.tscn")
