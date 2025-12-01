extends Area2D

@onready var t: Timer = $Timer
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	anim.play("Keycard")
	t.start()
	
	t.timeout.connect(on_timer_timeout)
	
func on_timer_timeout():
	anim.play("Keycard")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		SoundManager.play_sfx("chime", -20)
		Global.emit_signal("keycard_collected")
		queue_free()
