class_name CallableStateMachine

var states = {}


var current_state: Callable

func add_states(normal: Callable, enter: Callable = Callable(), leave: Callable = Callable()):
	var normal_name = normal.get_method()
	states[normal_name] = {}
	states[normal_name]["normal"] = normal
	if !enter.is_null():
		states[normal_name]["enter"] = enter
	if !leave.is_null():
		states[normal_name]["leave"] = leave


func set_initial_state(state: Callable):
	change_state(state, true)


func update():
	if !current_state.is_null():
		current_state.call()


func change_state(to_state: Callable, immediate: bool = false):
	var change = func():
		var to_state_name = to_state.get_method()
		var current_state_name = current_state.get_method() if !current_state.is_null() else null
		if states.has(to_state_name):
			if current_state_name != null && states[current_state_name].has("leave"):
				states[current_state_name].leave.call()
			if states[to_state_name].has("enter"):
				states[to_state_name].enter.call()
			
		current_state = to_state
	
	if !immediate:
		change.call_deferred()
	else:
		change.call()
