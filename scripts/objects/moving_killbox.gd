extends Area2D

@export var speed: float = 300.0
@export var despawn_x: float = -700.0

func _physics_process(delta: float) -> void:
	global_position.x -= speed * delta
	if global_position.x < despawn_x:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.die()
