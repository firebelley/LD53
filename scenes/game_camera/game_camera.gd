extends Node2D

@onready var shaky_camera: Camera2D = $ShakyCamera2D

var target_position: Vector2 = Vector2.ZERO


func _ready():
	shaky_camera.make_current()


func _process(delta):
	var player = get_tree().get_first_node_in_group("player")
	
	if player != null:
		target_position = player.global_position;
	
	global_position = global_position.lerp(target_position, 1.0 - exp(-16 * delta))
	shaky_camera.global_position = global_position.round()
