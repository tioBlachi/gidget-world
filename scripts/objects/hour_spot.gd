extends Area2D

# The required item name is explicitly defined in the script for this specific spot
const REQUIRED_ITEM_NAME: String = "hourglass"

func _ready():
	# Connect the signal locally in the script
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	# Check if the body entering is a player
	if body.is_in_group("players"):
		var player_node = body
		var held_item_name = get_item_name(player_node.held_item)

		print(self.name, ": Player entered holding '", held_item_name, "'. Needs '", REQUIRED_ITEM_NAME, "'.")

		if held_item_name == REQUIRED_ITEM_NAME:
			# 1. Update the global puzzle state
			# Ensure "PuzzleGlobalManager" matches your Autoload Node Name
			if GlobalGameManager: 
				GlobalGameManager.update_puzzle_state() # Triggers animation change in global script

			# 2. Despawn the item from the player's hand
			if player_node.held_item:
				player_node.held_item.queue_free()
				player_node.held_item = null
				 
			# 3. Despawn the spot itself
			queue_free()

# Helper function (copy this from previous examples in Item.gd)
func get_item_name(node: Node) -> String:
	if node and node.has_method("get_item_data"):
		var item_data_dict = node.get_item_data()
		if item_data_dict and item_data_dict["name"] is String:
			return item_data_dict["name"]
	return ""
