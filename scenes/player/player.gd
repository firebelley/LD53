extends CharacterBody2D

const MAX_SPEED = 120
const ACCEL_SMOOTH = -30.0
const GRAVITY = 1200
const JUMP_FORCE = 300
const UPPERCUT_FORCE = 400
const JUMP_UP_GRAVITY_MOD = .5
const JUMP_TERMINATION_MOD = 4.0

@onready var visuals: Node2D = $Visuals
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var uppercut_shape: CollisionShape2D = $UpperCutArea/CollisionShape2D
@onready var punch_shape: CollisionShape2D = $PunchArea/CollisionShape2D
@onready var punch_area: Area2D = $PunchArea
@onready var pickup_area: Area2D = $PickupArea
@onready var resource_preloader = $ResourcePreloader
@onready var fist_scene = resource_preloader.get_resource("fist") as PackedScene

var held_enemy: Node2D

var state_machine = CallableStateMachine.new()
var did_uppercut = false
var fist_instance: Node2D = null

func _ready():
	state_machine.add_states(state_normal)
	state_machine.add_states(state_airborne, Callable(), leave_state_airborne)
	state_machine.set_initial_state(state_normal)
	
	uppercut_shape.disabled = true
	punch_shape.disabled = true


func _process(_delta):
	state_machine.update()


func state_normal():
	var delta = get_process_delta_time()
	var movement_vector = get_movement_vector()
	velocity.x = lerp(velocity.x, movement_vector.x * MAX_SPEED, 1.0 - exp(ACCEL_SMOOTH * delta))
	did_uppercut = Input.is_action_just_pressed("punch_alternate")
	
	if movement_vector.y < 0 || did_uppercut:
		if did_uppercut:
			velocity.y -= UPPERCUT_FORCE
			activate_uppercut()
		else:
			velocity.y -= JUMP_FORCE
	
	move_and_slide()
	
	if (movement_vector.x == 0):
		animation_player.play("RESET")
	else:
		animation_player.play("run")
	
	visuals.global_position = global_position.round()
	update_facing()

	if (!is_on_floor()):
		state_machine.change_state(state_airborne)


func state_airborne():
	var delta = get_process_delta_time()
	var movement_vector = get_movement_vector()
	
	velocity.x = lerp(velocity.x, movement_vector.x * MAX_SPEED, 1.0 - exp(ACCEL_SMOOTH * delta))
	
	var is_jump_held = Input.is_action_pressed("jump") || did_uppercut
	
	if velocity.y < 0 && is_jump_held:
		var adjusted_gravity = GRAVITY * JUMP_UP_GRAVITY_MOD
		velocity.y += adjusted_gravity * delta
	elif velocity.y < 0 && !is_jump_held:
		velocity.y += GRAVITY * JUMP_TERMINATION_MOD * delta
	else:
		velocity.y += GRAVITY * delta

	move_and_slide()
	
	update_facing()
	
	var mouse_direction = (get_global_mouse_position() - punch_area.global_position).normalized()
	if is_instance_valid(fist_instance):
		fist_instance.set_direction(mouse_direction)

	if Input.is_action_just_pressed("punch"):
		Engine.time_scale = .25
		fist_instance = fist_scene.instantiate()
		add_child(fist_instance)
		fist_instance.global_position = punch_area.global_position
		fist_instance.set_initial_direction(mouse_direction)
	if Input.is_action_just_released("punch"):
		velocity.y = 0
		Engine.time_scale = 1.0
		punch_shape.disabled = false
		punch_area.rotation = mouse_direction.angle()
		var timer = get_tree().create_timer(.1)
		timer.timeout.connect(on_punch_timer_timeout)
		if is_instance_valid(fist_instance):
			fist_instance.punch()

	if is_on_floor():
		state_machine.change_state(state_normal)


func leave_state_airborne():
	did_uppercut = false
	Engine.time_scale = 1.0
	if is_instance_valid(fist_instance):
		fist_instance.cleanup()


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
