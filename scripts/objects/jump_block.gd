extends Node2D

@onready var t: Timer = $Timer
@onready var anim: AnimationPlayer = $AnimationPlayer

@export var jump_height : int = 700

func _ready() -> void:
	anim.play("idle")
	t.start()
	t.timeout.connect(on_t_timeout)
	
func on_t_timeout():
	anim.play("idle")

func _on_bounce_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		if anim.is_playing():
			anim.stop()
		body.velocity.y -= jump_height
		anim.play("launch")
		SoundManager.play_sfx("boing", -20)
