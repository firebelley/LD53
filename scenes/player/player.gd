extends CharacterBody2D

const MAX_SPEED = 110
const ACCEL_SMOOTH = -30.0
const GRAVITY = 1200
const JUMP_FORCE = 300
const JUMP_UP_GRAVITY_MOD = .5
const JUMP_TERMINATION_MOD = 4.0

@onready var visuals: Node2D = $Visuals
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var uppercut_shape: CollisionShape2D = $UpperCutArea/CollisionShape2D
@onready var punch_shape: CollisionShape2D = $PunchArea/CollisionShape2D
@onready var punch_area: Area2D = $PunchArea


enum State {
	Normal,
	Airborne
}

var state: Callable = Callable(state_normal)

func _ready():
	uppercut_shape.disabled = true
	punch_shape.disabled = true


func _process(_delta):
	state.call()


func state_normal():
	var delta = get_process_delta_time()
	var movement_vector = get_movement_vector()
	velocity.x = lerp(velocity.x, movement_vector.x * MAX_SPEED, 1.0 - exp(ACCEL_SMOOTH * delta))
	
	if movement_vector.y < 0:
		velocity.y -= JUMP_FORCE
		activate_uppercut()
	
	move_and_slide()
	
	if (movement_vector.x == 0):
		animation_player.play("RESET")
	else:
		animation_player.play("run")
	
	visuals.global_position = global_position.round()
	update_facing()
	
	if (!is_on_floor()):
		change_state(state_airborne)
	

func state_airborne():
	var delta = get_process_delta_time()
	var movement_vector = get_movement_vector()
	
	velocity.x = lerp(velocity.x, movement_vector.x * MAX_SPEED, 1.0 - exp(ACCEL_SMOOTH * delta))
	
	if velocity.y < 0 && Input.is_action_pressed("jump"):
		var adjusted_gravity = GRAVITY * JUMP_UP_GRAVITY_MOD
		velocity.y += adjusted_gravity * delta
	elif velocity.y < 0 && !Input.is_action_pressed("jump"):
		velocity.y += GRAVITY * JUMP_TERMINATION_MOD * delta
	else:
		velocity.y += GRAVITY * delta

	move_and_slide()
	
	update_facing()

	if Input.is_action_just_pressed("punch"):
		punch_shape.disabled = false
		punch_area.rotation = (get_global_mouse_position() - punch_area.global_position).angle()
		var timer = get_tree().create_timer(.1)
		timer.timeout.connect(on_punch_timer_timeout)

	if is_on_floor():
		change_state(state_normal)

		
func change_state(new_state: Callable, enter_state: Callable = Callable()):
	var state_change = func():
		if !enter_state.is_null():
			enter_state.call()
		state = new_state
	state_change.call_deferred()


func get_movement_vector():
	var x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y = -1 if Input.is_action_just_pressed("jump") && is_on_floor() else 0

	return Vector2(x, y)


func update_facing():
	if get_movement_vector().x == 0:
		return
	visuals.scale = Vector2(-1, 1) if get_movement_vector().x < 0 else Vector2.ONE


func activate_uppercut():
	uppercut_shape.disabled = false
	await get_tree().create_timer(.1).timeout
	uppercut_shape.disabled = true
	

func on_punch_timer_timeout():
	punch_shape.disabled = true
