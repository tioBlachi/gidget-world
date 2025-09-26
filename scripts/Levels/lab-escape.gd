extends Node2D

@export var map_limits: Rect2 = Rect2(0, 0, 2053, 1120)
@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var cell1 = $LabCell1/CellFloor
@onready var cell2 = $LabCell2/CellFloor
@onready var spikes = $Spikes
@onready var pSpawner = $pSpawner
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker
		
		
func _ready() -> void:
	add_to_group("lab_escape")
	if multiplayer.is_server():
		spawn_players.rpc(Net.players)
		_set_initial_flimsy_cell()
		
func _set_initial_flimsy_cell():
	randomize()
	var choice = randi() % 2
	set_flimsy_cell.rpc(choice)
	
@rpc("call_local", "reliable")
func set_flimsy_cell(choice: int):
	if choice == 0:
		cell1.is_flimsy = true
		print("Cell 1 is flimsy")
	else:
		cell2.is_flimsy = true
		print("Cell 2 is flimsy")

@rpc("authority", "call_local", "reliable")
func spawn_players(p_array: PackedInt32Array) -> void:
	if p_array.size() < 2:
		push_error("spawn_players: need 2 peer IDs, got %d" % p_array.size())
		return
		
	var markers := [player1marker, player2marker]
	var tints := [Color.WHITE, Color.hex(0xE0FFFF)]
	
	for i in 2:
		var peer_id := p_array[i]
		var player := player_scene.instantiate()
		player.name = str(peer_id)
		player.modulate = tints[i]
		player.global_position = markers[i].global_position
		player.set_multiplayer_authority(peer_id)

		pSpawner.add_child(player)

		var cam: Camera2D = player.get_node("Camera2D")
		cam.make_current()
			
@rpc("any_peer", "reliable")
func rpc_report_jump(peer_id: int):
	if not multiplayer.is_server():
		return
	var flr = cell1 if peer_id == 1 else cell2
	if not flr.is_flimsy or flr.is_open:
		return
	flr.jump_count += 1
	if flr.jump_count >= flr.jumps_needed:
		flr.rpc("rpc_unfreeze")
		
func _drop_trapdoor_now():
	$TrapDoor/AnimationPlayer.play("drop")
	
func get_map_limits() -> Rect2:
	return map_limits	
	
@rpc("authority", "call_local", "reliable")
func rpc_drop_trapdoor():
	_drop_trapdoor_now()

func _on_trap_anim_finished(anim_name: StringName) -> void:
	if String(anim_name) == "Drop":
		print("[TrapDoor] Drop finished")
		
func _on_spikes_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.die()
