# Attached to the Area2D that triggers the movement
extends Area2D

@export var path_follow: PathFollow2D # Reference to PathFollow2D
@export var speed: float = 5.0 # Speed at which the node moves along the path

var is_moving: bool = false  # A flag to track if the platform should move

# Called when the player enters the Area2D
func _on_Area2D_body_entered(body):
	if body.is_in_group("player"): # Assuming your player is in the "player" group
		start_moving()

func start_moving():
	# Start the movement by enabling PathFollow2D movement
	if path_follow:
		path_follow.offset = 0.0  # Start at the beginning of the path
		is_moving = true  # Set the moving flag to true

# Called every frame
func _process(delta):
	if is_moving and path_follow:
		move_along_path(delta)

func move_along_path(delta):
	# Increment the offset of PathFollow2D based on speed and delta time
	var offset = path_follow.offset
	offset += speed * delta  # Move along the path based on speed and delta time
	path_follow.offset = offset % 1.0  # Ensure it loops around the path if needed
