extends Node2D


var exp = 0


func _ready():
	$Area2D.body_entered.connect(on_body_entered)


func on_body_entered(body: PhysicsBody2D):
	body.queue_free()
	exp += 1
	print(exp)
