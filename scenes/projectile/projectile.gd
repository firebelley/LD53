extends Node2D

const SPEED = 75

var direction: Vector2


func _process(delta):
	global_position += SPEED * direction * delta


func start(dir: Vector2):
	direction = dir

