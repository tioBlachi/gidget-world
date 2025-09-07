extends CharacterBody2D

@export var SPEED: float = 200.0
@export var JUMP_VELOCITY: float = -375.0
@export var side_scroller: bool = true
@export var move_direction: float = 1.0

@onready var multiplayer_sync = $MultiplayerSynchronizer

var cell_floor: RigidBody2D = null


func _ready():
	var peer_id = name.to_int()
	if peer_id != 1:
		set_multiplayer_authority(peer_id)
	add_to_group("players")

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		#$Camera2D.make_current()
		if side_scroller:
		# Add the gravity.
			$Camera2D.make_current()
			if not is_on_floor():
				velocity += get_gravity() * delta

			# Handle jump.
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
				$JumpSound.play()
				
				#if cell_floor and cell_floor.has_method("count_jumps"):
					#cell_floor.count_jumps()
				var my_id = name.to_int()
				var lab = get_tree().get_first_node_in_group("lab_escape")
				if lab:
					if multiplayer.is_server():
						lab.rpc_report_jump(my_id)
					else:
						lab.rpc_id(1, "rpc_report_jump", my_id)


			# Get the input direction and handle the movement/deceleration.
			var direction := Input.get_axis("ui_left", "ui_right")
			if direction:
				velocity.x = direction * SPEED
				move_direction = direction
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
	
func set_side_scroller(value: bool):
	side_scroller = value
	$Camera2D.queue_free()
