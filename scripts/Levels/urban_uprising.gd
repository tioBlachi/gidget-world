extends Node2D

@onready var level_cam : Camera2D = $Camera2D
@onready var bottom_border = $Camera2D/BottomBorder
@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var pSpawner = $pSpawner
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker

@export var cam_rise_speed : float = 40

func _ready() -> void:
	if multiplayer.is_server():
		spawn_players.rpc(Net.players)


func _process(delta: float) -> void:
	var cam_position = level_cam.global_position.y
	cam_position -= cam_rise_speed * delta
	
	if cam_position < level_cam.limit_top:
		cam_position = level_cam.limit_top
		
	level_cam.global_position.y = cam_position
		
	
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
		var sprite := player.get_node("Sprite")
		player.JUMP_VELOCITY = -400
		player.name = str(peer_id)
		sprite.self_modulate = tints[i]
		player.global_position = markers[i].global_position
		player.set_multiplayer_authority(peer_id)

		pSpawner.add_child(player)

		var cam: Camera2D = player.get_node("Camera2D")
		cam.enabled = false


func _on_bottom_border_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.die.rpc()
		

func _on_can_2_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and $Can2:
		if $Can2.paused == true:
			$Can2.paused = false
