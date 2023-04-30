extends Node


func _ready():
	RenderingServer.set_default_clear_color(Color("0a010d"))
	$MusicPlayer.play()
