# Collin WHitney

extends CharacterBody2D

@export var min_speed := 60.0
@export var max_speed := 2000.0
@export var acceleration := 175.0
@export var turn_duration := 0.5
@export var bounce_back_distance := 22.0
@export var direction := Vector2.LEFT
@export var current_speed := 0.0
@export var turning := false
@export var stopping := false
@export var homing_strength := 0.5
var first_occurance := true
@onready var score_manager: Node2D = %"Score Manager"




@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	randomize()
	sprite.play("mow")

func _get_closest_player() -> Node2D:
	var players: Array = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return null

	var closest: Node2D = players[0]
	var closest_dist := global_position.distance_to(closest.global_position)

	for p in players:
		var d = global_position.distance_to(p.global_position)
		if d < closest_dist:
			closest = p
			closest_dist = d

	return closest


func _physics_process(delta: float) -> void:
	if turning:
		return
	
	if stopping:
		if first_occurance:
			sprite.pause()
			score_manager.key_collected()
			first_occurance = false
		current_speed = move_toward(current_speed, 0.0, acceleration * delta)
	else:
		current_speed = move_toward(current_speed, max_speed, acceleration * delta)

	# Curve toward closest player:
	if not turning and not stopping:
		var player = _get_closest_player()
		if player:
			var to_player = (player.global_position - global_position).normalized()
			direction = direction.lerp(to_player, homing_strength * delta).normalized()

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
	if turning or stopping:
		return
	turning = true
	current_speed = 0.0
	global_position -= direction * bounce_back_distance
	await get_tree().create_timer(turn_duration).timeout
	var fence_normal = collision.get_normal()
	var away_angle = fence_normal.angle()
	var arc_half = deg_to_rad(85)
	var random_angle = randf_range(away_angle - arc_half, away_angle + arc_half)
	direction = Vector2(cos(random_angle), sin(random_angle)).normalized()
	turning = false
