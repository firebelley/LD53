extends Node2D

func _process(delta):
	global_rotation = 0
	$RayCast2D.force_raycast_update()
	
	var points = []
	points.append(Vector2(0, 0))
	if $RayCast2D.is_colliding():
		points.append(to_local($RayCast2D.get_collision_point()))
	else:
		points.append(Vector2.DOWN * 1000)
	
	$Line2D.points = points
	$EndParticles.position = points[1]


func kill():
	$AnimationPlayer.play("kill")
