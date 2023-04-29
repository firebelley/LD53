extends CharacterBody2D

const MAX_SPEED = 110
const ACCEL_SMOOTH = -30.0
const GRAVITY = 600
const JUMP_FORCE = 300
const JUMP_UP_GRAVITY_MOD = .5
const JUMP_TERMINATION_MOD = 4.0

@onready var visuals: Node2D = $Visuals
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	pass


func _process(delta):
	var movement_vector = get_movement_vector()
	velocity.x = lerp(velocity.x, movement_vector.x * MAX_SPEED, 1.0 - exp(ACCEL_SMOOTH * delta))
	velocity.y += GRAVITY * delta
	
	if movement_vector.y < 0:
		velocity.y -= JUMP_FORCE
	
	if velocity.y < 0 && Input.is_action_pressed("jump"):
		var adjusted_gravity = GRAVITY * JUMP_UP_GRAVITY_MOD
		velocity.y += adjusted_gravity * delta
	elif velocity.y < 0 && !Input.is_action_pressed("jump"):
		velocity.y += GRAVITY * JUMP_TERMINATION_MOD * delta
	else:
		velocity.y += GRAVITY * delta
	
	move_and_slide()
	
	if (movement_vector.x == 0):
		animation_player.play("RESET")
	else:
		animation_player.play("run")
	
	visuals.global_position = global_position.round()
	update_facing()


func get_movement_vector():
	var x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y = -1 if Input.is_action_just_pressed("jump") && is_on_floor() else 0

	return Vector2(x, y)


func update_facing():
	if get_movement_vector().x == 0:
		return
	visuals.scale = Vector2(-1, 1) if get_movement_vector().x < 0 else Vector2.ONE
