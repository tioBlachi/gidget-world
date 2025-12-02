# Blas Antunez

# Script for controlling how the CatHead moves. Using RNG to determine a 
# direction. Bounces off collidable environment using trigonometry and normalization
# of force vectors

extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $Anim
@onready var meow1: AudioStreamPlayer2D = $Meow1
@onready var meow2: AudioStreamPlayer2D = $Meow2
@onready var meow3: AudioStreamPlayer2D = $Meow3
@export var frames: SpriteFrames
@export var speed: float = 150.0
@export var flee_speed: float = 220.0
@export var bounce_nudge: float = 0.5
@export var bounce_random_deg: float = 12.0
@export var min_distance: float = 8.0
@export var max_distance: float = 200.0
@export var flee_distance: float = 150.0 # tweak this until it feels right
@export var min_pause: float = 0.5
@export var max_pause: float = 1.25

var is_herded = false
@export var moving: bool = false
@export var player_nearby: Node2D = null
@export var direction: Vector2 = Vector2.ZERO
var distance_left: float = 0.0
var rng := RandomNumberGenerator.new()
var pause_timer: Timer
var meow_timer: Timer

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
	add_to_group("cats", true)
	rng.randomize()
	
	if frames:
		anim.sprite_frames = frames
		if not anim.is_playing():
			anim.play("idle")
	# Timers
	pause_timer = Timer.new()
	meow_timer = Timer.new()
	pause_timer.one_shot = true
	meow_timer.one_shot = true
	add_child(pause_timer)
	add_child(meow_timer)
	pause_timer.timeout.connect(_on_pause_timeout)
	meow_timer.timeout.connect(_on_meow_timer_timeout)
	_reset_meow_timer()

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
		var collision_info = move_and_collide(away * step)
		if collision_info:
			_apply_bounce(collision_info, true)
		return
		
	if moving:
		var step = min(speed * delta, distance_left)
		var step_vector = direction.normalized() * step

		var collision = move_and_collide(step_vector)
		if collision:
			_apply_bounce(collision, false)
		else:
			distance_left -= step
			if distance_left <= 0:
				_stop_move()


func _start_move() -> void:
	direction = DIRECTIONS[rng.randi_range(0, DIRECTIONS.size() - 1)]
	distance_left = rng.randf_range(min_distance, max_distance)
	moving = true


func _stop_move() -> void:
	moving = false
	var wait_time = rng.randf_range(min_pause, max_pause)
	pause_timer.start(wait_time)


func _on_pause_timeout() -> void:
	_start_move()
	
	
func _on_meow_timer_timeout():
	if is_herded:
		return
	else:
		match rng.randi() % 2:
			0: if not meow1.playing: meow1.play()
			1: if not meow2.playing: meow2.play()
	_reset_meow_timer()
	
	
func _reset_meow_timer():
	meow_timer.wait_time = rng.randf_range(2.0, 6.0)
	meow_timer.start()


func _apply_bounce(c: KinematicCollision2D, is_fleeing: bool) -> void:
	var n := c.get_normal()
	var incoming: Vector2

	if is_fleeing and player_nearby:
		# FLEE: slide along the wall to avoid jitter
		incoming = (global_position - player_nearby.global_position).normalized()
		var slid := incoming.slide(n)
		if slid.length() < 0.001:
			var tangent := Vector2(-n.y, n.x)  # one of the tangents
			if tangent.dot(direction) < 0.0:
				tangent = -tangent
			slid = tangent
		direction = slid.normalized()
	else:
		# WANDER:
		incoming = direction.normalized()
		var reflected := incoming.bounce(n).normalized()
		reflected = reflected.rotated(deg_to_rad(rng.randf_range(-bounce_random_deg, bounce_random_deg)))
		direction = reflected.normalized()

	global_position += n * bounce_nudge
	
func _on_sense_body_entered(body: Node2D) -> void:
	#if body.name.begins_with("Player"):
	if body.is_in_group("players"):
		player_nearby = body


func _on_sense_body_exited(body: Node2D) -> void:
	#if body.name.begins_with("Player"):
	if body.is_in_group("players"):
		player_nearby = null
