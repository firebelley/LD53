extends CharacterBody2D

const GRAVITY = 500
const WALK_SPEED = 50

@onready var uppercut_area: Area2D = $UpperCutArea
@onready var punch_area: Area2D = $PunchArea
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var resource_preloader: ResourcePreloader = $ResourcePreloader
@onready var center_marker = %CenterMarker
@onready var raycasts = $Raycasts
@onready var state_timer = $StateTimer
@onready var projectile_timer = $ProjectileTimer
@onready var projectile_marker = $ProjectileMarker
@onready var knockout_hitbox_shape = $KnockoutHitboxArea/CollisionShape2D
@onready var knockout_hurtbox_area = $KnockoutHurtboxArea
@onready var projectile_scene = resource_preloader.get_resource("projectile") as PackedScene

var state_machine: CallableStateMachine = CallableStateMachine.new()


func _ready():
	state_machine.add_states(state_normal)
	state_machine.add_states(state_airborne)
	state_machine.add_states(state_punched, enter_state_punched, leave_state_punched)
	state_machine.add_states(state_knockout, enter_state_knockout, leave_state_knockout)
	state_machine.set_initial_state(state_normal)
	
	knockout_hitbox_shape.disabled = true
	
	uppercut_area.area_entered.connect(on_uppercut_area_entered)
	punch_area.area_entered.connect(on_punch_area_entered)
	knockout_hurtbox_area.area_entered.connect(on_knockout_hurtbox_area_entered)


func _process(_delta):
	state_machine.update()


func state_normal():
	var delta = get_process_delta_time()
	var player = get_tree().get_first_node_in_group("player")
	
	var x_direction = 0.0
	if player != null:
		x_direction = -1.0 if global_position.x > player.global_position.x else 1.0
	
	velocity.x = lerp(velocity.x, x_direction * WALK_SPEED, 1.0 - exp(-20 * delta))
	move_and_slide()
	
	if is_on_floor() && is_over_edge():
		velocity.y -= 200
		velocity.x *= 3.0
	
	if !is_on_floor():
		state_machine.change_state(state_airborne)
		
	if projectile_timer.is_stopped():
		projectile_timer.start()
		try_spawn_projectile()


func enter_state_punched():
	knockout_hitbox_shape.disabled = false


func state_punched():
	var delta = get_process_delta_time()	
	velocity.y += GRAVITY * delta
	move_and_slide()
		
	visuals.rotation = lerp_angle(visuals.rotation, velocity.angle() + deg_to_rad(90), 1 - exp(-10 * delta))
	
	if is_on_floor():
		state_machine.change_state(state_knockout)


func leave_state_punched():
	knockout_hitbox_shape.disabled = true
	visuals.rotation = 0


func state_airborne():
	var delta = get_process_delta_time()	
	velocity.y += GRAVITY * delta
	move_and_slide()
	
	if is_on_floor():
		state_machine.change_state(state_normal)


func enter_state_knockout():
	sprite.rotation = rad_to_deg(90)
	state_timer.wait_time = 5
	state_timer.start()


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
	sprite.rotation = 0
	

func is_over_edge():
	for raycast in raycasts.get_children():
		var r = raycast as RayCast2D
		r.force_raycast_update()
		if !r.is_colliding():
			return true
	return false


func try_spawn_projectile():
	if randf() > .25:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	var direction = Vector2.RIGHT
	if player != null:
		direction = Vector2.RIGHT if player.global_position.x > global_position.x else Vector2.LEFT
	
	var projectile = projectile_scene.instantiate() as Node2D
	add_sibling(projectile)
	projectile.global_position = projectile_marker.global_position
	projectile.start(direction)


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
	if body == null || body == self || state_machine.current_state_equals(state_punched):
		return
	
	velocity = body.velocity
	state_machine.change_state(state_punched)
	
	var particles = resource_preloader.get_resource("punch_particles").instantiate() as Node2D
	add_sibling(particles)
	particles.global_position = center_marker.global_position
	particles.rotation = velocity.angle()
	HitstopManager.shake_camera()
