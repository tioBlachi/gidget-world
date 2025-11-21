extends Area2D

var speed := 750

func _ready() -> void:
	add_to_group("bullets")
	
func _physics_process(delta: float) -> void:
	position += transform.x * speed * delta
	

func _on_body_entered(body: Node2D) -> void:
	if body.name.begins_with("Cat"):
		Global.emit_signal("boss_hit")
	elif body.is_in_group("turrets"):
		Global.emit_signal("turret_hit")
	elif body.name.begins_with("Collision"):
		print("Shot at at spike")
		body.queue_free()
	queue_free()
