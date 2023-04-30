extends Node
class_name GameManager

signal level_progress_updated(current_progress: int, required_progress: int, level: int)

const MAX_TICKS = 60 * 5
const TARGET_LEVEL = 10

@onready var tick_timer: Timer = $TickTimer
@onready var spawn_timer: Timer = $SpawnTimer

var current_ticks = 0
var required_player_xp = 5
var required_xp_growth = 5
var current_player_xp = 0
var current_player_level = 0
var spawners = []

var max_enemies = 2
var current_enemies = 0
var enemies_per_15_ticks = 1

func _ready():
	GameEvents.game_started.connect(on_game_started)
	GameEvents.enemy_banished.connect(on_enemy_banished)
	tick_timer.timeout.connect(on_tick_timer_timeout)
	setup_spawners()
	spawn_timer.timeout.connect(on_spawn_timer_timeout)
	

func setup_spawners():
	spawners = get_tree().get_nodes_in_group("spawner").filter(func(x): return !x.is_in_group("spawner_secondary"))
	

func update_difficulty():
	max_enemies += 1
#	if (current_ticks % 30) == 0:
#		max_enemies += 1
	
	if current_player_level == 5:
		for spawner in get_tree().get_nodes_in_group("spawner_secondary"):
			spawners.append(spawner)
	
	

func check_level_up():
	while current_player_xp >= required_player_xp:
		current_player_level += 1
		current_player_xp -= required_player_xp
		required_player_xp += required_xp_growth
		update_difficulty()
	level_progress_updated.emit(current_player_xp, required_player_xp, current_player_level)
	

func on_enemy_banished(enemy: Node2D, points: int):
	if enemy.has_method("is_dummy") && enemy.is_dummy():
		return
	current_enemies -= 1
	current_player_xp += points
	check_level_up()
	print(current_enemies)
	if current_player_level >= TARGET_LEVEL:
		spawn_timer.stop()
		if current_enemies <= 0:
			GameEvents.emit_victory()
	

func on_game_started():
	tick_timer.start()
	spawn_timer.start()


func on_tick_timer_timeout():
	current_ticks += 1
	
	if current_ticks == MAX_TICKS:
		print("finished")
	else:
#		update_difficulty()
		tick_timer.start()	


func on_spawn_timer_timeout():
	while current_enemies < max_enemies:
		var spawner = spawners.pick_random()
		spawner.spawn()
		current_enemies += 1
