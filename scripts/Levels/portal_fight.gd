extends Node2D

@onready var bg := $Background
@onready var CatBoss := $CatBoss
@onready var boss_anim := $CatBoss/Anim
@onready var player1marker := $PlayerMarkers/Player1Marker
@onready var player2marker := $PlayerMarkers/Player2Marker
@onready var pSpawner := $pSpawner
@onready var player_scene = preload("res://scenes/player/PlayerShip.tscn")
# Boss is dead stuff
@onready var white_fade: ColorRect = $Fader/WhiteFade
@onready var explosion_template: AnimatedSprite2D = $Explosions
@export var explosion_radius = 150.0
@export var explosions_total = 7
@export var boss_hp := 10;

func _ready() -> void:
	bg.play("default")
	$CanvasLayer/BossHP.value = boss_hp
	if multiplayer.is_server():
		spawn_players.rpc(Net.players)
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		boss_take_damage.rpc(1)

@rpc("any_peer", "call_local")
func boss_take_damage(amount: float):
	boss_hp -= amount
	boss_hp = max(0, boss_hp)
	$CanvasLayer/BossHP.value = boss_hp
	if boss_hp <= 0:
		bg.stop()
		boss_anim.play("angry")
		spawn_explosions_over_time.rpc(5.0, 0.12)
		fade_to_white.rpc()
		await get_tree().create_timer(6.5).timeout
		# TODO: End Credit transition
		

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
		player.name = str(peer_id)
		player.modulate = tints[i]
		player.global_position = markers[i].global_position
		player.set_multiplayer_authority(peer_id)
		pSpawner.add_child(player)


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
			e.speed_scale = length / 1.0  # 1 second explosion by default

	e.frame = 0
	e.play(anim)

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
