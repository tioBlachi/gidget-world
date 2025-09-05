extends Node2D

@export var car_scene: PackedScene
@export var spawn_position: Vector2
@export var spawn_interval_seconds: float = 3.0
@export var car_speed: float = 400.0
@export var car_despawn_x: float = -1000.0

var _timer: Timer

func _ready() -> void:
	if car_scene == null:
		push_warning("killbox_spawner: car_scene is not assigned")
		return
	_timer = Timer.new()
	_timer.wait_time = max(0.1, spawn_interval_seconds)
	_timer.autostart = true
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)

func _on_timeout() -> void:
	if car_scene == null:
		return
	var car = car_scene.instantiate()
	if car == null:
		return
	# If this is our MovingKillbox, configure its speed and despawn boundary
	if car is MovingKillbox:
		car.speed = car_speed
		car.despawn_x = car_despawn_x
	car.global_position = spawn_position
	get_tree().current_scene.add_child(car)
