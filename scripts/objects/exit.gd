extends Area2D

# Preload the texture for the active state (Crate 4 image)
const ACTIVE_TEXTURE = preload("res://assets/craftpix-net-965938-free-effects-for-platformer-pixel-art-pack/6 Extra/Objects/Capsule/4.png") 
# Preload the texture for the finished state (Crate 1 image)
const FINISHED_TEXTURE = preload("res://assets/craftpix-net-965938-free-effects-for-platformer-pixel-art-pack/6 Extra/Objects/Capsule/1.png") 

signal alligator_exit_opened

@onready var sprite: Sprite2D = $Sprite2D 
var is_activated: bool = false 
var is_finished: bool = false  

func _ready():
	# Make sure you connected the 'body_entered' signal in the Editor's Node tab
	pass 
	# If connecting in editor, you don't need body_entered.connect(_on_body_entered) in _ready

func _on_body_entered(body: Node2D) -> void:
	if is_finished: return 
	
	# --- New Print Statement ---
	if body.is_in_group("players") and body.has_method("get_held_item_name"):
		var held_name = body.get_held_item_name()
		if held_name == "":
			print("Player entered the exit zone, but is holding nothing.")
		else:
			print("Player entered the exit zone, holding item: ", held_name)
	# --- End New Print Statement ---

	var item_name = body.get_held_item_name()
	
	# --- Phase 1: Activate the exit with "Exit 1" item ---
	if not is_activated and item_name == "Exit 1":
		activate_exit(body)
		print("Exit activated with Exit 1 item!")
		body.queue_free()

	# --- Phase 2: Finish the level with "KeyTooth" item ---
	elif is_activated and item_name == "KeyTooth":
		finish_level(body)
		print("Level finished with KeyTooth!")


func activate_exit(item_node_to_despawn: Node):
	is_activated = true
	# This is where the magic happens: Set the sprite to the FINISHED_TEXTURE
	sprite.texture = FINISHED_TEXTURE 
	#item_node_to_despawn.queue_free()


func finish_level(item_node_to_despawn: Node):
	is_finished = true
	# This also uses the finished texture, which is fine
	#sprite.texture = FINISHED_TEXTURE
	#item_node_to_despawn.queue_free()
	
	print("Level End Triggered! Going to next level.")
	Global.reset_players_to_standard_configuration()
	#get_tree().quit()
	emit_signal("alligator_exit_opened")	

# Helper function to get the item name from the node
func get_item_name_from_node(node: Node) -> String:
	if node and node.has_method("get_item_data"):
		var item_data_dict = node.get_item_data()
		if item_data_dict and item_data_dict["name"] is String:
			return item_data_dict["name"]
	return ""
