# Collin Whitney

extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		print("You Collected the Key!")
		print("Congrats")
		# The mower node this key belongs to
		var mower = get_parent()
		mower.stopping = true
