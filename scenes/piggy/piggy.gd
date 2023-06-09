extends CharacterBody2D

const GRAVITY = 500
const WALK_SPEED = 50

@onready var uppercut_area: Area2D = $UpperCutArea
@onready var punch_area: Area2D = $PunchArea
@onready var visuals: Node2D = $Visuals
@onready var resource_preloader: ResourcePreloader = $ResourcePreloader
@onready var center_marker = %CenterMarker
@onready var raycasts = $Raycasts
@onready var state_timer = $StateTimer
@onready var knockout_hitbox_shape = $KnockoutHitboxArea/CollisionShape2D
@onready var knockout_hurtbox_area = $KnockoutHurtboxArea
@onready var animation_player = $AnimationPlayer
@onready var attack_root = $AttackRoot
@onready var attack_scene = resource_preloader.get_resource("piggy_attack") as PackedScene


var state_machine: CallableStateMachine = CallableStateMachine.new()
var adjusted_walk_speed = WALK_SPEED * randf_range(.9, 1.1)
var attack_instance: Node2D = null
var attack_direction: Vector2


func _ready():
	animation_player.speed_scale = randf_range(.9, 1.1)
	state_machine.add_states(state_normal, enter_state_normal)
	state_machine.add_states(state_airborne, enter_state_airborne)
	state_machine.add_states(state_punched, enter_state_punched, leave_state_punched)
	state_machine.add_states(state_knockout, enter_state_knockout, leave_state_knockout)
	state_machine.add_states(state_attack, enter_state_attack, leave_state_attack)
	state_machine.set_initial_state(state_normal)
	
	knockout_hitbox_shape.disabled = true
	
	uppercut_area.area_entered.connect(on_uppercut_area_entered)
	punch_area.area_entered.connect(on_punch_area_entered)
	knockout_hurtbox_area.area_entered.connect(on_knockout_hurtbox_area_entered)


func _process(_delta):
	state_machine.update()


func enter_state_normal():
	animation_player.play("RESET")
	animation_player.queue("run")
	state_timer.wait_time = randf_range(2, 3)
	state_timer.start()


func state_normal():
	var delta = get_process_delta_time()
	var player = get_tree().get_first_node_in_group("player")
	
	var target_position = Vector2(global_position.x, 64)
	if player != null:
		target_position.x = player.global_position.x

	
	var target_direction = (target_position - global_position).normalized()
	velocity = velocity.lerp(target_direction * adjusted_walk_speed, 1.0 - exp(-5 * delta))
	
	move_and_slide()

	update_facing()
	
	if state_timer.is_stopped():
		state_machine.change_state(state_attack)


func enter_state_punched():
	animation_player.play("airborne")
	knockout_hitbox_shape.disabled = false


func state_punched():
	var delta = get_process_delta_time()	
	velocity.y += GRAVITY * delta
	move_and_slide()
		
	visuals.rotation = lerp_angle(visuals.rotation, velocity.angle() + deg_to_rad(90), 1 - exp(-10 * delta))
	
	if is_on_floor():
		state_machine.change_state(state_knockout)
	
	update_facing()


func leave_state_punched():
	knockout_hitbox_shape.disabled = true
	visuals.rotation = 0


func enter_state_airborne():
	animation_player.play("airborne")


func state_airborne():
	var delta = get_process_delta_time()	
	velocity.y += GRAVITY * delta
	move_and_slide()
	
	if is_on_floor():
		state_machine.change_state(state_normal)
	
	update_facing()


func enter_state_knockout():
	animation_player.play("knockout")
	visuals.rotation = deg_to_rad(-90)
	visuals.position = Vector2.UP * 4
	state_timer.wait_time = 5
	state_timer.start()
	visuals.scale = visuals.scale * Vector2(-1, 1)


func state_knockout():
	var delta = get_process_delta_time()
	velocity.x = lerp(velocity.x, 0.0, 1.0 - exp(-3.0 * delta))
	velocity.y += GRAVITY * delta
	move_and_slide()
	
	if !is_on_floor():
		state_machine.change_state(state_punched)
	if state_timer.is_stopped():
		state_machine.change_state(state_normal)
	
	
func leave_state_knockout():
	visuals.rotation = 0
	visuals.position = Vector2.ZERO
	
	
func enter_state_attack():
	attack_instance = attack_scene.instantiate() as Node2D
	$AttackRoot.add_child(attack_instance)
	
	attack_direction = Vector2.RIGHT
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		attack_direction = Vector2.LEFT if player.global_position.x < global_position.x else Vector2.RIGHT
	

func state_attack():
	velocity = velocity.lerp(attack_direction * adjusted_walk_speed * 1.5, 1.0 - exp(-20 * get_process_delta_time()))
	move_and_slide()
	if !is_instance_valid(attack_instance):
		state_machine.change_state(state_normal)
	
	
func leave_state_attack():
	if is_instance_valid(attack_instance):
		attack_instance.kill()


func is_over_edge():
	for raycast in raycasts.get_children():
		var r = raycast as RayCast2D
		r.force_raycast_update()
		if !r.is_colliding():
			return true
	return false


func update_facing():
	visuals.scale = Vector2(-1, 1) if velocity.x < 0 else Vector2.ONE


func on_uppercut_area_entered(_other_area: Area2D):
	velocity.y = randf_range(-350, -300)
	HitstopManager.hitstop()
	HitstopManager.shake_camera()
	var particles = resource_preloader.get_resource("punch_particles").instantiate() as Node2D
	add_sibling(particles)
	particles.global_position = center_marker.global_position
	particles.rotation = deg_to_rad(-90)


func on_punch_area_entered(other_area: Area2D):
	var rotation = other_area.rotation
	var direction = Vector2.RIGHT.rotated(rotation)
	
	velocity = direction * 300
	state_machine.change_state(state_punched)
	HitstopManager.hitstop()
	HitstopManager.shake_camera()
	
	var particles = resource_preloader.get_resource("punch_particles").instantiate() as Node2D
	add_sibling(particles)
	particles.global_position = center_marker.global_position
	particles.rotation = direction.angle()


func on_knockout_hurtbox_area_entered(other_area: Area2D):
	var body = other_area.owner as CharacterBody2D
	if body == null || body == self || state_machine.current_state_equals(state_punched) || state_machine.current_state_equals(state_knockout):
		return
	
	velocity = body.velocity
	state_machine.change_state(state_punched)
	
	var particles = resource_preloader.get_resource("punch_particles").instantiate() as Node2D
	add_sibling(particles)
	particles.global_position = center_marker.global_position
	particles.rotation = velocity.angle()
	HitstopManager.shake_camera()
