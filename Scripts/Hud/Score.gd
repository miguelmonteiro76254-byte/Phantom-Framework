extends Node

signal changed(points: int)
signal extra_life_earned

var life_every := 50000
var points := 0

var _next_life := 50000


func add(amount: int) -> void:
	if amount <= 0:
		return
	points += amount
	while points >= _next_life:
		_next_life += life_every
		Lives.count += 1
		extra_life_earned.emit()
	changed.emit(points)


func reset() -> void:
	points = 0
	_next_life = life_every
	changed.emit(points)
