@tool
extends RayCast2D

signal collided_once(collider: Object)
signal finished()

@export var cast_speed := 7000.0
@export var max_length := 1400.0
@export var start_distance := 0.0
@export var appear_time := 0.10
@export var hold_time := 1.00 
@export var color := Color.AQUA : set = set_color

@export var is_casting := false : set = set_is_casting

var _tween: Tween
var _line: Line2D
var _line_width: float
var _hit_emitted := false

func _ready() -> void:
	_line = $Line2D
	_line_width = _line.width
	set_color(color)

	_line.points = [Vector2.RIGHT * start_distance, Vector2.ZERO]
	_line.visible = false

	collide_with_bodies = true
	collide_with_areas = true
	hit_from_inside = true
	exclude_parent = true

	if not Engine.is_editor_hint():
		set_physics_process(false)

func set_color(c: Color) -> void:
	color = c
	if _line:
		_line.modulate = c

func set_is_casting(v: bool) -> void:
	if is_casting == v:
		return
	is_casting = v
	set_physics_process(is_casting)

	if not _line:
		return

	if is_casting:
		_hit_emitted = false
		target_position = Vector2.ZERO
		_line.points[0] = Vector2.RIGHT * start_distance
		_line.points[1] = Vector2.RIGHT * start_distance
		appear()
	else:
		target_position = Vector2.ZERO
		disappear()

func appear() -> void:
	_line.visible = true
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_line, "width", _line_width, appear_time).from(0.0)

	enabled = true

	if not Engine.is_editor_hint():
		get_tree().create_timer(hold_time).timeout.connect(func():
			is_casting = false)

func disappear() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_line, "width", 0.0, appear_time * 0.8).from_current()
	_tween.tween_callback(func():
		_line.hide()
		enabled = false
		emit_signal("finished")
		queue_free()
	)

func _physics_process(delta: float) -> void:
	target_position.x = move_toward(target_position.x, max_length, cast_speed * delta)

	var p_end := target_position
	force_raycast_update()

	if is_colliding():
		p_end = to_local(get_collision_point())

		if not _hit_emitted:
			_hit_emitted = true
			var col := get_collider()
			emit_signal("collided_once", col)

	_line.points[1] = p_end
