extends Area2D

# Get references to child nodes using @onready
# Adjust the node paths below (e.g., $AnimationPlayer or $AnimatedSprite2D)
@onready var animation_player: AnimationPlayer = $AnimationPlayer 

# The name of the final, complete animation (e.g., "Opened 2" or "Opened_2")
const LEVEL_COMPLETE_ANIM_NAME: String = "Opened 2" 

func _ready():
	# Connect the signal locally in the script to detect when a player enters the *finished* portal area
	body_entered.connect(_on_body_entered)
	
	# Optional: Link this scene's AnimationPlayer to the global manager immediately upon loading
	if GlobalGameManager:
		# If you are using AnimatedSprite2D instead, use: 
		# GlobalGameManager.portal_animated_sprite = $AnimatedSprite2D
		# Make sure you link the correct node type used in the manager script.
		pass 

func _on_body_entered(body: Node2D):
	# Check if the body entering is a player
	if body.is_in_group("players"):
		print("Player entered the final portal area.")
		
		# Check the global game state first
		var puzzle_is_complete_globally = GlobalGameManager and GlobalGameManager.current_stage == GlobalGameManager.PuzzleStage.STAGE_THREE_COMPLETE

		# Check the local animation state (if you prefer this check instead/additionally)
		var animation_is_finished = false
		if animation_player:
			animation_is_finished = animation_player.current_animation == LEVEL_COMPLETE_ANIM_NAME and not animation_player.is_playing()

		# Proceed to the next scene only if the state is verified
		if puzzle_is_complete_globally or animation_is_finished:
			print("Level conditions met. Loading next scene.")
			get_tree().quit() 
			# Replace "res://path/to/your/LevelQuitScene.tscn" with your actual scene path
			# Note: Best practice is often to use a global function to change scenes
			# get_tree().change_scene_to_file("res://scenes/LevelQuitScene.tscn") 
			
			# Example using a global manager function if you have one:
			#if GlobalGameManager and GlobalGameManager.has_method("load_level_quit_scene"):
				#GlobalGameManager.load_level_quit_scene()
			#else:
				# Fallback scene change
				#get_tree().change_scene_to_file("res://scenes/LevelQuitScene.tscn")

		else:
			print("Portal is not yet fully activated. Puzzle stage:", GlobalGameManager.current_stage)
