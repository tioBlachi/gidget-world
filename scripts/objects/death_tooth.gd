extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# Check if the body that entered is in the "player" group.
	if body.is_in_group("players"):
		# Emit the global signal to trigger the alligator bite.
		Global.trigger_alligator_bite()
		
		
		
