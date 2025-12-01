extends AnimatedSprite2D

func _ready():
	# Connect the 'animation_finished' signal from THIS node to the function below
	self.connect("animation_finished", Callable(self, "_on_animation_finished"))
	print("Portal animation script ready. Signal connected.")

# This function is called every time an animation finishes playing
func _on_animation_finished():
	# Check if the animation that just finished was named "Opened 1"
	if self.animation == "Opened 1":
		print("Animation 'Opened 1' finished. Switching to 'Opened 2'.")
		
		# Now play the "Opened 2" animationw
		# Make sure "Opened 2" is set to Loop in the editor
		self.play("Opened 2")

	# If it was any other animation that finished, do nothing special.
