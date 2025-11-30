extends Path2D

@export var chase_speed: float = 150.0
@export var detect_radius: float = 320.0
@export var horizontal_only: bool = false

@onready var body: AnimatableBody2D = $AnimatableBody2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var follow: PathFollow2D = $PathFollow2D
@onready var sprite: AnimatedSprite2D = $AnimatableBody2D/AnimatedSprite2D

func _ready() -> void:
	# Disable path/remote transform driven motion; we drive the body directly.
	if is_instance_valid(anim) and anim.is_playing():
		anim.stop()
	if is_instance_valid(follow) and follow.has_node("RemoteTransform2D"):
		follow.get_node("RemoteTransform2D").set_process(false)


	# Make all body contacts lethal via an Area2D overlay (non-blocking)
	var kill_area := Area2D.new()
	kill_area.name = "KillAreaAll"
	kill_area.monitoring = true
	kill_area.monitorable = false
	kill_area.collision_layer = 0
	kill_area.collision_mask = 1
	body.add_child(kill_area)
	# Reuse main collision shape geometry
	if body.has_node("CollisionShape2D"):
		var base_shape: CollisionShape2D = body.get_node("CollisionShape2D")
		var dup := CollisionShape2D.new()
		dup.shape = base_shape.shape
		dup.position = base_shape.position
		dup.rotation = base_shape.rotation
		dup.scale = base_shape.scale
		kill_area.add_child(dup)
	kill_area.body_entered.connect(_on_kill_body)

	set_physics_process(true)

func _physics_process(delta: float) -> void:
	var target := _get_nearest_player()
	if target == null:
		return
	var delta_vec: Vector2 = target.global_position - body.global_position
	if horizontal_only:
		var dx: float = delta_vec.x
		var abs_dx: float = absf(dx)
		if abs_dx > detect_radius:
			return
		if abs_dx > 1.0:
			var step_h: float = minf(chase_speed * delta, abs_dx)
			var move_vec_h: Vector2 = Vector2(sign(dx) * step_h, 0.0)
			body.global_position += move_vec_h
			if abs(move_vec_h.x) > 0.01:
				# Default sprite faces left; flip when moving right
				sprite.flip_h = move_vec_h.x > 0.0
	else:
		var dist: float = delta_vec.length()
		if dist > detect_radius:
			return
		if dist > 1.0:
			var step: float = minf(chase_speed * delta, dist)
			var move_vec: Vector2 = delta_vec.normalized() * step
			body.global_position += move_vec
			if abs(move_vec.x) > 0.01:
				# Default sprite faces left; flip when moving right
				sprite.flip_h = move_vec.x > 0.0

func _get_nearest_player() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for n in get_tree().get_nodes_in_group("players"):
		if n is Node2D:
			var d := body.global_position.distance_to(n.global_position)
			if d < best:
				best = d
				nearest = n
	return nearest

#func _on_kill_body(hit: Node) -> void:
	#if hit.is_in_group("players") and hit.has_method("die"):
		#hit.die()
func _on_kill_body(hit: Node) -> void:
	if not hit.is_in_group("players"):
		return

	if not multiplayer.is_server():
		return

	if hit.is_in_group("player_ships"):# or hit.is_in_group("players"):
		var peer_id := hit.get_multiplayer_authority()
		Global.player_hit_by_bird.emit(peer_id)
		queue_free()
		return

	# Default behavior for other levels/players
	if hit.has_method("die"):
		hit.die()
