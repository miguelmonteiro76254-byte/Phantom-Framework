class_name PlayerSpawner
extends Node2D

@export var default_player: PackedScene
@export var default_cpu: PackedScene
@export var cpu_spawn: Node2D
@export var cpu_offset := Vector2(128.0, 0.0)
@export var spawn_parent: Node

var player: Node
var cpu: Node


func _ready() -> void:
	_spawn_all.call_deferred()


func _spawn_all() -> void:
	var player_scene: PackedScene = default_player
	var cpu_scene: PackedScene = default_cpu
	if LevelSelect.has_selection:
		player_scene = _load_scene(LevelSelect.selected_player, default_player)
		cpu_scene = _load_scene(LevelSelect.selected_cpu, null)

	var cpu_position := global_position + cpu_offset
	if cpu_spawn != null:
		cpu_position = cpu_spawn.global_position

	player = _spawn(player_scene, global_position)
	cpu = _spawn(cpu_scene, cpu_position)


func _load_scene(path: String, fallback: PackedScene) -> PackedScene:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_warning("PlayerSpawner: cena nao existe: %s" % path)
		return fallback
	return load(path) as PackedScene


func _spawn(scene: PackedScene, at: Vector2) -> Node:
	if scene == null:
		return null
	var instance := scene.instantiate()
	var parent: Node = spawn_parent if spawn_parent != null else get_parent()
	parent.add_child(instance)
	if instance is Node2D:
		instance.global_position = at
	return instance
