extends Node2D

@onready var cam : Camera2D = $Camera2D
@onready var bottom_border = $Camera2D/BottomBorder
@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var pSpawner = $pSpawner
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker

@export var cam_rise_speed : float = 50

var players_spawned := 0

func _ready() -> void:
	if multiplayer.is_server():
		spawn_player.rpc(1)
		var peers := multiplayer.get_peers()
		if peers.size() > 0:
			var client := peers[0]
			if client != 1:
				spawn_player.rpc(client)
				print("Client spawned")

func _process(delta: float) -> void:
	var cam_position = cam.global_position.y
	cam_position -= cam_rise_speed * delta
	
	if cam_position < cam.limit_top:
		cam_position = cam.limit_top
		
	cam.global_position.y = cam_position
		
	
@rpc("authority", "call_local", "reliable")
func spawn_player(id: int):
	var player_instance = player_scene.instantiate()
	player_instance.get_node("Camera2D").enabled = false
	if id != 1:
		player_instance.modulate = Color.hex(0xE0FFFF)
	player_instance.name = str(id)
	var spawn_pos: Vector2 = player1marker.global_position if players_spawned == 0 else player2marker.global_position
	player_instance.global_position = spawn_pos
	pSpawner.add_child(player_instance)
	players_spawned += 1


func _on_bottom_border_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.die()
		
