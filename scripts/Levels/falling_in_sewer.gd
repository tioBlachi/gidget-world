extends Node2D



func _ready() -> void:
	for player in get_tree().get_nodes_in_group("players"):
		player.is_gravity_level = true
	var players_in_scene = get_tree().get_nodes_in_group("players")
	print("Nodes in 'players' group: ", players_in_scene)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	

	
	pass



func _on_death_line_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.die()
		
