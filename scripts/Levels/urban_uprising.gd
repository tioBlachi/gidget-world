# Blas Antuenz

# Players need to climb the building while avoiding FlameDudes. If player touches a flamedude,
# they will be unable to contro their jump for a few seconds which can lead them to touch the botton
# border of the rising camera and dying.  

extends Node2D

@onready var level_cam : Camera2D = $Camera2D
@onready var bottom_border = $Camera2D/BottomBorder
@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var pSpawner = $pSpawner
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker
@onready var blue_bird := $BlueBird/AnimatedSprite2D
@onready var popup := $PopupUI/restart_screen

@export var cam_rise_speed : float = 35
var killzone_deactivated := false
var killzone_top: float

func _ready() -> void:
	if multiplayer.is_server():
		spawn_players.rpc(Net.players)
	killzone_top = $Camera2D/BottomBorder/Not_Active.global_position.y
	
	var bird := blue_bird.get_parent()
	bird.ready_to_fly.connect(flip_the_bird)
		
func flip_the_bird():
	blue_bird.flip_h = true
	await get_tree().create_timer(5.0).timeout
	trigger_win.rpc()


func _process(delta: float) -> void:
	var cam_position = level_cam.global_position.y
	cam_position -= cam_rise_speed * delta
	
	if cam_position < level_cam.limit_top:
		cam_position = level_cam.limit_top
		killzone_deactivated = true
		
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
		
@rpc("any_peer", "call_local")
func trigger_win():
	popup.current_state = popup.LEVEL_STATE.COMPLETE
	popup.pause()

func _on_bottom_border_body_entered(body: Node2D) -> void:
	if killzone_top >= bottom_border.global_position.y:
		return
	if body.is_in_group("players") and not killzone_deactivated:
		body.die.rpc()
