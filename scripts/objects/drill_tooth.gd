extends RigidBody2D

# Preload all required textures
const TEX_ORIGINAL = preload("res://assets/sprites/Decay Tooth.png")
const TEX_DRILLED = preload("res://assets/sprites/Drill Tooth.png")
const TEX_FILLED = preload("res://assets/sprites/Filled Tooth.png")

# Preload the generic item scene for spawning the final Exit 1 item
var ItemScene = preload("res://scenes/objects/Item.tscn")

# State Management
enum State { UNTOUCHED, DRILLED, FILLED }
var current_state: State = State.UNTOUCHED

# Get reference to the Sprite2D child node
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	contact_monitor = true
	max_contacts_reported = 10
	sprite.texture = TEX_ORIGINAL # Start with original texture

# Connect this function to the body_entered(body: Node2D) signal in the editor
func _on_body_entered(body: Node2D) -> void:
	# Check if the colliding body is the player group
	if body.is_in_group("players"):
		
		# We define the check logic locally, using the structure you provided
		# This function takes the player node 'body' as input
		var player_holds_drill = is_player_holding_item(body, "drill")
		var player_holds_filler = is_player_holding_item(body, "filler")
		
		# Get the held item's name for use in the print statement below
		var held_item_name_for_print = get_held_item_name(body)
		
		# Check interactions based on the current state and held item name
		if current_state == State.UNTOUCHED and player_holds_drill:
			change_state(State.DRILLED)
			print("Tooth is now drilled!")
			
		elif current_state == State.DRILLED and player_holds_filler:
			change_state(State.FILLED)
			print("Tooth is now filled! Spawning Exit 1.")
			spawn_exit_item()
			
		# Optional feedback if the player bumped the tooth with the wrong item
		# Use the temporary variable we created to print the name
		elif held_item_name_for_print != "":
			print("Bumped the tooth with an item called: ", held_item_name_for_print, " that had no effect.")

# A reusable function using the requested structure to check the held item name
func is_player_holding_item(player_node: Node2D, item_name_to_check: String) -> bool:
	var held_item_name = get_held_item_name(player_node)
	return held_item_name == item_name_to_check

# Helper function to consolidate getting the name from the player's held item node
func get_held_item_name(player_node: Node2D) -> String:
	var held_item_node = player_node.held_item
	
	if held_item_node:
		if held_item_node.has_method("get_item_data"):
			var item_data_dict = held_item_node.get_item_data() 
			if item_data_dict and item_data_dict["name"] is String:
				return item_data_dict["name"]
		
		# Fallback for simple name check
		return held_item_node.name 
		
	return "" # Return empty if nothing is held


func change_state(new_state: State):
# ... (rest of change_state function is the same) ...
	current_state = new_state
	match current_state:
		State.UNTOUCHED:
			sprite.texture = TEX_ORIGINAL
		State.DRILLED:
			sprite.texture = TEX_DRILLED
		State.FILLED:
			sprite.texture = TEX_FILLED
			
func spawn_exit_item():
# ... (rest of spawn_exit_item function is the same) ...
	var new_item_instance = ItemScene.instantiate()
	new_item_instance.item_name = "Exit 1"
	new_item_instance.sprite_texture = preload("res://assets/craftpix-net-965938-free-effects-for-platformer-pixel-art-pack/6 Extra/Objects/Capsule/3.png")
	new_item_instance.scale = Vector2(5, 5) 
	var world_node = get_tree().current_scene 
	world_node.add_child(new_item_instance)
	new_item_instance.global_position = global_position
	
	# Remove the tooth object after completion
	queue_free()
