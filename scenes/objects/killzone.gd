extends Area2D
@onready var timer: Timer = $Timer

signal character_died

func _ready():
	add_to_group("killzones")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		print("You Died")
		if body.has_method("die"):
			body.die()
		emit_signal("character_died")
		# body.queue_free()
	else:
		print("Tried to kill non player body")


func _on_timer_timeout() -> void:
	print("Game Over")
	# get_tree().reload_current_scene()
