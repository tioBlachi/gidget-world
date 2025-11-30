extends AnimatableBody2D

@export var speed: float = 40.0
@export var use_start_as_origin := true
@export var origin: Vector2
@export var target: Vector2
@export var activation_delay: float = 0.0
@export var size_width: float = 64.0 : set = _set_size_width
@export var size_height: float = 16.0 : set = _set_size_height
@export var loop_ping_pong: bool = false
@export var fall_on_touch_enabled: bool = false
@export var return_when_unloaded: bool = false

var _active := false
var _prev_pos := Vector2.ZERO
var _goal := Vector2.ZERO
var _fall_origin_y := 0.0
var _rider_count := 0

@onready var _col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var _rider_area: Area2D = get_node_or_null("RiderArea")
@onready var _rider_shape: CollisionShape2D = _rider_area.get_node_or_null("CollisionShape2D") if _rider_area else null

func _ready() -> void:
	if use_start_as_origin or origin == Vector2.ZERO:
		origin = global_position
	_goal = origin
	_prev_pos = global_position
	process_priority = -10
	set_physics_process(true)
	_fall_origin_y = origin.y
	_apply_size()
	if _rider_area:
		if not _rider_area.is_connected("body_entered", Callable(self, "_on_rider_entered")):
			_rider_area.body_entered.connect(_on_rider_entered)
		if not _rider_area.is_connected("body_exited", Callable(self, "_on_rider_exited")):
			_rider_area.body_exited.connect(_on_rider_exited)

func activate() -> void:
	if _active:
		return
	# Offline: activate locally (with optional delay)
	if multiplayer.multiplayer_peer == null:
		if activation_delay > 0.0:
			var t := get_tree().create_timer(activation_delay)
			await t.timeout
		_active = true
		_goal = target
		return
	if multiplayer.is_server():
		if activation_delay > 0.0:
			await get_tree().create_timer(activation_delay).timeout
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
		if loop_ping_pong:
			var eps := 0.5
			if global_position.distance_to(origin) <= eps:
				_goal = target
			elif global_position.distance_to(target) <= eps:
				_goal = origin
			_move_toward_goal(delta)
		elif _active:
			_move_toward_goal(delta)

		if fall_on_touch_enabled:
			if _rider_count > 0:
				global_position.y += speed * delta
			elif return_when_unloaded and global_position.y > _fall_origin_y:
				global_position.y = max(_fall_origin_y, global_position.y - speed * delta)

	var new_pos := global_position
	var v: Vector2 = (new_pos - _prev_pos) / max(delta, 1e-6)
	constant_linear_velocity = v
	_prev_pos = new_pos

func _move_toward_goal(delta: float) -> void:
	var to_goal := _goal - global_position
	var dist := to_goal.length()
	if dist <= 0.5:
		global_position = _goal
		return
	var step := speed * delta
	if step >= dist:
		global_position = _goal
	else:
		global_position += to_goal.normalized() * step

func _apply_size() -> void:
	if _col_shape and _col_shape.shape and _col_shape.shape is RectangleShape2D:
		_col_shape.shape.size = Vector2(size_width, size_height)
	if _rider_shape and _rider_shape.shape and _rider_shape.shape is RectangleShape2D:
		_rider_shape.shape.size = Vector2(size_width, size_height)

func _set_size_width(v: float) -> void:
	size_width = v
	if is_inside_tree():
		_apply_size()

func _set_size_height(v: float) -> void:
	size_height = v
	if is_inside_tree():
		_apply_size()

func _on_rider_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		_rider_count += 1

func _on_rider_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		_rider_count = max(0, _rider_count - 1)
