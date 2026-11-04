class_name LostRing
extends Ring


@export var fall_gravity := 337.5
@export var bounce := 0.75
@export var world_mask := 1
@export var pickup_delay := 1.0
@export var lifetime := 4.3
@export var blink_time := 1.2
@export var blink_interval := 0.06

var velocity := Vector2.ZERO
var _age := 0.0


func _ready() -> void:
	super._ready()
	collectable = false


func _physics_process(delta: float) -> void:
	if collected:
		return
	_age += delta
	if _age >= pickup_delay:
		collectable = true
	if _age >= lifetime:
		queue_free()
		return
	visible = true if lifetime - _age > blink_time else int(_age / blink_interval) % 2 == 0

	velocity.y += fall_gravity * delta
	var motion := velocity * delta
	var query := PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + motion + motion.normalized() * radius,
			world_mask)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position += motion
	else:
		var n: Vector2 = hit.normal
		global_position = hit.position + n * radius
		var vn := n * velocity.dot(n)
		var vt := velocity - vn
		velocity = vt - vn * bounce

	super._physics_process(delta)
