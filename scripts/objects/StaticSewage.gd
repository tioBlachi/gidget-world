extends Area2D

@export var kill_any_character: bool = false

func _ready() -> void:
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var offline := multiplayer.multiplayer_peer == null
	if not (offline or multiplayer.is_server()):
		return
	var should_kill := body.is_in_group("players") or (kill_any_character and body is CharacterBody2D)
	if should_kill:
		if body.has_method("die"):
			body.die()
		else:
			body.queue_free()
