extends AnimatableBody2D

@export var is_weak: bool = false
@export var weak_delay_seconds: float = 1.5
@export var weak_drop_distance: float = 48.0
@export var weak_recover_seconds: float = 1.5

enum MovementMode { NONE, LINEAR, CIRCULAR }
@export var movement_mode: MovementMode = MovementMode.NONE

# Linear movement
@export var speed: float = 100.0
@export var point_a: Vector2 = Vector2.ZERO
@export var point_b: Vector2 = Vector2.ZERO
@export var use_start_as_point_a: bool = true

# Circular movement
@export var circle_center: Vector2 = Vector2.ZERO
@export var use_start_as_circle_center: bool = false
@export var circle_radius: float = 64.0
@export var angular_speed_deg: float = 90.0
@export var start_angle_deg: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D
@onready var area_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D

var _origin_position := Vector2.ZERO
var _linear_target := Vector2.ZERO
var _last_pos := Vector2.ZERO
var _weak_in_progress := false
var _circle_angle_rad := 0.0
var _saved_collision_layer := 0
var _saved_collision_mask := 0

func _ready() -> void:
	_origin_position = global_position
	_last_pos = global_position
	# Ensure platform velocity updates before players so riders stick better
	process_priority = -20
	if use_start_as_point_a or point_a == Vector2.ZERO:
		point_a = global_position
	if point_b == Vector2.ZERO:
		point_b = point_a
	_linear_target = point_b

	if use_start_as_circle_center:
		circle_center = global_position
	elif circle_center == Vector2.ZERO:
		# Safety: if center wasn't set in the editor, keep the bird where it starts
		circle_center = global_position
	_circle_angle_rad = deg_to_rad(start_angle_deg)

	# Signals for weak trigger
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)
	# Ensure we detect players on layers 1 and 2 (player is on layer 1|2 -> 3)
	area.collision_mask = 3

	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _weak_in_progress:
		# Velocity for rider support during scripted motions
		_update_platform_velocity(delta)
		return

	match movement_mode:
		MovementMode.NONE:
			# Idle animation still plays; keep velocity clear
			constant_linear_velocity = Vector2.ZERO
		MovementMode.LINEAR:
			_update_linear_movement(delta)
		MovementMode.CIRCULAR:
			_update_circular_movement(delta)

	_update_platform_velocity(delta)

func _update_linear_movement(delta: float) -> void:
	var to_target: Vector2 = _linear_target - global_position
	var dist: float = to_target.length()
	if dist <= 0.5:
		# Snap and swap targets
		global_position = _linear_target
		_linear_target = point_a if _linear_target == point_b else point_b
		to_target = _linear_target - global_position
		dist = to_target.length()
	if dist > 0.0:
		var step: float = minf(speed * delta, dist)
		var delta_pos: Vector2 = to_target.normalized() * step
		global_position += delta_pos
		# Flip based on X motion only
		if abs(delta_pos.x) > 0.01:
			sprite.flip_h = delta_pos.x < 0.0

func _update_circular_movement(delta: float) -> void:
	var ang_speed: float = deg_to_rad(angular_speed_deg)
	_circle_angle_rad = wrapf(_circle_angle_rad + ang_speed * delta, -PI, PI)
	var new_pos: Vector2 = circle_center + Vector2(cos(_circle_angle_rad), sin(_circle_angle_rad)) * circle_radius
	var tangent: Vector2 = Vector2(-sin(_circle_angle_rad), cos(_circle_angle_rad))
	global_position = new_pos
	if abs(tangent.x) > 0.01:
		sprite.flip_h = tangent.x < 0.0

func _update_platform_velocity(delta: float) -> void:
	var new_pos: Vector2 = global_position
	var v: Vector2 = (new_pos - _last_pos) / maxf(delta, 1e-6)
	constant_linear_velocity = v
	_last_pos = new_pos

# ---------- Weak behavior ----------

var _bodies_on_top := {}

func _on_area_body_entered(body: Node) -> void:
	if not (body is Node2D):
		return
	if body.is_in_group("players"):
		_bodies_on_top[body.get_instance_id()] = body
		if is_weak and not _weak_in_progress:
			_start_weak_cycle()

func _on_area_body_exited(body: Node) -> void:
	_bodies_on_top.erase(body.get_instance_id())

func _start_weak_cycle() -> void:
	_weak_in_progress = true
	await _shake_for_seconds(weak_delay_seconds)
	# Drop: disable collisions so player falls through
	_set_colliders_enabled(false)
	# Wait one physics frame so the collision toggle is applied before moving
	await get_tree().physics_frame
	await _animate_vertical_offset(weak_drop_distance, 0.35)
	# Hang briefly at bottom so player fully clears
	await get_tree().create_timer(weak_recover_seconds).timeout
	# Rise back and re-enable colliders
	await _animate_vertical_offset(-weak_drop_distance, 0.45)
	_set_colliders_enabled(true)
	_weak_in_progress = false

func _set_colliders_enabled(enabled: bool) -> void:
	# Disable both physics collision and area detection for the weak phase
	if is_instance_valid(body_shape):
		body_shape.set_deferred("disabled", not enabled)
		# Also toggle body layers to guarantee CharacterBody2D loses the floor
		if enabled:
			set_deferred("collision_layer", _saved_collision_layer)
			set_deferred("collision_mask", _saved_collision_mask)
		else:
			_saved_collision_layer = collision_layer
			_saved_collision_mask = collision_mask
			set_deferred("collision_layer", 0)
			set_deferred("collision_mask", 0)
	if is_instance_valid(area):
		area.set_deferred("monitoring", enabled)
	if is_instance_valid(area_shape):
		area_shape.set_deferred("disabled", not enabled)

func _shake_for_seconds(duration: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var elapsed := 0.0
	var amp := 2.0
	while elapsed < duration:
		# Quick left-right jiggle of the sprite only
		tween.tween_property(sprite, "position:x", -amp, 0.05)
		tween.tween_property(sprite, "position:x", amp, 0.1)
		tween.tween_property(sprite, "position:x", 0.0, 0.05)
		await tween.finished
		elapsed += 0.2

func _animate_vertical_offset(offset: float, seconds: float) -> void:
	var start: Vector2 = position
	var target: Vector2 = start + Vector2(0, offset)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target, seconds)
	await tween.finished
