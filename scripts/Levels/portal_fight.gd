extends Node2D

@export var red_bird_scene: PackedScene

@onready var bg := $Background
@onready var CatBoss := $CatBoss
@onready var boss_anim := $CatBoss/Anim
@onready var player1marker := $PlayerMarkers/Player1Marker
@onready var player2marker := $PlayerMarkers/Player2Marker
@onready var pSpawner := $pSpawner
@onready var player_scene = preload("res://scenes/player/PlayerShip.tscn")
@onready var music := $Music
@onready var turrets := $CatBoss/Turrets.get_children()
@onready var popup := $PopupUI/restart_screen
# Boss stuff
@onready var white_fade: ColorRect = $Fader/WhiteFade
@onready var explosion_template: AnimatedSprite2D = $Explosions
@onready var spike_spawn_points := $CatBoss/SpikeSpawnPoints.get_children()
@export var explosion_radius = 150.0
@export var explosions_total = 7
@export var spike_ring_scene: PackedScene
@export var boss_hp := 20;
@export var random_num: int


var players : Array
var phase_2_entered := false
var phase_3_entered := false
var boss_float_base_y: float
var boss_float_time := 0.0
var boss_float_base_pos: Vector2
var phase_over := false


func _ready() -> void:
	boss_float_base_pos = CatBoss.position
	boss_float_base_y = CatBoss.position.y
	$CanvasLayer/BossHP.max_value = boss_hp
	bg.play("default")
	$CanvasLayer/BossHP.value = boss_hp
	if multiplayer.is_server():
		spawn_players.rpc(Net.players)
		
	Global.boss_hit.connect(on_boss_hit_by_laser)
	Global.player_died.connect(on_player_died)
	phase_1.rpc()
	
	
func _process(delta: float) -> void:
	boss_float_time += delta

	var amplitude_y := 10.0
	var amplitude_x := 5.0
	var speed := 1.0

	CatBoss.position.y = boss_float_base_pos.y + sin(boss_float_time * speed) * amplitude_y
	CatBoss.position.x = boss_float_base_pos.x + cos(boss_float_time * speed * 0.7) * amplitude_x


	
@rpc("any_peer", "call_local")
func activate_players():
	for p in pSpawner.get_children():
		p.disabled = false
		p.invincible = false

@rpc("any_peer", "call_local")
func deactivate_players():
	for p in pSpawner.get_children():
		p.disabled = true
		p.invincible = true

@rpc("any_peer", "call_local")
func reverse_players():
	for p in pSpawner.get_children():
		p.reversed = true

@rpc("any_peer", "call_local")
func unreverse_players():
	for p in pSpawner.get_children():
		p.reversed = false

@rpc("authority", "call_local")
func phase_1():
	for t in turrets:
		t.activated = true
		await get_tree().create_timer(1.0).timeout


@rpc("authority", "call_local")
func end_phase_1():
	phase_over = true
	for t in turrets:
		t.activated = false
		t.queue_free()
	deactivate_players.rpc()
	boss_anim.play("angry")
	await get_tree().create_timer(2.0).timeout
	phase_2.rpc()

@rpc("authority", "call_local", "reliable")
func phase_2():
	if not multiplayer.is_server():
		return

	phase_over = false
	reverse_players.rpc()
	activate_players.rpc()
	boss_anim.play("patch")

	spawn_all_spike_rings.rpc()

	while phase_2_entered and not phase_over:
		var t := get_tree().create_timer(3.0)
		await t.timeout

		if phase_over or not phase_2_entered or phase_3_entered:
			break

		var choice := randi_range(1, 4)
		match choice:
			1:
				spawn_spike_ring_at.rpc(0)
			2:
				spawn_spike_ring_at.rpc(1)
			3:
				spawn_spike_ring_at.rpc(2)
			_:
				spawn_all_spike_rings.rpc()



@rpc("authority", "call_local")
func end_phase_2():
	phase_over = true
	deactivate_players.rpc()
	boss_anim.play("angry")
	await get_tree().create_timer(2.0).timeout
	phase_3.rpc()


@rpc("authority", "call_local")
func phase_3():
	phase_over = false

	if not multiplayer.is_server():
		return

	unreverse_players.rpc()
	activate_players.rpc()

	boss_anim.play("patch")

	await get_tree().create_timer(1.0).timeout

	# Begin spawning homing bird waves
	start_bird_flocks()
	
func start_bird_flocks():
	# Initial burst
	var initial_count := calculate_wave_size()
	var initial_positions := get_bird_spawn_positions(initial_count)
	spawn_bird_wave.rpc(initial_positions)

	await get_tree().create_timer(3.0).timeout

	# While the boss is alive, keep spawning waves
	while boss_hp > 0 and not phase_over:
		var count := calculate_wave_size()
		var positions := get_bird_spawn_positions(count)
		spawn_bird_wave.rpc(positions)
		await get_tree().create_timer(4.0).timeout


@rpc("any_peer", "call_local")
func spawn_bird_wave(positions: Array):
	if phase_over:
		return
	for pos in positions:
		var bird := red_bird_scene.instantiate()
		bird.global_position = pos

		var bird_body := bird.get_node("AnimatableBody2D") as Node2D
		if bird_body:
			bird_body.add_to_group("red_bird_body")

		add_child(bird)

func get_bird_spawn_positions(count: int) -> Array:
	var positions: Array = []
	for i in count:
		positions.append(get_random_bird_spawn_point_front())
	return positions

func get_random_bird_spawn_point_front() -> Vector2:
	var boss_pos = CatBoss.global_position

	# Distance in front of the boss
	var min_dist := 500.0
	var max_dist := 750.0
	var dist := randf_range(min_dist, max_dist)

	# Vertical spread around the boss (up/down, but still "in front")
	var vertical_spread := 150.0
	var y_offset := randf_range(-vertical_spread, vertical_spread)

	# Front of boss = negative X direction from boss (to the left)
	var offset := Vector2(-dist, y_offset)

	return boss_pos + offset


#func get_random_bird_spawn_point() -> Vector2:
	#var radius := 500.0  # can tweak for larger arena
	#var angle := randf() * TAU
	#var offset := Vector2(cos(angle), sin(angle)) * radius
	#return CatBoss.global_position + offset

func calculate_wave_size() -> int:
	var max_hp: float = $CanvasLayer/BossHP.max_value
	var ratio := float(boss_hp) / max_hp

	if ratio > 0.50:
		return 3  # easier at start
	elif ratio > 0.25:
		return 4
	elif ratio > 0.10:
		return 5
	else:
		return 6  # final frenzy


# ----------------- Spike Rings -------------------
@rpc("any_peer", "call_local")
func spawn_spike_ring_at(index: int) -> void:
	if index < 0 or index >= spike_spawn_points.size():
		return

	var ring := spike_ring_scene.instantiate()
	ring.global_position = spike_spawn_points[index].global_position
	add_child(ring)
	
@rpc("any_peer", "call_local")
func spawn_all_spike_rings() -> void:
	for m in spike_spawn_points:
		var ring := spike_ring_scene.instantiate()
		ring.global_position = m.global_position
		add_child(ring)
# -------------------------------------------------

@rpc("any_peer")
func request_boss_hit(amount: float):
	if not multiplayer.is_server():
		return
	boss_take_damage.rpc(amount)

	
@rpc("authority", "call_local")
func boss_take_damage(amount: float):
	boss_hp -= amount
	boss_hp = max(0, boss_hp)
	$CanvasLayer/BossHP.value = boss_hp

	var max_hp: float = $CanvasLayer/BossHP.max_value
	var hp_ratio: float = float(boss_hp) / float(max_hp)

	# Death check first – always highest priority
	if boss_hp <= 0:
		phase_over = true
		deactivate_players.rpc()
		bg.stop()
		music.stop()
		boss_anim.play("angry")
		$CatDeath.play()
		await $CatDeath.finished
		spawn_explosions_over_time.rpc(5.0, 0.15)
		fade_to_white.rpc()
		await get_tree().create_timer(6.5).timeout
		trigger_win.rpc()
		return

	# Phase 2 threshold
	if not phase_2_entered and hp_ratio <= 2.0 / 3.0:
		phase_2_entered = true
		end_phase_1()

	# Phase 3 threshold
	if not phase_3_entered and hp_ratio <= 1.0 / 3.0:
		phase_3_entered = true
		end_phase_2()

@rpc("any_peer", "call_local")
func update_boss_hp(new_hp: int):
	boss_hp = new_hp
	$CanvasLayer/BossHP.value = boss_hp

@rpc("any_peer", "call_local", "reliable")
func spawn_players(p_array: PackedInt32Array) -> void:
	if p_array.size() < 2:
		push_error("spawn_players: need 2 peer IDs, got %d" % p_array.size())
		return

	var markers := [player1marker, player2marker]
	var tints := [Color.WHITE, Color.hex(0xE0FFFF)]

	for i in 2:
		var peer_id := p_array[i]
		var player := player_scene.instantiate()
		var sprite := player.get_child(0)
		player.name = str(peer_id)
		#player.modulate = tints[i]
		sprite.self_modulate = tints[i]
		player.global_position = markers[i].global_position
		player.set_multiplayer_authority(peer_id)
		pSpawner.add_child(player)
	players = pSpawner.get_children()


@rpc("authority", "call_local")
func spawn_single_explosion():
	var e := explosion_template.duplicate() as AnimatedSprite2D
	add_child(e)

	var rng := RandomNumberGenerator.new()
	var r = explosion_radius * sqrt(rng.randf())
	var theta := rng.randf_range(0.0, TAU)
	var offset := Vector2(r * cos(theta), r * sin(theta))

	e.global_position = CatBoss.global_position + offset
	e.rotation = rng.randf_range(0.0, TAU)
	e.scale = Vector2.ONE * rng.randf_range(0.85, 1.25)
	e.z_index = 10
	e.visible = true

	var anim := "explode"
	var frames := e.sprite_frames
	if frames and frames.has_animation(anim):
		var fps := frames.get_animation_speed(anim)
		var count := frames.get_frame_count(anim)
		if fps > 0 and count > 0:
			var length := float(count) / float(fps)
			e.speed_scale = length / 1.0

	e.frame = 0
	e.play(anim)
	$Boom.play()
	get_tree().create_timer(1.0).timeout.connect(func():
		if e:
			e.queue_free())

@rpc("any_peer", "call_local")
func spawn_explosions_over_time(total_time: float = 5.0, interval: float = 0.1):
	var time_left = total_time
	while time_left > 0:
		spawn_single_explosion()
		await get_tree().create_timer(interval).timeout
		time_left -= interval

@rpc("any_peer", "call_local")
func fade_to_white(duration: float = 5.0) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(white_fade, "color:a", 1.0, duration)

@rpc("authority", "call_local")
func trigger_win():
	popup.current_state = popup.LEVEL_STATE.COMPLETE
	popup.pause()
	
@rpc("authority", "call_local")
func trigger_lose():
	popup.current_state = popup.LEVEL_STATE.FAILED
	popup.pause()
	
@rpc("any_peer", "call_local")
func on_player_died():
	trigger_lose.rpc()

func on_boss_hit_by_laser():
	request_boss_hit.rpc(1.0)
