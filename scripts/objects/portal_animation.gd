extends AnimatedSprite2D

func _ready():
	# Start the non-looping animation
	play("default")

func _on_AnimatedSprite2D_animation_finished():
		# Check if the "intro" animation just finished
	if animation == "Opened 1":
			# Play the looping "idle" animation
		play("Opened 2")
