class_name Lives
extends RefCounted

const START_LIVES := 3

static var count := START_LIVES


static func lose(amount: int = 1) -> void:
	count = maxi(count - amount, 0)


static func add(amount: int = 1) -> void:
	count += amount


static func reset() -> void:
	count = START_LIVES


static func is_game_over() -> bool:
	return count <= 0
