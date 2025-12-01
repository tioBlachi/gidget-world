extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn")

@onready var pSpawner = $pSpawner
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker
@onready var keycards_left: int = $Keycards.get_children().size()
@onready var keycards: Array = $Keycards.get_children()
@onready var label: Label = $TimeLeftLabel
@onready var level_t: Timer = $LevelTimer
@onready var popup : Control = $PopupUI/restart_screen
@onready var g_timer: Timer = $Grinder/GrindTimer


var player_left = Net.players.size()

func _ready() -> void:
	if multiplayer.is_server():
		await get_tree().physics_frame
		spawn_players.rpc(Net.players)
	
	Global.keycard_collected.connect(func():
		keycards_left -= 1
		print(keycards_left)
		check_delete_spikes()
		)
		
	g_timer.timeout.connect(func():
		$AnimationPlayer.play("Grind")
		)
	level_t.timeout.connect(time_is_up)
		
		
func _process(delta: float) -> void:
	label.text = "%.2f" % level_t.time_left
	
func time_is_up():
	await get_tree().physics_frame
	popup.pause()
		
func check_delete_spikes():
	if keycards_left <= 0:
		#$Grinder.visible = false
		#$Grinder/CollisionShape2D.disabled
		$Grinder.queue_free()


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
		cam.enabled = false


func _on_grinder_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.die()


func _on_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		player_left -= 1
		body.queue_free()
		if player_left <= 0:
			popup.current_state = popup.LEVEL_STATE.COMPLETE
			popup.pause()
