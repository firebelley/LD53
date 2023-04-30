extends CanvasLayer


@export var game_manager: GameManager
@onready var progress_bar = %ProgressBar
@onready var level_label = %LevelLabel
@onready var heart_container = %HeartContainer

var current_tween: Tween



func _ready():
	GameEvents.player_health_changed.connect(on_player_health_changed)
	game_manager.level_progress_updated.connect(on_level_progress_updated)
	for i in range(3):
		var texture_rect = TextureRect.new()
		heart_container.add_child(texture_rect)
		texture_rect.texture = load("res://assets/ui/heart.png")
	
	

func on_level_progress_updated(current_progress: int, required_progress: int, current_level: int):
	if current_tween != null && current_tween.is_valid():
		current_tween.kill()
	
	var target_value = float(current_progress) / float(required_progress)
	
	current_tween = create_tween()
	current_tween.tween_property(progress_bar, "value", target_value, .2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	var level_to_use = 9 if current_level > 9 else current_level
	level_label.text = "Level %s" % (level_to_use + 1)


func on_player_health_changed(current: int, max: int):
	for child in heart_container.get_children():
		child.queue_free()
	for i in current:
		var texture_rect = TextureRect.new()
		heart_container.add_child(texture_rect)
		texture_rect.texture = load("res://assets/ui/heart.png")
