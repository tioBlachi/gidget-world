extends RigidBody2D 

var is_carried = false
var player_node = null

func _ready():
	# Set up the item to not follow the scene tree pause
	process_mode = Node.PROCESS_MODE_INHERIT # Default, but useful to be explicit

func pickup(picker):
	is_carried = true
	player_node = picker
	# Stop physics simulation while carried
	set_physics_process(false)
	# Remove from its current parent in the world
	get_parent().remove_child(self)
	# Add as a child of the player's carry spot
	player_node.get_node("CarrySpot").add_child(self)
	# Reset position relative to the carry spot
	position = Vector2.ZERO 
	# Optional: adjust sprite z-index to be in front of player
	# get_node("Sprite2D").z_index = 1 

func drop():
	is_carried = false
	# Stop following the player's position logic, re-enable physics process
	set_physics_process(true) 
	# Remove from player's carry spot
	player_node.get_node("CarrySpot").remove_child(self)
	# Add back to the main scene tree (e.g., the root "World" node)
	# You will need a reference to the main world node to do this properly
	# For simplicity, for now it just goes back to the tree but might not render correctly
	# You should use a signal or a global script to handle re-instancing in the main world scene
	# A simple way for testing is to add it back to the main scene root if you can get a reference to it
	player_node = null
