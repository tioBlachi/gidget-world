# James Wilcox

extends StaticBody2D

@export var speed: float = 160.0
@export var use_start_as_origin := true
@export var origin: Vector2
@export var target: Vector2

var _active := false
var _prev_pos := Vector2.ZERO
var _goal := Vector2.ZERO

func _ready() -> void:
	if use_start_as_origin or origin == Vector2.ZERO:
		origin = global_position
	_goal = origin
	_prev_pos = global_position
	process_priority = -10
	set_physics_process(true)

func activate() -> void:
	if _active:
		return
	# Offline: activate locally
	if multiplayer.multiplayer_peer == null:
		_active = true
		_goal = target
		return
	if multiplayer.is_server():
		_active = true
		_goal = target
		rpc("_apply_active")
	else:
		rpc_id(1, "activate")

@rpc("authority", "call_local", "reliable")
func _apply_active() -> void:
	_active = true

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		var to_goal := _goal - global_position
		var dist := to_goal.length()
		if dist <= 0.5:
			global_position = _goal
		else:
			var step := speed * delta
			if step >= dist:
				global_position = _goal
			else:
				global_position += to_goal.normalized() * step

	var new_pos := global_position
	var v: Vector2 = (new_pos - _prev_pos) / max(delta, 1e-6)
	constant_linear_velocity = v
	_prev_pos = new_pos
