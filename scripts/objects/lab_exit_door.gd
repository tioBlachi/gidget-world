extends Area2D

# Blas Antunez

# Simple script to control how the lab exit door is activated and synched
# in multiplayer mode+

signal lab_door_opened
signal player_left

@export var is_open := false

func _ready():
	if is_open:
		_start_open_anim()

func _on_body_entered_local(body: Node):
	if not body.is_in_group("players"):
		return
	var requester_id := body.name.to_int() if body.name.is_valid_int() else body.get_multiplayer_authority()
	if multiplayer.is_server():
		rpc_request_open(requester_id)
	else:
		rpc_id(1, "rpc_request_open", requester_id)

@rpc("any_peer", "reliable")
func rpc_request_open(requester_id: int):
	if not multiplayer.is_server():
		return
	if is_open:
		rpc("rpc_remove_player", requester_id)
		return
	if not _requester_has_keycard(requester_id):
		return
	rpc("rpc_open_door")
	rpc("rpc_remove_player", requester_id)

@rpc("authority", "call_local", "reliable")
func rpc_remove_player(peer_id: int):
	var p := find_player(peer_id)
	if p:
		emit_signal("player_left")
		p.queue_free()

@rpc("authority", "call_local", "reliable")
func rpc_open_door():
	if is_open:
		return
	is_open = true
	_start_open_anim()
	emit_signal("lab_door_opened")

func _start_open_anim():
	$AnimatedSprite2D.play("opening")
	$LabDoorOpenSfx.play()

func _requester_has_keycard(pid: int) -> bool:
	for k in get_tree().get_nodes_in_group("keycards"):
		if k.collected and k.holder_peer_id == pid:
			return true
	return false

func find_player(pid: int) -> Node:
	for p in get_tree().get_nodes_in_group("players"):
		if p.name == str(pid):
			return p
	return null
