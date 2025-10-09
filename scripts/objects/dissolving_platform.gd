extends Node2D

@onready var solid_body = $StaticBody2D
@onready var detection_area = $Area2D
@onready var timer = $Timer

# Load the enemy scene. Change this path to your enemy's scene file.
var enemy_scene = preload("res://scenes/objects/heat_seek_enemy.tscn")

# Check if the platform has already been triggered to avoid restarting the timer
var is_triggered = false

# Signal handler for the Area2D's body_entered signal
func _on_area_2d_body_entered(body):
	# Make sure the platform hasn't been triggered yet and that the body is the player
	if not is_triggered and body.is_in_group("players"):
		is_triggered = true
		timer.start() # Start the 3-second timer
		
		# Spawn a new enemy
		spawn_enemy(body.global_position)
		
		# Optional: You can add a visual cue here, like flashing the platform
		
# Signal handler for the Timer's timeout signal
func _on_timer_timeout():
	# Disable the StaticBody2D's collision to make the player fall through
	solid_body.queue_free()
	# Optional: Queue the whole platform for deletion after the timer expires
	queue_free()

# Function to spawn a new enemy instance
func spawn_enemy(spawn_position):
	if enemy_scene:
		# Create a new instance of the enemy scene
		var new_enemy = enemy_scene.instantiate()
		
		# Set the new enemy's position to a location near the player
		# Add or subtract from spawn_position to avoid spawning directly on the player
		new_enemy.global_position = spawn_position + Vector2(100, -100)
		
		# Add the new enemy to the scene tree
		# get_tree().root gets the top-level node
		get_tree().root.add_child(new_enemy)
