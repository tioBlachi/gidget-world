extends CanvasLayer

@onready var label: Label = $ColorRect/Label
@onready var music: AudioStreamPlayer2D = $FinMusic

func _ready() -> void:
	label.self_modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(label, "self_modulate:a", 1.0, 5.0)
	music.play()
	await music.finished
	SceneManager.switch_scene("Title")
	SceneManager.current_level_idx = 0
