extends Node2D

func _ready() -> void:
	$Face.play("blink")
	$Flames.play("burn")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		# Make the player randomly move left and right for 3 seconds
		var timer := Timer.new()
		timer.wait_time = 3.0
		timer.one_shot = true
		add_child(timer)
		timer.start()

		var random_direction = 1.0 if randf() > 0.5 else -1.0
		body.velocity.x = 200 * random_direction  # Adjust speed as needed

		timer.timeout.connect(func():
			body.velocity.x = 0  # Stop the player after 3 seconds
		)

		# Remove the flame dude
		queue_free()
