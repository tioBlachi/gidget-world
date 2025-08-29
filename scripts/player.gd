extends CharacterBody2D

@export var SPEED: float = 200.0
@export var JUMP_VELOCITY: float = -375.0
@export var side_scroller: bool = true

var cell_floor: RigidBody2D = null
var facing_right = true


func _ready():
	add_to_group("players")

func _physics_process(delta: float) -> void:
	if side_scroller:
	# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			$JumpSound.play()
			
			if cell_floor and cell_floor.has_method("count_jumps"):
				cell_floor.count_jumps()


		# Get the input direction and handle the movement/deceleration.
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
			facing_right = direction > 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
	else:
		var x_direction = Input.get_axis("ui_left", "ui_right")
		var y_direction = Input.get_axis("ui_up", "ui_down")
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
