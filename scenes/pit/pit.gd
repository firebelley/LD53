extends Node2D


@onready var resource_preloader = $ResourcePreloader
@onready var pit_explosion_scene: PackedScene = resource_preloader.get_resource("pit_explosion_particles")


func _ready():
	$Area2D.body_entered.connect(on_body_entered)


func on_body_entered(body: PhysicsBody2D):
	var particles = pit_explosion_scene.instantiate() as Node2D
	add_child(particles)
	particles.global_position = body.global_position
	GameEvents.emit_enemy_banished(body, 1)
	body.queue_free()
