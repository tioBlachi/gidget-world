extends CharacterBody2D

@export var SPEED: float = 200.0
@export var JUMP_VELOCITY: float = -375.0
@export var side_scroller: bool = true
@export var use_wasd: bool = false

var cell_floor: RigidBody2D = null
var facing_right = true
var _w_was_down := false

func _ready():
	add_to_group("players")

func _physics_process(delta: float) -> void:
	if side_scroller:
	# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if use_wasd:
			var w_now := Input.is_key_pressed(KEY_W)
			if w_now and not _w_was_down and is_on_floor():
				velocity.y = JUMP_VELOCITY
				$JumpSound.play()
			_w_was_down = w_now
		else:
			if Input.is_action_just_pressed("ui_up") and is_on_floor():
				velocity.y = JUMP_VELOCITY
				$JumpSound.play()
			
			if cell_floor and cell_floor.has_method("count_jumps"):
				cell_floor.count_jumps()


		# Get the input direction and handle the movement/deceleration.
		var direction := 0.0
		if use_wasd:
			if Input.is_key_pressed(KEY_A):
				direction -= 1.0
			if Input.is_key_pressed(KEY_D):
				direction += 1.0
		else:
			direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
			facing_right = direction > 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
	else:
		var x_direction := 0.0
		var y_direction := 0.0
		if use_wasd:
			if Input.is_key_pressed(KEY_A):
				x_direction -= 1.0
			if Input.is_key_pressed(KEY_D):
				x_direction += 1.0
			if Input.is_key_pressed(KEY_W):
				y_direction -= 1.0
			if Input.is_key_pressed(KEY_S):
				y_direction += 1.0
		else:
			x_direction = Input.get_axis("ui_left", "ui_right")
			y_direction = Input.get_axis("ui_up", "ui_down")
		var dir = Vector2(x_direction, y_direction)
		
		if dir != Vector2.ZERO:
			dir = dir.normalized()
			velocity.x = dir.x * SPEED
			velocity.y = dir.y * SPEED
			# Might use code below later
			#if x_direction != 0:
				#facing_right = x_direction > 0
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
			velocity.y = move_toward(velocity.y, 0.0, SPEED)

		move_and_slide()
		
# ----- KEYCARD/KEY HANDLING. UPDATE FOR OTHER WORLDS
var has_keycard := false
var keycard_ref: Node = null

func pickup_keycard(keycard: Node):
	has_keycard = true
	keycard_ref = keycard
