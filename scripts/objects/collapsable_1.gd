# Collin Whitney

extends Node2D

@export var rumble_duration: float = 0.75    # Time for rumbling effect before collapse
@export var fall_duration: float = 5.0      # Time for the building to fall
@export var lean_angle: float = 0.5        # How much the building leans before falling
@export var fall_speed: float = 20.0        # Speed of the falling

@onready var collision_area: Area2D = $Area2D   # Reference to the Area2D for player detection

var is_collapsing: bool = false
var rumble_timer: float = 0.0
var fall_timer: float = 0.0
var target_angle: float = 5.0
var original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	original_position = position  # Save the initial position of the building

	# Connect the collision area to a function that will start the collapse
	collision_area.body_entered.connect(_on_player_entered)

func _on_player_entered(body: Node) -> void:
	if body.is_in_group("players") and not is_collapsing:
		start_collapse()

# This function starts the collapse process
func start_collapse() -> void:
	is_collapsing = true
	rumble_timer = rumble_duration
	fall_timer = 0.0
	target_angle = lean_angle

	# Optionally, add a sound or particle effect here to indicate the rumble starting
	# get_node("RumbleSound").play()  # Example for sound
	# get_node("RumbleParticles").emitting = true  # Example for particles

func _process(delta: float) -> void:
	if is_collapsing:
		if rumble_timer > 0:
			rumble_timer -= delta
			rumble_effect(delta)
		elif fall_timer < fall_duration:
			fall_timer += delta
			fall_effect(delta)

# Rumble effect - shake the building
func rumble_effect(delta: float) -> void:
	var shake_intensity = 0.2  # How much the building shakes
	var shake_offset = Vector2(
		sin(rumble_timer * 10.0) * shake_intensity,   # Sinusoidal motion for shake effect
		cos(rumble_timer * 10.0) * shake_intensity
	)
	position = original_position + shake_offset  # Apply the shake effect
	rotation = sin(rumble_timer * 10.0) * 0.03    # Small shake effect for rotation

# Fall effect - lean the building and then fall
func fall_effect(delta: float) -> void:
	# Lean the building first
	position.y += fall_speed * delta
	rotation += delta * 0.5
	return
