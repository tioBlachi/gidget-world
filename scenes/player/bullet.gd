extends Area2D

signal boss_hit(body: Node2D)

var speed := 750

func _ready() -> void:
	add_to_group("bullets")
	
func _physics_process(delta: float) -> void:
	position += transform.x * speed * delta
	

func _on_body_entered(body: Node2D) -> void:
	if body.name.begins_with("Cat"):
		emit_signal("boss_hit", body)
		print("Cat hit")
	else:
		print(body.name, " hit")
	queue_free()
