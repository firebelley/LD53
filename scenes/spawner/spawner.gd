@tool
extends Node2D
class_name Spawner

@export var extents: Vector2 = Vector2(16, 1)
@export var scene: PackedScene


func _ready():
	set_physics_process(Engine.is_editor_hint())


func _physics_process(delta):
	queue_redraw()


func _draw():
	draw_rect(get_rect(), Color.DARK_RED)


func spawn():
	if scene == null:
		return
	var position = get_random_spawn_point()
	var instance = scene.instantiate()
	add_sibling(instance)
	instance.global_position = position


func get_rect():
	return Rect2(Vector2.ZERO, extents * 2.0)


func get_random_spawn_point():
	var position = global_position
	position.x += randf_range(0, get_rect().size.x)
	return position 

