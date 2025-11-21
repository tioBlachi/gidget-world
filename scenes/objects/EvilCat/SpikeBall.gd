extends Area2D

@export var spin_speed: float = 10.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	rotation += spin_speed * delta


func _on_body_entered(body: Node) -> void:
	# Only the server decides damage to players
	if not multiplayer.is_server():
		return

	if body.is_in_group("players"):
		var hit_peer_id := body.get_multiplayer_authority()
		Global.player_hit_by_spike.emit(hit_peer_id)
		# Optional: spike disappears when it hits a player
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	# Bullet vs spike ball collision
	if area.is_in_group("bullets"):
		# This visual behavior is safe to run on all peers
		area.queue_free()
		queue_free()
