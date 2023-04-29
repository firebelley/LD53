extends CharacterBody2D

@onready var uppercut_area: Area2D = $UpperCutArea
@onready var punch_area: Area2D = $PunchArea

enum State {
	Normal,
	Airborne
}

var state: Callable = Callable(state_normal)

func _ready():
	uppercut_area.area_entered.connect(on_uppercut_area_entered)
	punch_area.area_entered.connect(on_punch_area_entered)


func _process(_delta):
	state.call()


func state_normal():
	var delta = get_process_delta_time()
	velocity.y += 400 * delta
	velocity.x = lerp(velocity.x, 0.0, 1.0 - exp(-20 * delta))
	move_and_slide()
	
	if !is_on_floor():
		change_state(state_airborne)
	

func state_airborne():
	var delta = get_process_delta_time()	
	velocity.y += 400 * delta
	move_and_slide()
	
	if is_on_floor():
		change_state(state_normal)


func change_state(new_state: Callable, enter_state: Callable = Callable()):
	var state_change = func():
		if !enter_state.is_null():
			enter_state.call()
		state = new_state
	state_change.call_deferred()


func on_uppercut_area_entered(_other_area: Area2D):
	velocity.y = -200


func on_punch_area_entered(other_area: Area2D):
	var rotation = other_area.rotation
	var direction = Vector2.RIGHT.rotated(rotation)
	
	velocity = direction * 300
