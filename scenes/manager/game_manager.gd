extends Node
class_name GameManager

signal level_progress_updated(current_progress: int, required_progress: int, level: int)

const MAX_TICKS = 60 * 5

@onready var tick_timer: Timer = $TickTimer
@onready var spawn_timer: Timer = $SpawnTimer

var current_ticks = 0
var required_player_xp = 5
var required_xp_growth = 5
var current_player_xp = 0
var current_player_level = 1
var spawners = []

var max_enemies = 3
var current_enemies = 0
var enemies_per_15_ticks = 1

func _ready():
	tick_timer.start()
	GameEvents.enemy_banished.connect(on_enemy_banished)
	tick_timer.timeout.connect(on_tick_timer_timeout)
	setup_spawners()
	spawn_timer.timeout.connect(on_spawn_timer_timeout)
	

func setup_spawners():
	spawners = get_tree().get_nodes_in_group("spawner")
	

func update_difficulty():
	if (current_ticks % 15) == 0:
		max_enemies += 1
	
	if current_ticks == 30:
		print("difficulty increase")
	

func check_level_up():
	while current_player_xp >= required_player_xp:
		current_player_level += 1
		current_player_xp -= required_player_xp
		required_player_xp += required_xp_growth
	level_progress_updated.emit(current_player_xp, required_player_xp, current_player_level)
	

func on_enemy_banished(enemy: Node2D, points: int):
	current_enemies -= 1
	current_player_xp += points
	check_level_up()
	

func on_tick_timer_timeout():
	current_ticks += 1
	
	if current_ticks == MAX_TICKS:
		print("finished")
	else:
		update_difficulty()
		tick_timer.start()	


func on_spawn_timer_timeout():
	while current_enemies < max_enemies:
		var spawner = spawners.pick_random()
		spawner.spawn()
		current_enemies += 1
