extends Node


func _ready():
	RenderingServer.set_default_clear_color(Color("0a010d"))
	GameEvents.game_started.connect(on_game_started)
	GameEvents.victory.connect(on_victory)	
	GameEvents.game_over.connect(on_game_over)
	$MusicPlayer.play()
	$CenterContainer.visible = false
	

func on_game_started():
	$DeliverLabel.queue_free()


func on_victory():
	var tween = create_tween()
	tween.tween_property($CenterContainer, "visible", true, 0.0)
	tween.tween_property($CenterContainer, "scale", Vector2.ZERO, 0.0)
	tween.tween_property($CenterContainer, "scale", Vector2.ONE, .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func on_game_over():
	add_child(load("res://scenes/ui/game_over_screen.tscn").instantiate())
