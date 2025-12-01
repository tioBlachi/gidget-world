extends Node2D # Or whatever your level's root node type is

# Reference the AnimatedSprite2D node in your scene via its path
@onready var portal_sprite: AnimatedSprite2D = $"Exit/Portal Animation"
# @onready var level_camera: Camera2D = $Camera2D # If you added a level camera for top-down view

func _ready():
	# --- CRITICAL STEP ---
	# Assign the local AnimatedSprite2D node reference to the global manager
	if GlobalGameManager:
		GlobalGameManager.portal_animated_sprite = portal_sprite
		print("Level script assigned portal_sprite to the global manager.")
		
	# --- Existing Level Setup ---
	# Configure player movement and physics globally for this level
	if Global:
		Global.set_all_players_side_scroller(false) # Set to 'false' for 2D top-down mode
		Global.configure_players_for_new_interaction_zone()
		print("Level loaded: Side scrolling is now OFF for all players.")

	# You can start an initial animation or keep it blank until the first item is placed
	# portal_sprite.play("default") 


# If you were using map limits previously, you can keep this function
# func get_map_limits() -> Rect2:
#     # Return the boundaries of your level for camera limits
#     return Rect2(0, 0, 1000, 1000) # Example limits
