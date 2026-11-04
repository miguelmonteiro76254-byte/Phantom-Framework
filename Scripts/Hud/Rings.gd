extends Label

@export var player: Node
@export var prefix := "RINGS: "


func _ready() -> void:
	text = prefix + "0"
	while player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			await get_tree().process_frame
	player.rings_changed.connect(_on_rings_changed)
	_on_rings_changed(player.rings)


func _on_rings_changed(count: int) -> void:
	text = prefix + str(count)
