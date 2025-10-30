extends Node2D

@export var find_time := 3.0
@export var aim_delay := 0.5
@export var lock_time := 1.0
@export var rotate_speed_deg := 180.0
@export var beam_range := 1500.0
@export var start_distance := 0.0
@export var laser_ray_scene: PackedScene

const SPRITE_UP_OFFSET := -PI / 2.0

@onready var barrel: Marker2D = $BarrelTip

# --- States ---
@export var activated = false
var target: Node2D = null
var target_pos := Vector2.ZERO
var elapsed := 0.0
var finding := true
var charging := false
var firing := false

func _ready() -> void:
	randomize()
	_enter_find()

func _physics_process(delta: float) -> void:
	if activated:
		if finding:
			_do_find(delta)
		elif charging:
			_do_charge(delta)

# -------------------- STATES --------------------

func _do_find(delta: float) -> void:
	elapsed += delta

	if not is_instance_valid(target):
		_pick_target()

	if is_instance_valid(target):
		var desired := (target.global_position - global_position).angle() + SPRITE_UP_OFFSET
		var diff := wrapf(desired - rotation, -PI, PI)
		var step := deg_to_rad(rotate_speed_deg) * delta
		rotation += clamp(diff, -step, step)

	if elapsed >= find_time:
		target_pos = target.global_position if is_instance_valid(target) else (barrel.global_position + Vector2.DOWN * 200.0)
		_enter_charge()

func _do_charge(delta: float) -> void:
	elapsed += delta
	var start := barrel.global_position
	var v := (target_pos - start)
	if v == Vector2.ZERO:
		v = Vector2.DOWN
	var dir := v.normalized()
	rotation = dir.angle() + SPRITE_UP_OFFSET

	if elapsed >= aim_delay:
		_enter_fire()

func _enter_find() -> void:
	finding = true
	charging = false
	firing = false
	elapsed = 0.0
	_pick_target()

func _enter_charge() -> void:
	finding = false
	charging = true
	firing = false
	elapsed = 0.0

func _enter_fire() -> void:
	finding = false
	charging = false
	firing = true
	elapsed = 0.0

	var start := barrel.global_position
	var v := (target_pos - start)
	if v == Vector2.ZERO: v = Vector2.DOWN
	var dir := v.normalized()

	rotation = dir.angle() + SPRITE_UP_OFFSET

	if laser_ray_scene == null:
		_enter_find()
		return

	var laser := laser_ray_scene.instantiate()
	get_tree().current_scene.add_child(laser)

	laser.global_position = start
	laser.rotation = dir.angle()

	laser.set("max_length", beam_range)
	laser.set("start_distance", start_distance)
	laser.set("hold_time", lock_time)

	if laser.has_signal("collided_once"):
		laser.connect("collided_once", Callable(self, "_on_laser_hit"))
	if laser.has_signal("finished"):
		laser.connect("finished", Callable(self, "_on_laser_finished"))
	else:
		get_tree().create_timer(lock_time).timeout.connect(Callable(self, "_on_laser_finished"))

	laser.set("is_casting", true)

# -------------------- UTIL --------------------
func _pick_target() -> void:
	if not multiplayer.is_server():
		return
		
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		target = null
		return
		
	var new_target = players[randi() % players.size()]
	rpc_set_target.rpc(new_target)

func _on_laser_hit(collider: Object) -> void:
	if collider and collider is Node:
		var n := collider as Node
		if n.is_in_group("players"):
			print("Player: ", n.name, " hit!")
			n.staggered = true
			await get_tree().create_timer(1).timeout
			n.die.rpc()
		elif n.is_in_group("generators"):
			print("Hitting :", n.name)

func _on_laser_finished() -> void:
	_enter_find()
	
@rpc("authority", "call_local", "reliable")
func rpc_set_target(player: Node2D):
	target = player
	target_pos = player.global_position
