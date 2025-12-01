extends Node

@export var spawn_interval_min := 1.0
@export var spawn_interval_max := 2.5

var _lane_spawners: Array = []
var _rng := RandomNumberGenerator.new()

func _ready():
	# collect Lane0, Lane1, Lane2
	var parent := get_node("../LaneSpawners")
	for child in parent.get_children():
		if child.has_method("spawn_car"):
			_lane_spawners.append(child)

	_rng.randomize()

	# only the server controls spawning
	if multiplayer.is_server():
		_spawn_loop()

func _spawn_loop() -> void:
	await get_tree().process_frame

	while true:
		var dur = _rng.randf_range(spawn_interval_min, spawn_interval_max)
		await get_tree().create_timer(dur).timeout

		var lane = _rng.randi_range(0, _lane_spawners.size() - 1)
		rpc_spawn_car.rpc(lane)

@rpc("authority", "call_local")
func rpc_spawn_car(lane_index: int) -> void:
	if lane_index < 0 or lane_index >= _lane_spawners.size():
		return

	var lane = _lane_spawners[lane_index]
	lane.spawn_car()
