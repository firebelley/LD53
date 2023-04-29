extends Node2D

@onready var animation_player = $AnimationPlayer


func _ready():
	animation_player.play("default")
	animation_player.queue("idle")


func _process(delta):
	animation_player.speed_scale = 1.0 / Engine.time_scale


func set_initial_direction(direction: Vector2):
	rotation = direction.angle()


func set_direction(direction: Vector2):
	if animation_player.assigned_animation != "punch":
		var adjusted_delta = get_process_delta_time() / Engine.time_scale
		rotation = lerp_angle(rotation, direction.angle(), 1.0 - exp(-7 * adjusted_delta))


func punch():
	animation_player.play("punch")


func cleanup():
	if animation_player.assigned_animation != "punch":
		queue_free()
