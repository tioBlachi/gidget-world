# GlobalGameManager.gd

extends Node

# Reference to the main animated sprite that will show the portal animations
var portal_animated_sprite: AnimatedSprite2D = null 

enum PuzzleStage { STAGE_ZERO, STAGE_ONE, STAGE_TWO, STAGE_THREE_COMPLETE }
var current_stage: PuzzleStage = PuzzleStage.STAGE_ZERO


func _ready():
	# Assuming the portal_animated_sprite variable is assigned a value somewhere else 
	# (e.g., in the parent scene's _ready function or via an export variable)
	if portal_animated_sprite != null:
		# Check if already connected before connecting again
		if not portal_animated_sprite.is_connected("animation_finished", Callable(self, "_on_portal_animated_sprite_animation_finished")):
			# Connect the signal from the sprite to this function within this script ('self')
			portal_animated_sprite.connect("animation_finished", Callable(self, "_on_portal_animated_sprite_animation_finished"))
			print("Signal successfully connected programmatically in _ready().")
	else:
		print("Error: portal_animated_sprite is null in _ready(). Cannot connect signal.")


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


func _on_portal_animated_sprite_animation_finished():
	print("Animation finished signal received.")
	print("Current Stage is: ", current_stage)
	print("Just finished animation: ", portal_animated_sprite.animation)
	
	# Check if the just-finished animation was "Opened 1" AND we are in the final stage
	if current_stage == PuzzleStage.STAGE_THREE_COMPLETE and portal_animated_sprite.animation == "Opened 1":
		print("Conditions met! Switching to Opened 2.")
		# Switch to "Opened 2", which should have its 'loop' property enabled in the editor
		portal_animated_sprite.play("Opened 2")
	else:
		print("Conditions failed. Not switching to Opened 2.")
