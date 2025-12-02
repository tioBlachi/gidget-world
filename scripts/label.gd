# Collin Whitney

extends Label

@export var delay := 2.0          # Seconds before fading starts
@export var fade_time := 1.0      # Fade-out duration

func _ready():
	fade_out_after_delay()

func fade_out_after_delay() -> void:
	await get_tree().create_timer(delay).timeout
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
