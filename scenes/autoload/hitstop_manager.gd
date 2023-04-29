extends Node


func hitstop():
	get_tree().paused = true
	await get_tree().create_timer(.05, true, false, true).timeout
	get_tree().paused = false


func shake_camera():
	var camera = get_tree().get_first_node_in_group("shaky_camera")
	if camera != null:
		camera.shake()
