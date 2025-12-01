# GlobalGameManager.gd

extends Node

# Reference to the main animated sprite that will show the portal animations
var portal_animated_sprite: AnimatedSprite2D = null 

enum PuzzleStage { STAGE_ZERO, STAGE_ONE, STAGE_TWO, STAGE_THREE_COMPLETE }
var current_stage: PuzzleStage = PuzzleStage.STAGE_ZERO

# Function called when a specific zone is active
func configure_players_for_new_interaction_zone():
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player is PhysicsBody2D or player is Area2D:
			player.collision_layer = 0 
			player.set_collision_layer_value(3, true)
			player.collision_mask = 1 | 2 | 8 
			# print("Configured player: ", player.name, " for interaction zone.")

# Function to reset all players to standard configuration
func reset_players_to_standard_configuration():
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player is PhysicsBody2D or player is Area2D:
			player.collision_layer = 1 | 2
			player.collision_mask = 1 | 2
			# print("Reset player: ", player.name, " to standard configuration.")

func update_puzzle_state():
	# Only update the visual if we have a reference to the sprite
	if portal_animated_sprite == null:
		print("Error: Portal AnimatedSprite2D reference is missing!")
		return

	match current_stage:
		PuzzleStage.STAGE_ZERO:
			current_stage = PuzzleStage.STAGE_ONE
			portal_animated_sprite.play("Opening 1") 
			print("Stage 1 recorded globally. Playing Opening 1.")
		PuzzleStage.STAGE_ONE:
			current_stage = PuzzleStage.STAGE_TWO
			portal_animated_sprite.play("Opening 2")
			print("Stage 2 recorded globally. Playing Opening 2.")
		PuzzleStage.STAGE_TWO:
			current_stage = PuzzleStage.STAGE_THREE_COMPLETE
			portal_animated_sprite.play("Opened 1")
			print("Stage 3 recorded globally (Level should now end).")

# Add other global functions here, like changing levels
