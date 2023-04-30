extends Node


func _ready():
	RenderingServer.set_default_clear_color(Color("0a010d"))
	$MusicPlayer.play()
	GameEvents.game_started.connect(on_game_started)
	

func on_game_started():
	$DeliverLabel.queue_free()
