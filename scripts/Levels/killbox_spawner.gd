extends Node2D

@export var car_scene: PackedScene
@export var car_scenes: Array[PackedScene] = []
@export var spawn_interval_min: float = 2.0
@export var spawn_interval_max: float = 6.0
@export var car_speed: float = 300.0
@export var car_speed_min: float = 100.0
@export var car_speed_max: float = 300.0
@export var car_despawn_x: float = -1200.0

# Anchor options: keep spawner 500px inside the right edge of the active camera
@export var anchor_to_camera_right: bool = true
@export var right_offset_px: float = -1500.0
@export var lock_y_to_camera_center: bool = false
@export var y_offset_px: float = 0.0

var _timer: Timer
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	if car_scene == null:
		push_warning("killbox_spawner: car_scene is not assigned")
	# Create a one-shot timer that we restart after each spawn with a new random delay
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_rng.randomize()
	_set_next_wait()
	_timer.start()
	_timer.timeout.connect(_on_timeout)

func _process(delta: float) -> void:
	if not anchor_to_camera_right:
		return
	var cam := _get_active_camera()
	if cam == null:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var half_width_world: float = (vp_size.x * 0.5) * cam.zoom.x
	var right_edge_world_x: float = cam.global_position.x + half_width_world
	global_position.x = right_edge_world_x - right_offset_px
	if lock_y_to_camera_center:
		global_position.y = cam.global_position.y + y_offset_px

func _get_active_camera() -> Camera2D:
	return get_viewport().get_camera_2d()

func _set_next_wait() -> void:
	var low = min(spawn_interval_min, spawn_interval_max)
	var high = max(spawn_interval_min, spawn_interval_max)
	low = max(0.1, low)
	high = max(low, high)
	_timer.wait_time = _rng.randf_range(low, high)

func _on_timeout() -> void:
	var scene_to_spawn: PackedScene = null
	if car_scenes.size() > 0:
		scene_to_spawn = car_scenes[_rng.randi_range(0, car_scenes.size() - 1)]
	else:
		scene_to_spawn = car_scene
	if scene_to_spawn == null:
		_set_next_wait()
		_timer.start()
		return
	var car = scene_to_spawn.instantiate()
	if car != null:
		if car is MovingKillbox:
			var min_s = min(car_speed_min, car_speed_max)
			var max_s = max(car_speed_min, car_speed_max)
			var picked_speed = _rng.randf_range(min_s, max_s)
			car.speed = picked_speed if picked_speed > 0.0 else car_speed
			car.despawn_x = car_despawn_x
		car.global_position = global_position
		if get_parent() != null:
			get_parent().add_child(car)
		else:
			get_tree().current_scene.add_child(car)
	_set_next_wait()
	_timer.start()
