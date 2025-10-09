extends Node2D

@export var delay_seconds: float = 20.0
@export var rise_speed: float = 40.0

@onready var area: Area2D = $Area2D

var _active := false

func _ready() -> void:
	if not area.is_connected("body_entered", Callable(self, "_on_body_entered")):
		area.body_entered.connect(_on_body_entered)
	set_physics_process(false)
	if multiplayer.is_server():
		var t := get_tree().create_timer(delay_seconds)
		await t.timeout
		rpc("_begin")

@rpc("authority", "call_local", "reliable")
func _begin() -> void:
	_active = true
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	global_position.y -= rise_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	if body.is_in_group("players"):
		if body.has_method("die"):
			body.die()
		else:
			body.queue_free()
