extends CharacterBody2D


@export var base_speed = 100.0
@export var max_fall_speed: float = 1800.0 
@export var chase_distance: float = 1000.0
@export var min_speed_distance: float = 50.0
@export var max_speed_distance: float = 2000.0
@export var max_chase_speed: float = 2000.0
@export var gravity_transition_speed: float = 2.0 # Controls how fast the gravity changes

var player = null
var current_gravity_factor = 1.0 # The factor that will be lerped
var target_gravity_factor = 1.0 # The target gravity factor
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	player = get_tree().get_first_node_in_group("players") 
	Global.player_died.connect(remove_self)
	Global.level_ended.connect(remove_self)
	
func remove_self():
	queue_free()

func _physics_process(delta: float) -> void:
	if player == null:
		return

	# Handle vertical movement (gravity/negative gravity)
	if not is_on_floor():
		if player.global_position.y < global_position.y:
			# Target negative gravity when player is above
			target_gravity_factor = -4.0
		else:
			# Target normal gravity when player is below
			target_gravity_factor = 4.0
		
		# Interpolate the current gravity factor towards the target
		current_gravity_factor = lerp(current_gravity_factor, target_gravity_factor, gravity_transition_speed * delta)
		
		velocity.y += gravity * current_gravity_factor * delta
		
		# Clamp the vertical velocity to the maximum fall speed
		velocity.y = clamp(velocity.y, -max_fall_speed, max_fall_speed)
	else:
		# Reset gravity when on the floor
		current_gravity_factor = 1.0
		target_gravity_factor = 1.0
	
	# Handle horizontal movement
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= chase_distance:
		var current_speed = remap(
			distance_to_player,
			min_speed_distance,
			max_speed_distance,
			base_speed,
			max_chase_speed
		)
		
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, base_speed * delta)

	move_and_slide()
