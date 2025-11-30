extends CharacterBody2D

@export var min_speed := 60.0
@export var max_speed := 1000.0
@export var acceleration := 150.0
@export var turn_duration := 0.5
@export var bounce_back_distance := 20.0

var direction := Vector2.LEFT
var current_speed := 0.0
var turning := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	randomize()
	sprite.play("mow")

func _physics_process(delta: float) -> void:
	if turning:
		return

	current_speed = move_toward(current_speed, max_speed, acceleration * delta)
	velocity = direction * current_speed
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision:
			_on_collision(collision)

	if direction.length() > 0:
		var target_angle = direction.angle() + deg_to_rad(90)
		rotation = lerp_angle(rotation, target_angle, 5 * delta)

func _on_collision(collision: KinematicCollision2D) -> void:
	if turning:
		return

	turning = true
	current_speed = 0.0

	# Bounce back
	global_position -= direction * bounce_back_distance

	await get_tree().create_timer(turn_duration).timeout

	# Get the fence normal and flip it to point away from the fence
	var fence_normal = collision.get_normal()

	# Use the angle of the flipped normal as the center of our arc
	var away_angle = fence_normal.angle()

	# Define half of the arc angle in radians (85° on each side)
	var arc_half = deg_to_rad(85)

	# Pick a random angle within that arc centered on the 'away' direction
	var random_angle = randf_range(away_angle - arc_half, away_angle + arc_half)

	# Turn angle into direction vector
	direction = Vector2(cos(random_angle), sin(random_angle)).normalized()

	turning = false
