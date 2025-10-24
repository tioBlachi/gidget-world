extends Node2D

@export var map_limits: Rect2 = Rect2(0, 0, 2550, 1440)

@onready var pSpawner = $pSpawner
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker
@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var white_fade: ColorRect = $CanvasLayer/WhiteFade
@onready var boss = $PortalBoss

var _shake_time := 0.0
var _shake_duration := 0.0
var _shake_strength := 0.0
var _original_offset := Vector2.ZERO

func _ready():
	if multiplayer.is_server():
		spawn_players.rpc(Net.players)
		
	white_fade.color = Color(1,1,1,0)
	#white_fade.modulate.a = 0.0
	boss.portal_defeated.connect(fade_to_white)
		
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
		player.side_scroller = false
		player.scale = Vector2.ONE * 0.3
		pSpawner.add_child(player)
		if multiplayer.get_unique_id() == peer_id:
			var cam: Camera2D = player.get_node("Camera2D")
			cam.make_current()
			
func _process(delta: float) -> void:
	_apply_screen_shake(delta)
			
		
func get_map_limits() -> Rect2:
	return map_limits	
	
func fade_to_white(duration: float = 9.0) -> void:
	print("Signal received")
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(white_fade, "color:a", 1.0, duration)
	

func start_screen_shake(strength: float = 12.0, duration: float = 7.0) -> void:
	_shake_strength = strength
	_shake_duration = max(duration, 0.001)
	_shake_time = duration
	
func _apply_screen_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		# Reset camera offset when done
		var cam := get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2.ZERO
		return
	
	_shake_time -= delta
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return

	var t = clamp(_shake_time / _shake_duration, 0.0, 1.0)
	var falloff = t * t  # nice smooth fade-out
	var amt = _shake_strength * falloff

	var jitter := Vector2(
		randf_range(-amt, amt),
		randf_range(-amt, amt)
	)

	cam.offset = jitter
