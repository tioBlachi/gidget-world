extends Node

@export var column_delay_seconds: float = 1.0
@export var block_delay_seconds: float = 3.0
@export var auto_start: bool = true
@export var enable_startup_boost: bool = true
@export var startup_boost_multiplier: float = 20.0
@export var startup_boost_duration_seconds: float = 7.0

var _lane_spawners: Array = []
var _module
var _running: bool = false
var _speed_multiplier: float = 1.0
var _spawned_during_boost: Array = []

func _ready() -> void:
	_collect_lane_spawners()
	_disable_random_on_spawners()
	_module = load("res://scripts/CarSpawner/CarModule.gd").new()
	if auto_start:
		start()

func start() -> void:
	if _running:
		return
	_running = true
	if enable_startup_boost and startup_boost_multiplier > 1.0 and startup_boost_duration_seconds > 0.0:
		_speed_multiplier = startup_boost_multiplier
		var t := get_tree().create_timer(startup_boost_duration_seconds)
		t.timeout.connect(_on_startup_boost_end)
		_set_spawner_speed_multiplier(_speed_multiplier)
	_run_loop()

func stop() -> void:
	_running = false

func _on_startup_boost_end() -> void:
	_speed_multiplier = 1.0
	_set_spawner_speed_multiplier(1.0)
	_reset_boosted_car_speeds()

func _collect_lane_spawners() -> void:
	_lane_spawners.clear()
	for child in get_children():
		if child != null and child.has_method("spawn_fixed"):
			_lane_spawners.append(child)
	# exactly 3
	_lane_spawners.sort_custom(Callable(self, "_sort_by_y"))
	if _lane_spawners.size() != 3:
		push_warning("car_block_controller: expected 3 lane spawners with spawn_fixed() under this node")

func _sort_by_y(a, b) -> bool:
	return a.global_position.y < b.global_position.y

func _disable_random_on_spawners() -> void:
	for s in _lane_spawners:
		s.use_random_spawning = false

func _set_spawner_speed_multiplier(mult: float) -> void:
	for s in _lane_spawners:
		if "speed_multiplier" in s:
			s.speed_multiplier = mult

func _pick_pattern() -> Array:
	var patterns: Array = _module.all_patterns if _module != null else []
	if patterns.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return patterns[rng.randi_range(0, patterns.size() - 1)]

func _run_loop() -> void:
	await get_tree().process_frame
	while _running:
		var pattern: Array = _pick_pattern()
		if pattern.is_empty():
			await get_tree().create_timer(_effective_delay(block_delay_seconds)).timeout
			continue
		var num_rows := pattern.size()
		if num_rows < 3:
			await get_tree().create_timer(_effective_delay(block_delay_seconds)).timeout
			continue
		var num_cols := 0
		if num_rows > 0:
			num_cols = pattern[0].size()
		for col in range(num_cols):
			# For each column, check each lane 
			for row in range(3):
				if row < _lane_spawners.size() and col < pattern[row].size():
					var should_spawn = int(pattern[row][col]) == 1
					if should_spawn:
						var car = _lane_spawners[row].spawn_fixed()
						if car is MovingKillbox:
							# Record to normalize speed when boost ends
							_spawned_during_boost.append({
								"car": car,
								"normal_speed": _lane_spawners[row].car_speed
							})
			await get_tree().create_timer(_effective_delay(column_delay_seconds)).timeout
		await get_tree().create_timer(_effective_delay(block_delay_seconds)).timeout

func _effective_delay(base_seconds: float) -> float:
	var mult := _speed_multiplier
	if mult <= 1.0:
		return max(0.01, base_seconds)
	return max(0.01, base_seconds / mult)

func _reset_boosted_car_speeds() -> void:
	var remaining: Array = []
	for entry in _spawned_during_boost:
		if typeof(entry) == TYPE_DICTIONARY and entry.has("car") and entry.has("normal_speed"):
			var car = entry["car"]
			if is_instance_valid(car) and car is MovingKillbox:
				car.speed = float(entry["normal_speed"])
		
			if is_instance_valid(car):
				remaining.append(entry)
	_spawned_during_boost = remaining
