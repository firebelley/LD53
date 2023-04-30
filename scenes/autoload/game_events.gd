extends Node


signal enemy_banished(enemy: Node2D, points: int)


func emit_enemy_banished(enemy: Node2D, points: int):
	enemy_banished.emit(enemy, points)
