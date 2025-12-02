extends StaticBody2D

# Blas Antunez

# Script to set up moving platforms in various levels
# It is also used on the blue bird at the end of urban uprising
# to fly the players to the level compete popup

signal ready_to_fly

@export var players_needed: int = 2
@export var speed: float = 160.0

@export var origin: Vector2
@export var max_pos: Vector2
@export var use_start_as_origin: bool = true

@export var ping_pong: bool = false

var has_emitted_ready := false

var _riders := {}
var _prev_pos := Vector2.ZERO
var _target := Vector2.ZERO

func _ready() -> void:
	if use_start_as_origin or origin == Vector2.ZERO:
		origin = global_position
	_target = origin
	_prev_pos = global_position
	process_priority = -10
	set_physics_process(true)

func _player_on_platform(body: Node2D) -> void:
	if body.is_in_group("players"):
		_riders[body.get_instance_id()] = body

func _player_left_platform(body: Node2D) -> void:
	_riders.erase(body.get_instance_id())

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		if ping_pong:
			_update_ping_pong(delta)
		else:
			_update_rider_gated(delta)

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
	if enough and not has_emitted_ready:
		has_emitted_ready = true
		emit_signal("ready_to_fly")
	_target = max_pos if enough else origin
	_move_toward_target(delta)

func _update_ping_pong(delta: float) -> void:
	var eps := 0.5
	if global_position.distance_to(origin) <= eps:
		_target = max_pos
	elif global_position.distance_to(max_pos) <= eps:
		_target = origin
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
