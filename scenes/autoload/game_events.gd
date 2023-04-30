extends Node


signal enemy_banished(enemy: Node2D, points: int)
signal game_started()
signal victory()


func emit_enemy_banished(enemy: Node2D, points: int):
	enemy_banished.emit(enemy, points)
	if enemy.has_method("is_dummy") && enemy.is_dummy():
		game_started.emit()


func emit_victory():
	victory.emit()
