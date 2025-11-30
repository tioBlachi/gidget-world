extends StaticBody2D

# Speed of the platform movement
@export var move_speed: float = 0.5
# Max height the platform can reach (the Y position where it stops going up)
@export var max_height: float = 0
# Starting position of the platform
var start_position: Vector2
# Is the player currently standing on the platform
var is_player_on_platform: bool = false
# Did the player previously stand on the platform?
var player_was_on_platform: bool = false
# Should the platform start falling?
var start_to_fall: bool = false

@export var move_x: bool = false

@export var little_fall: bool = false

# Falling speed
@export var fall_speed: float = 200  # Speed at which the platform will fall once it starts
@export var gravity: float = 400  # Acceleration due to gravity (pixels per second^2)
@export var max_fall_speed: float = 1000  # Maximum fall speed (terminal velocity)

# for horizontal movement (optional)
@export var hor_move_speed: float = 200
@export var hor_distance: float = 20
@export var max_hor_move_speed: float = 200
@export var min_hor_move_speed: float = 0
var asdf: float = 0
# Platform velocity (how fast it falls)
var fall_velocity: float = 0  # Initial fall speed is 0


# Called when the node enters the scene tree for the first time
func _ready():
	start_position = position  # Save the starting position

	# Get the Area2D node (direct child of StaticBody2D)
	var area = $Area2D
	# Correct way to connect signals in Godot 4.x
	area.body_entered.connect(_on_Player_entered_area)
	area.body_exited.connect(_on_Player_exited_area)

# Detect when the player enters the Area2D
func _on_Player_entered_area(body: Node) -> void:
	if body.is_in_group("players"):  # Check if the body is the player
		print("Player is on the platform")
		is_player_on_platform = true
		player_was_on_platform = true
	if little_fall:
		max_height = position.y - 22

# Detect when the player exits the Area2D
func _on_Player_exited_area(body: Node) -> void:
	if body.is_in_group("players"):  # Check if the body is the player
		print("Player left the platform")
		is_player_on_platform = false

# Platform movement logic
func _process(delta):
	if start_to_fall and player_was_on_platform:
		fall_velocity += gravity * delta  # Increase fall velocity over time
		if fall_velocity > max_fall_speed:
			fall_velocity = max_fall_speed
		position.y += fall_velocity * delta  # Make it fall faster over time
		print("Platform Y position (falling): " + str(position.y))

	elif player_was_on_platform and position.y > (max_height + 18):
		# Move the platform upwards to the max height
		position.y = lerp(position.y, max_height, 0.01)
		print("Platform Y position: " + str(position.y))
	
	elif position.y <= max_height + 18:
		# Once the platform reaches its top, start the falling process
		start_to_fall = true
	
	if player_was_on_platform and move_x:
		position.x = lerp(position.x, hor_distance, 0.01)
