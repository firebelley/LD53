extends Node


signal enemy_banished(enemy: Node2D, points: int)
signal game_started
signal victory
signal player_health_changed(current: int, max: int)
signal game_over


func emit_enemy_banished(enemy: Node2D, points: int):
	enemy_banished.emit(enemy, points)
	if enemy.has_method("is_dummy") && enemy.is_dummy():
		game_started.emit()


func emit_victory():
	victory.emit()
	

func emit_player_health_change(current: int, max: int):
	player_health_changed.emit(current, max)


func emit_game_over():
	game_over.emit()
