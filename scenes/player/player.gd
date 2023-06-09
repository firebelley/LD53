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
@onready var hurtbox_area = $HurtboxArea
@onready var pit_area = $PitArea
@onready var jump_stream_player = $JumpStreamPlayer
@onready var wings = %Wings
@onready var coyote_timer = $CoyoteTimer

var held_enemy: Node2D
var current_hp = 3

var state_machine = CallableStateMachine.new()
var did_uppercut = false
var fist_instance: Node2D = null

func _ready():
	state_machine.add_states(state_normal)
	state_machine.add_states(state_airborne, enter_state_airborne, leave_state_airborne)
	state_machine.add_states(state_knockback, enter_state_knockback)
	state_machine.add_states(state_resurrect, enter_state_resurrect, leave_state_resurrect)
	state_machine.set_initial_state(state_normal)
	
	uppercut_shape.disabled = true
	punch_shape.disabled = true
	hurtbox_area.area_entered.connect(on_hurtbox_area_entered)
	pit_area.area_entered.connect(on_pit_area_entered)


func _process(_delta):
	state_machine.update()


func state_normal():
	var delta = get_process_delta_time()
	var movement_vector = get_movement_vector()
	velocity.x = lerp(velocity.x, movement_vector.x * MAX_SPEED, 1.0 - exp(ACCEL_SMOOTH * delta))
	did_uppercut = Input.is_action_just_pressed("punch_alternate")
	var did_jump = false
	
	if movement_vector.y < 0 || did_uppercut:
		if did_uppercut:
			velocity.y -= UPPERCUT_FORCE
			activate_uppercut()
		else:
			velocity.y -= JUMP_FORCE
		jump_stream_player.play_random()
		did_jump = true
	
	move_and_slide()
	
	if (movement_vector.x == 0):
		animation_player.play("RESET")
	else:
		animation_player.play("run")
	
	visuals.global_position = global_position.round()
	update_facing()

	if (!is_on_floor()):
		state_machine.change_state(state_airborne)
		if !did_jump:
			coyote_timer.start()
		


func enter_state_airborne():
	animation_player.play("jump")


func state_airborne():
	var delta = get_process_delta_time()
	var movement_vector = get_movement_vector()
	
	velocity.x = lerp(velocity.x, movement_vector.x * MAX_SPEED, 1.0 - exp(ACCEL_SMOOTH * delta))
	
	var is_jump_held = Input.is_action_pressed("jump") || did_uppercut
	
	if Input.is_action_just_pressed("jump") && !coyote_timer.is_stopped():
		velocity.y = -JUMP_FORCE
		jump_stream_player.play_random()
		coyote_timer.stop()
	elif velocity.y < 0 && is_jump_held:
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

	if Input.is_action_pressed("punch"):
		Engine.time_scale = .25
		if !is_instance_valid(fist_instance):
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
		fist_instance = null

	if is_on_floor():
		state_machine.change_state(state_normal)


func leave_state_airborne():
	did_uppercut = false
	Engine.time_scale = 1.0
	if is_instance_valid(fist_instance):
		fist_instance.cleanup()


func enter_state_knockback():
	animation_player.play("jump")


func state_knockback():
	velocity.y += GRAVITY * get_process_delta_time()
	move_and_slide()
	
	if is_on_floor():
		state_machine.change_state(state_normal)


func enter_state_resurrect():
	did_uppercut = false
	velocity = Vector2.ZERO
	current_hp -= 1
	GameEvents.emit_player_health_change(current_hp, 3)
	
	if current_hp > 0:
		var apex_marker = get_tree().get_first_node_in_group("resurrect_marker_apex")
		var drop_marker = get_tree().get_nodes_in_group("resurrect_marker").pick_random()
		var tween = create_tween()
		tween.tween_property(wings, "scale", Vector2.ZERO, 0.0)
		tween.tween_property(wings, "visible", true, 0.0)
		tween.tween_property(wings, "scale", Vector2.ONE, .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "global_position", apex_marker.global_position, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "global_position", drop_marker.global_position, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func(): state_machine.change_state(state_normal))
		tween.tween_property(wings, "scale", Vector2.ZERO, .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(wings, "visible", false, 0.0)
	elif current_hp == 0:
		GameEvents.emit_game_over()
		queue_free()
	

func state_resurrect():
	velocity = Vector2.ZERO
	move_and_slide()


func leave_state_resurrect():
	velocity = Vector2.ZERO
	move_and_slide()


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
	var uppercut_fist = fist_scene.instantiate()
	add_child(uppercut_fist)
	uppercut_fist.global_position = punch_area.global_position
	uppercut_fist.set_initial_direction(Vector2.UP)
	uppercut_fist.punch()
	

func on_punch_timer_timeout():
	punch_shape.disabled = true


func on_hurtbox_area_entered(other_area: Area2D):
	var middle = get_tree().get_first_node_in_group("resurrect_marker_apex") as Node2D
	
	if other_area is KnockbackAreaComponent:
		var area = other_area as KnockbackAreaComponent
		
		var xsign = sign(middle.global_position.x - global_position.x)
		var direction = Vector2.UP.rotated(deg_to_rad(25 * xsign))
		velocity = direction * area.knockback_force
		state_machine.change_state(state_knockback)
		if area.owner.has_method("kill"):
			area.owner.kill()
		HitstopManager.shake_camera()


func on_pit_area_entered(_other_area: Area2D):
	state_machine.change_state(state_resurrect)
	$HurtStreamPlayer.play_random()
