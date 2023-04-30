extends Node2D


func _ready():
	$Area2D.body_entered.connect(on_body_entered)


func on_body_entered(body: PhysicsBody2D):
	GameEvents.emit_enemy_banished(body, 1)
	body.queue_free()
