# Jacob Ashmore

extends RigidBody2D

@export var is_key_tooth: bool = false
var ItemScene = preload("res://scenes/objects/Item.tscn") 
const KEY_TOOTH_TEXTURE = preload("res://assets/sprites/KeyCard.png")

# Define the force for the initial upward pop
var pop_up_force = Vector2(0, -500) # Negative Y is up
var pop_up_torque = 200 # Add some rotation for effect

# A flag to prevent the tooth from activating multiple times
var extracted = false

func _ready():
	# Make sure we monitor collisions
	contact_monitor = true
	max_contacts_reported = 5

# Connect this function to the body_entered(body: Node2D) signal in the editor


func _on_body_entered(body: Node2D):
	print("Function called by: ", body.name, " (Extracted state: ", extracted, ")")
	if body.is_in_group("players"):
		print("Body is in group players.")
	# Check if the colliding body is the player (assuming player is in a "Player" group)
	if not extracted and body.is_in_group("players"):
		# The body parameter here is the Player node
		
		# Access the player's script to check the held item
		# We need the player script to have an 'is_holding_extractor()' function
		
		if body.has_method("is_holding_extractor") and body.is_holding_extractor():
			extract_tooth.rpc()

@rpc("any_peer", "call_local")
func extract_tooth():
	if extracted: return
	extracted = true
	
	# 1. Apply a sudden force upwards to make it "pop"
	apply_central_impulse(pop_up_force)
	apply_torque_impulse(pop_up_torque)

	# 2. Make the tooth fall through the scenery (disable its interaction with the ground)
	# This assumes 'World' is on Layer 1 in your Project Settings (see previous explanation)
	set_collision_mask_value(1, false) 
	
	print("Tooth extracted and falling through the world!")
	if is_key_tooth:
		spawn_key_tooth_item()
	# Queue the tooth for deletion after a few seconds
	var timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(self.queue_free)
	timer.start(5.0) # Delete after 5 seconds


func spawn_key_tooth_item():
	# Instantiate a new item using the generic Item Scene
	var new_item_instance = ItemScene.instantiate()
	
	# Configure the instance to be a "KeyTooth" using exported variables
	# This calls the setter function you defined in Item.gd
	new_item_instance.item_name = "KeyTooth" 
	new_item_instance.item_type = "Key"
	new_item_instance.scale = Vector2(5, 5) 
	# new_item_instance.sprite_texture = preload("res://Art/key_texture.png") # Set specific texture here

	# Get the main world scene node to add the naew item to the tree
	var world_node = get_tree().current_scene 
	world_node.add_child(new_item_instance)
	new_item_instance.sprite_texture = KEY_TOOTH_TEXTURE 
	# Place the item where the tooth was located
	new_item_instance.global_position = global_position
	
	print("Spawned a KeyTooth item at location.")

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("2d body entered called by: ", body.name, " (Extracted state: ", extracted, ")")
	if body.is_in_group("players"):
		print("Body is in group players.")
	# --- Debugging Print Statements ---
	var has_method_check = body.has_method("is_holding_extractor")
	print("Does body have is_holding_extractor method? ", has_method_check)
		
	var is_holding_extractor_check = false
	if has_method_check:
		is_holding_extractor_check = body.is_holding_extractor()
		print("Is player currently holding the extractor? ", is_holding_extractor_check)
		# --- End Debugging Print Statements ---
		
		# Check if the colliding body is the player and not already extracted
		if not extracted and is_holding_extractor_check:
			# The body parameter here is the Player node
			print("Conditions met: Extracting tooth!")
			extract_tooth.rpc()
		elif not extracted:
			print("Player is nearby, but is not holding the correct item.")
