extends CanvasLayer


@export var game_manager: GameManager
@onready var progress_bar = %ProgressBar
@onready var level_label = %LevelLabel

var current_tween: Tween



func _ready():
	game_manager.level_progress_updated.connect(on_level_progress_updated)
	

func on_level_progress_updated(current_progress: int, required_progress: int, current_level: int):
	if current_tween != null && current_tween.is_valid():
		current_tween.kill()
	
	var target_value = float(current_progress) / float(required_progress)
	
	current_tween = create_tween()
	current_tween.tween_property(progress_bar, "value", target_value, .2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	level_label.text = "Level %s" % (current_level + 1)
