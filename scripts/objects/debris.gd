extends CharacterBody2D

@export var gravity: float = 600.0
@export var slow_multiplier: float = 0.4
@export var max_fall_speed: float = 250.0

#var velocity: Vector2 = Vector2.ZERO

func _ready():
	#$AnimatedSprite2D.play("fall") # play your falling animation
	Global.player_died.connect(remove_self)

func remove_self():
	queue_free()


func _physics_process(delta):
	velocity.y += gravity * slow_multiplier * delta
	velocity.y = min(velocity.y, max_fall_speed)
	move_and_slide()

	# Optional: remove when it goes off-screen
	#if global_position.y > 1200: # adjust to match your level
		#queue_free()
