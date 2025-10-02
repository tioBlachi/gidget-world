extends Area2D
@onready var timer: Timer = $Timer


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		print("You Died")
		# body.queue_free()
		timer.start()
	else:
		print("Tried to kill non player body")


func _on_timer_timeout() -> void:
	print("Game Over")
	get_tree().reload_current_scene()
