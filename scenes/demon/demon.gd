extends CharacterBody2D

const GRAVITY = 400

@onready var uppercut_area: Area2D = $UpperCutArea
@onready var punch_area: Area2D = $PunchArea
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var resource_preloader: ResourcePreloader = $ResourcePreloader
@onready var center_marker = %CenterMarker

var state: Callable = Callable(state_normal)

func _ready():
	uppercut_area.area_entered.connect(on_uppercut_area_entered)
	punch_area.area_entered.connect(on_punch_area_entered)

func _process(_delta):
	state.call()


func state_normal():
	var delta = get_process_delta_time()
	velocity.x = lerp(velocity.x, 0.0, 1.0 - exp(-20 * delta))
	move_and_slide()
	
	if !is_on_floor():
		change_state(state_airborne)
	

func state_punched():
	var delta = get_process_delta_time()	
	velocity.y += GRAVITY * delta
	move_and_slide()
		
	visuals.rotation = lerp_angle(visuals.rotation, velocity.angle() + deg_to_rad(90), 1 - exp(-10 * delta))
	
	if is_on_floor():
		change_state(state_knockout, leave_state_airborne)


func state_airborne():
	var delta = get_process_delta_time()	
	velocity.y += GRAVITY * delta
	move_and_slide()
	
	if is_on_floor():
		change_state(state_normal)


func leave_state_airborne():
	visuals.rotation = 0


func state_knockout():
	sprite.rotation = rad_to_deg(90)
	var delta = get_process_delta_time()
	velocity.x = lerp(velocity.x, 0.0, 1.0 - exp(-20 * delta))
	move_and_slide()
	
	if !is_on_floor():
		change_state(state_airborne)


func change_state(new_state: Callable, enter_state: Callable = Callable()):
	var state_change = func():
		if !enter_state.is_null():
			enter_state.call()
		state = new_state
	state_change.call_deferred()


func on_uppercut_area_entered(_other_area: Area2D):
	velocity.y = -200
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
	change_state(state_punched)
	HitstopManager.hitstop()
	HitstopManager.shake_camera()
	
	var particles = resource_preloader.get_resource("punch_particles").instantiate() as Node2D
	add_sibling(particles)
	particles.global_position = center_marker.global_position
	particles.rotation = direction.angle()
	
