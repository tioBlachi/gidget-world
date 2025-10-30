extends Node2D

@export var map_limits: Rect2 = Rect2(0, 0, 2550, 1440)

@onready var pSpawner = $pSpawner
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker
@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var white_fade: ColorRect = $CanvasLayer/WhiteFade
@onready var boss = $PortalBoss
@onready var phase1_turret = $Turret
@onready var p1_doors := $Phase1Doors.get_children()
@onready var p1_generators := $Phase1Generators2.get_children()
@onready var cam = $Camera2D

@export var _start_phase_1 := 0
@export var p1_generators_destroyed := 0
var p1_L_target
var p1_R_target 
var players_in_r2 := 0
var _shake_time := 0.0
var _shake_duration := 0.0
var _shake_strength := 0.0
var _original_offset := Vector2.ZERO


func _ready():		
	if multiplayer.is_server():
		spawn_players.rpc(Net.players)
		
	for d in p1_doors:
		if d.name.begins_with("Left"):
			p1_L_target = d.origin
		else:
			p1_R_target = d.origin
	boss.phase = 0
	white_fade.color = Color(1,1,1,0)
	# ---------- CONNECT SIGNALS -------------
	phase1_turret.generator_destroyed.connect(on_generator_destroyed)
	boss.portal_defeated.connect(fade_to_white)

	var phase1_buttons = $Phase1Buttons.get_children()
	for b in phase1_buttons:
		b.button_pressed.connect(on_p1_btn_pressed)
		b.button_released.connect(on_p1_btn_released)
		
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
			player.cam.enabled = false
			
func _process(delta: float) -> void:
	_apply_screen_shake(delta)

func get_map_limits() -> Rect2:
	return map_limits	
	
func fade_to_white(duration: float = 8.0) -> void:
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

func on_p1_btn_pressed():
	if multiplayer.is_server():
		_start_phase_1 += 1
		clamp(_start_phase_1, 0, Net.players.size())
		if _start_phase_1 == Net.players.size():
			var players = get_tree().get_nodes_in_group("players")
			for p in players:
				p.staggered = true
			var buttons := get_tree().get_nodes_in_group("buttons")
			for b in buttons:
				b.turn_off_collision.rpc()
			await get_tree().create_timer(2).timeout
			boss.phase = 1
			phase1_turret.activated = true
			
			for p in players:
				p.staggered = false

func on_p1_btn_released():
	if multiplayer.is_server():
		_start_phase_1 -= 1
		clamp(_start_phase_1, 0, Net.players.size())
		print("Activated Buttons: ", _start_phase_1)
		
@rpc("authority", "call_local", "reliable")
func on_generator_destroyed():
	p1_generators_destroyed += 1
	print("Destroyed Generators: ", p1_generators_destroyed)
	if p1_generators_destroyed >= get_tree().get_nodes_in_group("generators").size():
		phase1_turret.activated = false
		var tween = get_tree().create_tween()
		tween.tween_property(cam, "position", Vector2(boss.global_position.x / 2, boss.global_position.y / 2), 2.0)
		for i in range(2):
			tween = get_tree().create_tween()
			var player = $pSpawner.get_child(i)
			if i == 0:
				tween.tween_property(player, "position", Vector2(404.0, 653.0), 2.0)
			if i == 1:
				tween.tween_property(player, "position", Vector2(444.0, 653.0), 2.0)
		await get_tree().create_timer(2.0).timeout
		boss.phase += 2
		await get_tree().create_timer(2.0).timeout
		tween = get_tree().create_tween()
		tween.tween_property(cam, "position", Vector2(0, boss.global_position.y / 2), 2.0)
		await get_tree().create_timer(1.0).timeout
		if multiplayer.is_server():
			for d in p1_doors:
				d.activate()

func _on_2nd_room_body_entered(body: Node2D) -> void:
	players_in_r2 += 1
	if players_in_r2 >= Net.players.size():
		var tween = get_tree().create_tween()
		tween.tween_property(cam, "position", Vector2(0.0, boss.global_position.y), 2.0)
		for d in p1_doors:
			if d.name.begins_with("Right"):
				d.origin = d.global_position
				d._goal = p1_R_target
			else:
				d.origin = d.global_position
				d._goal = p1_L_target
			d.activate()
	
