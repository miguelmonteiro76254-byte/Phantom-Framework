extends Node

signal changed(count: int)

var total := 7
var count := 0


func add(amount: int = 1) -> void:
	set_count(count + amount)


func set_count(value: int) -> void:
	var new_count := clampi(value, 0, total)
	if new_count == count:
		return
	count = new_count
	changed.emit(count)


func reset() -> void:
	set_count(0)


func is_full() -> bool:
	return count >= total
