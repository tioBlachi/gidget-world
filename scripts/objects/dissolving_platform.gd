extends Node2D

@onready var solid_body = $StaticBody2D
@onready var detection_area = $Area2D
@onready var timer = $Timer

# Check if the platform has already been triggered to avoid restarting the timer
var is_triggered = false

# Signal handler for the Area2D's body_entered signal
func _on_area_2d_body_entered(body):
	# Make sure the platform hasn't been triggered yet and that the body is the player
	#ddddddddprint("Collision Occured")
	#print("is_triggered ", is_triggered)
	#print("body.is in group ", body.is_in_group("players"))
	if not is_triggered:
		is_triggered = true
		timer.start() # Start the 3-second timer
		print("Timer Started")
		# Optional: You can add a visual cue here, like flashing the platform
		
# Signal handler for the Timer's timeout signal
func _on_timer_timeout():
	# Disable the StaticBody2D's collision to make the player fall through
	solid_body.queue_free()
	# Optional: Queue the whole platform for deletion after the timer expires
	queue_free()
