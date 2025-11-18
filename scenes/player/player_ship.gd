extends CharacterBody2D

@onready var sprite := $AnimatedSprite2D
@export var SPEED: float = 200.0
@export var disabled := false


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not disabled:
		var x_direction = Input.get_axis("move left", "move right")
		var y_direction = Input.get_axis("move up", "move down")
		var dir = Vector2(x_direction, y_direction)

		if dir != Vector2.ZERO:
			dir = dir.normalized()
			velocity.x = dir.x * SPEED
			velocity.y = dir.y * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
			velocity.y = move_toward(velocity.y, 0.0, SPEED)

		if x_direction > 0:
			sprite.flip_h = false
			SPEED = 200.0
		elif x_direction < 0:
			sprite.flip_h = true
			SPEED = 100.0
		if Input.is_action_just_pressed("action"):
			print(self.name, " Should be shooting right now!")
		move_and_slide()
