extends CharacterBody2D

signal herded
signal escaped

# How fast the cat moves (pixels per second)
@export var speed: float = 150.0
@export var flee_speed: float = 220.0
# Minimum and maximum distance to move each time
@export var min_distance: float = 8.0
@export var max_distance: float = 200.0
@export var flee_distance: float = 150.0 # tweak this until it feels right
# How long to pause between moves
@export var min_pause: float = 0.5
@export var max_pause: float = 1.25

var moving: bool = false
var player_nearby: Node2D = null
var direction: Vector2 = Vector2.ZERO
var distance_left: float = 0.0
var rng := RandomNumberGenerator.new()
var pause_timer: Timer

# 8 directions the cat can choose from
const DIRECTIONS := [
	Vector2( 1,  0),   # right
	Vector2(-1,  0),   # left
	Vector2( 0,  1),   # down
	Vector2( 0, -1),   # up
	Vector2( 1,  1),   # down-right
	Vector2(-1,  1),   # down-left
	Vector2( 1, -1),   # up-right
	Vector2(-1, -1),   # up-left
]

func _ready() -> void:
	rng.randomize()
	# Timer to handle pauses, can be added in Scene Tree
	pause_timer = Timer.new()
	pause_timer.one_shot = true
	add_child(pause_timer)
	pause_timer.timeout.connect(_on_pause_timeout)

	_start_move()

func _physics_process(delta: float) -> void:
	# Animation
	if moving:
		$Anim.play("run")
	else:
		$Anim.play("idle")

	# Movement (only when moving is true)
	if player_nearby:
		var away = (global_position - player_nearby.global_position).normalized()
		var step = flee_speed * delta
		move_and_collide(away * step)
	if moving:
		var step = min(speed * delta, distance_left)
		var step_vector = direction.normalized() * step

		var collision = move_and_collide(step_vector)
		if collision:
			_stop_move()
		else:
			distance_left -= step
			if distance_left <= 0:
				_stop_move()


func _start_move() -> void:
	# Pick a random direction
	direction = DIRECTIONS[rng.randi_range(0, DIRECTIONS.size() - 1)]
	# Pick a random distance
	distance_left = rng.randf_range(min_distance, max_distance)
	moving = true

func _stop_move() -> void:
	moving = false
	# Wait a random pause time before next move
	var wait_time = rng.randf_range(min_pause, max_pause)
	pause_timer.start(wait_time)

func _on_pause_timeout() -> void:
	_start_move()
	

func _on_sense_body_entered(body: Node2D) -> void:
	if body.name.begins_with("Player"):
		player_nearby = body

func _on_sense_body_exited(body: Node2D) -> void:
	if body.name.begins_with("Player"):
		player_nearby = null


func _on_pen_body_entered(body: Node2D) -> void:
	if body.name.begins_with("Cat"):
		emit_signal("herded")


func _on_pen_body_exited(body: Node2D) -> void:
	if body.name.begins_with("Cat"):
		emit_signal("escaped")
