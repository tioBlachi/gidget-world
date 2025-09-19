# moving_platform.gd
extends AnimatableBody2D

@export var players_needed: int = 2
@export var speed: float = 160.0              # pixels/sec along the segment

# Endpoints (set per platform in the Inspector)
@export var origin: Vector2
@export var max_pos: Vector2
@export var use_start_as_origin: bool = true  # auto-fill origin from starting position

# NEW: Ping-pong mode (ignore riders and go back/forth forever)
@export var ping_pong: bool = false
#@export var dwell_time: float = 0.0           # pause at each end (seconds), 0 = no pause

# Internals
var _riders := {}                              # instance_id -> Node2D
var _prev_pos := Vector2.ZERO
var _target := Vector2.ZERO
#var _dwell_left := 0.0

func _ready() -> void:
	if use_start_as_origin or origin == Vector2.ZERO:
		origin = global_position
	_target = origin
	_prev_pos = global_position
	process_priority = -10                     # update before players
	set_physics_process(true)

# keep your existing connections to these:
func _player_on_platform(body: Node2D) -> void:
	if body.is_in_group("players"):
		_riders[body.get_instance_id()] = body

func _player_left_platform(body: Node2D) -> void:
	_riders.erase(body.get_instance_id())

func _physics_process(delta: float) -> void:
	# ---- Decide target for THIS frame (server only) ----
	if multiplayer.is_server():
		if ping_pong:
			_update_ping_pong(delta)
		else:
			_update_rider_gated(delta)

	# ---- Report actual velocity on ALL peers so riders stick ----
	var new_pos := global_position
	var actual_v = (new_pos - _prev_pos) / max(delta, 1e-6)
	constant_linear_velocity = actual_v
	_prev_pos = new_pos

	# Stop tiny jitter at ends when we’re basically at target
	if new_pos.distance_to(_target) <= 0.5 and (ping_pong or _riders.size() < players_needed):
		constant_linear_velocity = Vector2.ZERO


# ----- Movement strategies -----

func _update_rider_gated(delta: float) -> void:
	# Move toward max_pos if enough riders, else back to origin.
	var enough := _riders.size() >= players_needed
	_target = max_pos if enough else origin
	_move_toward_target(delta)

func _update_ping_pong(delta: float) -> void:
	# Optional dwell pause at ends
	#if _dwell_left > 0.0:
		#_dwell_left -= delta
		#return

	# If we’re at (or very near) an end, set the opposite as new target & maybe dwell
	var eps := 0.5
	if global_position.distance_to(origin) <= eps:
		_target = max_pos
		#if dwell_time > 0.0:
			#_dwell_left = dwell_time
			#return
	elif global_position.distance_to(max_pos) <= eps:
		_target = origin
		#if dwell_time > 0.0:
			#_dwell_left = dwell_time
			#return

	_move_toward_target(delta)

func _move_toward_target(delta: float) -> void:
	var to_target := _target - global_position
	var dist := to_target.length()
	if dist <= 0.5:
		global_position = _target
		return
	var step := speed * delta
	if step >= dist:
		global_position = _target
	else:
		global_position += to_target.normalized() * step
