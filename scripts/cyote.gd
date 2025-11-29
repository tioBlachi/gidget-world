extends CharacterBody2D

@export var SPEED: float = 200.0
@export var JUMP_VELOCITY: float = -375.0
@export var side_scroller: bool = true
@export var direction: float = 1.0
@export var staggered: bool = false
@export var burning: bool = false
@onready var sprite: Sprite2D = $Sprite
@onready var cam = $Camera2D
@onready var collision_shape = $CollisionShape2D
@onready var timer = $Timer
@export var max_fall_speed: float = 500.0
@export var is_gravity_level: bool = false
@export var god_mode: bool = false
@export var is_locally_paused := false

const PUSH_FORCE = 15.0
const MIN_PUSH_FORCE = 10.0

var cell_floor: RigidBody2D = null
var is_dead = false
var original_texture = preload("res://Art/OldTestArt/gRight.png")
var death_texture = preload("res://Art/OldTestArt/gDeath.png")
var burned_texture = preload("res://Art/OldTestArt/deathGidget.png")

signal character_died

# Coyote Time variables
var coyote_time: float = 0.2  # Time window for jumping after leaving the ground (in seconds)
var coyote_timer: float = 0.0  # Timer to track coyote time

func _ready():
	add_to_group("players")
	add_to_group("killzones")

func _physics_process(delta: float) -> void:
	if is_locally_paused:
		return
	
	# Handle gravity and fall speed
	if not is_dead:
		if not is_on_floor():
			coyote_timer -= delta  # Count down the coyote timer if we're in the air
		else:
			coyote_timer = coyote_time  # Reset the coyote timer when we land
	
		# Handle jump input with coyote time
		if not staggered:
			if side_scroller:
				# Apply gravity and max fall speed if not on the floor
				if not is_on_floor():
					var gravity_force := get_gravity()
					var fall_limit := max_fall_speed

					if is_gravity_level and Input.is_action_pressed("action2"):
						gravity_force *= 2.5
						fall_limit *= 2.5

					velocity += gravity_force * delta
					velocity.y = min(velocity.y, fall_limit)

				# Jump logic with coyote time
				if not burning and Input.is_action_just_pressed("jump"):
					# Check if we're on the floor or within coyote time
					if is_on_floor() or coyote_timer > 0:
						velocity.y = JUMP_VELOCITY
						$JumpSound.play()
						coyote_timer = 0  # Reset coyote timer when we jump

				# Handle movement
				direction = Input.get_axis("move left", "move right")
				if direction:
					velocity.x = direction * SPEED
					$Sprite.flip_h = direction < 0
				else:
					velocity.x = move_toward(velocity.x, 0, SPEED)

				_update_slope_tilt()
				move_and_slide()
			else:
				# Handle 8-direction movement
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
			
func burn():
	var stars = $Stars.get_children()
	if stars:
		for s in stars:
			s.visible = false
	print("Player: ", self.name, " is burned!")
	var burned_sprite = self.get_node_or_null("Sprite")
		
	burned_sprite.texture = burned_texture
	burned_sprite.self_modulate = Color.WHITE
	burning = true
	
func dizzy():
	if staggered and not burning:
		var stars = $Stars.get_children()
		for s in stars:
			if int(self.name) == Net.players[1]:
				s.self_modulate = Color(1,1,1,1)	 
				s.visible = true
				s.play("dizzy")
			else:
				s.visible = true
				s.play("dizzy")
	
func recover():
	staggered = false
	sprite.texture = original_texture
	if int(self.name) == Net.players[1]:
		sprite.self_modulate = Color.hex(0xE0FFFF)

func set_paused(value: bool) -> void:
	is_locally_paused = value

func _update_slope_tilt():
	if is_on_floor():
		var n := get_floor_normal()
		var t := Vector2(-n.y, n.x)
		var target := t.angle()

		$Sprite.rotation = lerp_angle($Sprite.rotation, target, 0.15)
		$CollisionShape2D.rotation = lerp_angle($Sprite.rotation, target, 0.15)
	else:
		$Sprite.rotation = lerp_angle($Sprite.rotation, 0.0, 0.1)

@rpc("any_peer", "call_local")
func die():
	
	if god_mode or is_dead:
		print("Player is in God Mode and cannot die.")
		return

	is_dead = true
	self.modulate = Color(1,1,1,1)
	$Sprite.self_modulate = Color.WHITE
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
	# timer.timeout.connect(self.queue_free)
	timer.start()

func _on_timer_complete():
	Global.player_died.emit()
	emit_signal("character_died")
	# get_tree().reload_current_scene()
	#get_tree().paused = true
