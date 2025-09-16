extends Area2D

@export var collected := false
@export var holder_peer_id: int = 0

var holder: Node = null  # The player holding it

func _ready():
	add_to_group("keycards")
	var door = get_node("../LabExitDoor")
	if door:
		door.connect("lab_door_opened", _on_door_opened)
		
	if not is_connected("body_entered", Callable(self, "_on_body_entered_local")):
		body_entered.connect(_on_body_entered_local)
	
	
func _on_door_opened():
	queue_free()
	
	
func _process(_delta: float) -> void:
	# Visual follow (no reparent): derive from holder each frame
	if collected:
		if holder == null:
			holder = find_player(holder_peer_id)
		if holder:
			# Keep position floating in front of player (GLOBAL positioning)
			var bob_height = 2.0
			var x_offset = 40 if holder.direction > 0 else -40
			var y_offset = -50
			global_position = holder.global_position + Vector2(
				x_offset,
				y_offset + sin(Time.get_ticks_msec() / 200.0) * bob_height
			)

# This is for local stuff that happens, not server
func _on_body_entered_local(body):
	if collected: return
	if body.is_in_group("players"):
		var peer_id = body.name.to_int() if body.name.is_valid_int() else body.get_multiplayer_authority()
		if multiplayer.is_server():
			# We're already the server — call the server method directly
			rpc_request_pickup(peer_id)
		else:
			# Ask the server
			rpc_id(1, "rpc_request_pickup", peer_id)

		
func find_player(id: int):
	for p in get_tree().get_nodes_in_group("players"):
		if p.name == str(id):
			return p
	return null

@rpc("any_peer", "reliable")
func rpc_request_pickup(requester_id: int):
	if not multiplayer.is_server():
		return
	if collected:
		return

	var player = find_player(requester_id)
	if player == null:
		return

	collected = true
	holder_peer_id = requester_id
	holder = player
	$collect_sfx.play()

	if player.has_method("pickup_keycard"):
		player.pickup_keycard(self)
		
	var lab = get_tree().get_first_node_in_group("lab_escape")
	if lab and lab.has_method("rpc_drop_trapdoor"):
		lab.rpc("rpc_drop_trapdoor")
