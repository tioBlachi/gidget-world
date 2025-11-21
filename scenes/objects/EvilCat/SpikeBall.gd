extends Area2D

@export var spin_speed: float = 10.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	
func _physics_process(delta: float) -> void:
	rotation += spin_speed * delta
	
	
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("players"):
		return

	if multiplayer.is_server():
		var hit_peer_id := body.get_multiplayer_authority()
		Global.player_hit_by_spike.emit(hit_peer_id)
	queue_free()
	
func _on_area_entered(area: Area2D) -> void:
	# Bullet vs spike ball collision
	if area.is_in_group("bullets"):
		area.queue_free()
		queue_free()
