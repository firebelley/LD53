extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = create_tween()
	tween.tween_property(%PanelContainer, "scale", Vector2.ZERO, 0)
	tween.tween_property(%PanelContainer, "scale", Vector2.ONE, .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _unhandled_input(event):
	if event.is_action_pressed("jump"):
		get_tree().change_scene_to_file("res://scenes/Main.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	%PanelContainer.pivot_offset = %PanelContainer.size / 2.0
