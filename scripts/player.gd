extends CharacterBody2D

@export var SPEED: float = 200.0
@export var JUMP_VELOCITY: float = -375.0
@export var side_scroller: bool = true
@export var direction: float = 1.0
@onready var collision_shape = $CollisionShape2D

const PUSH_FORCE = 15.0
const MIN_PUSH_FORCE = 10.0

var cell_floor: RigidBody2D = null

var is_dead = false
var death_texture = preload("res://assets/BowenStuff/gDeath.png")

func _ready():
	var peer_id = name.to_int()
	if peer_id != 1:
		set_multiplayer_authority(peer_id)
	add_to_group("players")

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var level_root = get_parent().get_parent()
		if is_dead:
			velocity += get_gravity() * delta * 2.0 
			move_and_slide()
			return

		if side_scroller:
			#$Camera2D.make_current()
			
			if level_root and level_root.has_method("get_map_limits"):
				var limits = level_root.get_map_limits()
				$Camera2D.limit_left = int(limits.position.x)
				$Camera2D.limit_top = int(limits.position.y)
				$Camera2D.limit_right = int(limits.end.x)
				$Camera2D.limit_bottom = int(limits.end.y)
			if not is_on_floor():
				velocity += get_gravity() * delta

			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
				$JumpSound.play()
				
				var my_id = name.to_int()
				var lab = get_tree().get_first_node_in_group("lab_escape")
				if lab:
					if multiplayer.is_server():
						lab.rpc_report_jump(my_id)
					else:
						lab.rpc_id(1, "rpc_report_jump", my_id)

			direction = Input.get_axis("move left", "move right")
			if direction:
				velocity.x = direction * SPEED
				$Sprite.flip_h = direction < 0
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				
			_update_slope_tilt()
			
			if move_and_slide():
				for i in get_slide_collision_count():
					var c = get_slide_collision(i)
					var collider = c.get_collider()
					
					if collider and collider is RigidBody2D and collider.is_in_group("crates"):
						var push_direction = -c.get_normal()
						collider.apply_central_impulse(push_direction * PUSH_FORCE)
			
		else:
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
				$Sprite.flip_h = false
			elif x_direction < 0:
				$Sprite.flip_h = true

			move_and_slide()
		
# ----- KEYCARD/KEY HANDLING. UPDATE FOR OTHER WORLDS
var has_keycard := false
var keycard_ref: Node = null

func pickup_keycard(keycard: Node):
	has_keycard = true
	keycard_ref = keycard
	
func set_side_scroller(value: bool):
	side_scroller = value
	if not side_scroller:
		if is_instance_valid($Camera2D):
			$Camera2D.queue_free()

func _update_slope_tilt():
	if is_on_floor():
		var n := get_floor_normal()
		var t := Vector2(-n.y, n.x)
		var target := t.angle()

		$Sprite.rotation = lerp_angle($Sprite.rotation, target, 0.15)
		$CollisionShape2D.rotation = lerp_angle($Sprite.rotation, target, 0.15)
	else:
		# Smoothly return to upright in the air
		$Sprite.rotation = lerp_angle($Sprite.rotation, 0.0, 0.1)


func die():
	if is_dead:
		return

	is_dead = true
	self.modulate = Color(1,1,1,1)
	velocity.y = -1000
	velocity.x = 0
	
	collision_shape.set_deferred("disabled", true)
	
	$Sprite.texture = death_texture
	
	if is_instance_valid($Camera2D):
		$Camera2D.process_mode = self.PROCESS_MODE_DISABLED
	
	$MultiplayerSynchronizer.set_process(false)
	$DeathSFX.play()
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.5
	add_child(timer)
	timer.timeout.connect(_on_timer_complete)
	timer.timeout.connect(self.queue_free)
	timer.start()

func _on_timer_complete():
	get_tree().paused = true
