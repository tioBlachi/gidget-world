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
@export var max_fall_speed: float = 500.0 #allows other scenes to access max fall speed
@export var is_gravity_level: bool = false
@export var god_mode: bool = false

const PUSH_FORCE = 15.0
const MIN_PUSH_FORCE = 10.0

var cell_floor: RigidBody2D = null

var is_dead = false
var original_texture = preload("res://Art/OldTestArt/gRight.png")
var death_texture = preload("res://Art/OldTestArt/gDeath.png")
var burned_texture = preload("res://Art/OldTestArt/deathGidget.png")

func _ready():
	add_to_group("players")
	if get_tree().current_scene and get_tree().current_scene.name == "Alligator Dentistry":
		SPEED *= 2.5
		JUMP_VELOCITY *= 2.0

func _physics_process(delta: float) -> void:
	#print("Player velocity.y = ", velocity.y)
	#print("This is gravity level ", is_gravity_level)
	#print("We are not on floor ", not is_on_floor())
	#print("Input move up ", Input.is_action_pressed("move_up"))
	#print("Input move down ", Input.is_action_pressed("move_down"))
	#print("Input move right ", Input.is_action_pressed("move_right"))
	#print("Input move left ", Input.is_action_pressed("move_left"))
	#print("Input action 1 ", Input.is_action_pressed("action"))
	#print("Input action 2 ", Input.is_action_pressed("action2"))
	#print("Input jump ", Input.is_action_pressed("jump"))
	
	if is_multiplayer_authority():
		var level_root = get_parent().get_parent()
		if is_dead:
			velocity += get_gravity() * delta * 2.0 
			move_and_slide()
			return
		if not staggered:
			if side_scroller:
				if level_root and level_root.has_method("get_map_limits"):
					var limits = level_root.get_map_limits()
					$Camera2D.limit_left = int(limits.position.x)
					$Camera2D.limit_top = int(limits.position.y)
					$Camera2D.limit_right = int(limits.end.x)
					$Camera2D.limit_bottom = int(limits.end.y)

				if not is_on_floor():
					var gravity_force := get_gravity()
					var fall_limit := max_fall_speed

					if is_gravity_level and Input.is_action_pressed("action2"):
						gravity_force *= 2.5
						fall_limit *= 2.5

					velocity += gravity_force * delta
					velocity.y = min(velocity.y, fall_limit)

				if is_gravity_level and (Input.is_action_pressed("move up") or Input.is_action_pressed("jump")):
					velocity.y *= 0.9

				if not burning and Input.is_action_just_pressed("jump") and is_on_floor():
					velocity.y = JUMP_VELOCITY
					$JumpSound.play()
	   				 # (lab reporting)
					var lab = get_tree().get_first_node_in_group("lab_escape")
					if lab:
						var my_id = name.to_int()
						if multiplayer.is_server():
							lab.rpc_report_jump(my_id)
						else:
							lab.rpc_id(1, "rpc_report_jump", my_id)
	
				var direction := Input.get_axis("move left", "move right")
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
							collider.apply_central_impulse(push_direction * PUSH_FORCE)					#
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



var held_item = null
var float_offset = Vector2(-30, -80) 

func _process(delta):
	# Handle pickup/drop action
	if Input.is_action_just_pressed("pickup_drop"):
		if held_item:
			drop_item()
		else:
			try_pickup_item()

	# Update held item position if one exists
	if held_item:
		# Use global_position for accurate world positioning
		held_item.global_position = global_position + float_offset

func try_pickup_item():
	# Assuming the player has an Area2D named "PickupZone" to detect items
	var pickup_zone = $PickupZone 
	var overlapping_items = pickup_zone.get_overlapping_areas() # Adjust for body detection if needed

	for item_area in overlapping_items:
		if item_area.is_in_group("CollectableItems"): # Ensure items are in this group
			pickup_item(item_area)
			break # Only pick up one item at a time

func pickup_item(item_node):
	if held_item == null:
		# Remove the item from its original parent in the scene tree
		item_node.get_parent().remove_child(item_node)
		# Make the player the new parent
		add_child(item_node)
		held_item = item_node
		# Optionally, disable its physics/collision while held
		if item_node is RigidBody2D:
			item_node.set_physics_process(false)
			item_node.set_collision_layer_value(1, false)
			item_node.set_collision_mask_value(1, false)

func drop_item():
	if held_item:
		# Reparent the item back to the main world scene (e.g., "/root/World")
		# You may need a reference to your main world node
		var world_node = get_tree().current_scene # Gets the current main scene
		remove_child(held_item)
		world_node.add_child(held_item)
		
		# Set its global position where the player is (or in front of them)
		held_item.global_position = global_position
		
		# Re-enable physics/collision
		if held_item is RigidBody2D:
			held_item.set_physics_process(true)
			held_item.set_collision_layer_value(1, true)
			held_item.set_collision_mask_value(1, true)

		held_item = null



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
	timer.timeout.connect(self.queue_free)
	timer.start()

func _on_timer_complete():
	Global.player_died.emit()
	get_tree().reload_current_scene()
	#get_tree().paused = true


func _on_pickup_zone_area_entered(area: Area2D) -> void:
	if area.is_in_group("CollectableItems"):
		print("An item is nearby and overlapping: ", area.name)
		

# Optional: Add a message for when an item leaves the zoned



func _on_pickup_zone_area_exited(area: Area2D) -> void:
	if area.is_in_group("CollectableItems"):
		print(area.name, " has left the pickup zone.")
