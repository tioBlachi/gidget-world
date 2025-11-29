extends Node


signal player_died
signal alligator_triggered_bite
func trigger_alligator_bite():
	alligator_triggered_bite.emit()
	
	

# Function called when a specific zone is active
func configure_players_for_new_interaction_zone():
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player is PhysicsBody2D or player is Area2D:
			player.collision_layer = 0 
			player.set_collision_layer_value(3, true)
			player.collision_mask = 1 | 2 | 4 
			print("Configured player: ", player.name, " for interaction zone.")

# Function to reset all players to standard configuration
func reset_players_to_standard_configuration():
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player is PhysicsBody2D or player is Area2D:
			player.collision_layer = 1 | 2
			player.collision_mask = 1 | 2
			print("Reset player: ", player.name, " to standard configuration.")
signal boss_hit
signal turret_hit
signal player_hit_by_turret(id: int)
signal player_hit_by_spike(hit_peer_id: int)
signal player_hit_by_bird(id: int)
