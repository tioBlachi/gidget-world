# Blas Antunez

# Second version of the enemy of urban uprising. A FlameDude has a Raycast that 
# detects players. Once detected, they chase that player wrecklessly

extends CharacterBody2D

@export var player: CharacterBody2D
@export var SPEED: int = 200
@export var CHASE_SPEED: int = 350
@export var ACCELERATION: int = 300
@onready var left_bounds: Marker2D = $LeftBounds
@onready var right_bounds: Marker2D = $RightBounds

@onready var dude: CharacterBody2D = $"."
@onready var face: AnimatedSprite2D = $Face
@onready var flames: AnimatedSprite2D = $Flames
@onready var blink_timer: Timer = $Face/BlinkTimer
@onready var chase_timer: Timer = $ChaseTimer
@onready var player_detector: RayCast2D = $Face/RayCast2D
@onready var player_original_sprite = preload("res://Art/OldTestArt/deathGidget.png")

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: Vector2
var left_limit: float
var right_limit: float


enum States {
	WANDER,
	CHASE
}
var current_state = States.WANDER

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	face.play("idle")
	flames.play("burning")
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	
	left_limit = left_bounds.global_position.x
	right_limit = right_bounds.global_position.x

	_restart_blink_timer()


func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_movement(delta)
	change_direction()
	look_for_player()
		
func look_for_player():
	if player_detector.is_colliding():
		var collider = player_detector.get_collider()
		if collider and collider.has_method("is_in_group") and collider.is_in_group("players"):
			player = collider
			chase_player()
		elif current_state == States.CHASE:
			stop_chase()
	elif current_state == States.CHASE:
		stop_chase()

func change_direction():
	if current_state == States.WANDER:

		if face.flip_h:
			# moving right
			if self.position.x >= right_limit:
				face.flip_h = false
				player_detector.target_position = Vector2(-125, 0)
				direction = Vector2(-1, 0)
			else:
				direction = Vector2(1, 0)

		else:
			# moving left
			if self.position.x <= left_limit:
				face.flip_h = true
				player_detector.target_position = Vector2(125, 0)
				direction = Vector2(1, 0)
			else:
				direction = Vector2(-1, 0)

	else:
		# chasing the player
		direction = (player.position - self.position).normalized()
		if direction.x > 0:
			face.flip_h = true
			player_detector.target_position = Vector2(125, 0)
		else:
			face.flip_h = false
			player_detector.target_position = Vector2(-125, 0)

		
func chase_player():
	chase_timer.stop()
	current_state = States.CHASE
	
func stop_chase():
	if chase_timer.time_left <= 0:
		chase_timer.start()
		
func handle_movement(delta: float):
	if current_state == States.WANDER:
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(direction * CHASE_SPEED, ACCELERATION * delta) 
	move_and_slide()
	
func handle_gravity(delta:float):
	if not is_on_floor():
		velocity.y += gravity * delta
			
func _on_burn_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		print("A player touched FlameDude")
		body.burning = true
		body.burn()
		panic(body)
		
		visible = false
		$BodyCollider.set_deferred("disabled", true)
		$BurnZone/BurnCollision.set_deferred("disabled", true)
		
func _on_blink_timer_timeout() -> void:
	face.play("blink")
	await face.animation_finished
	face.play("idle")
	_restart_blink_timer()
	
func _restart_blink_timer() -> void:
	blink_timer.start(rng.randf_range(1.0, 3.0))
	
func panic(player: CharacterBody2D):
	var timer: Timer = player.get_node("Timer")
	timer.one_shot = true
	timer.start(7.0)
	
	var b_timer = $Timer
	b_timer.one_shot = false
	b_timer.start(0.25)
	
	b_timer.timeout.connect(func():
		burn_bounce(player)
		)
	
	timer.timeout.connect(func ():
		print("Time is up!")
		b_timer.queue_free()
		await player.recover()
		player.burning = false
		queue_free()
	)

func burn_bounce(player: CharacterBody2D):
	player.staggered = false
	var sfx := player.get_node("JumpSound")

	if player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY * 0.35
		sfx.play()
	await get_tree().physics_frame
	


func _on_chase_timer_timeout() -> void:
	pass # Replace with function body.
