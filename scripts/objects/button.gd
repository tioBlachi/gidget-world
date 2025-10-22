extends Node2D

@export var is_pressed := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D
@onready var click_sfx := $ClickSound

func _ready():
	if not area.is_connected("body_entered", Callable(self, "_on_body_entered_local")):
		area.body_entered.connect(_on_body_entered_local)
	if is_pressed:
		_apply_pressed_visuals()

func _on_body_entered_local(body: Node2D) -> void:
	if not body.is_in_group("players"):
		return
	if is_pressed:
		return
	var pid := body.name.to_int() if body.name.is_valid_int() else body.get_multiplayer_authority()
	print("Player: ", pid, " pressed the button")
	if multiplayer.is_server():
		rpc_request_press(pid)
	else:
		rpc_id(1, "rpc_request_press", pid)

@rpc("any_peer", "reliable")
func rpc_request_press(_pid: int):
	if not multiplayer.is_server():
		return
	if is_pressed:
		return
	is_pressed = true
	rpc("rpc_apply_pressed")
	_release_other_floors()

@rpc("authority", "call_local", "reliable")
func rpc_apply_pressed():
	_apply_pressed_visuals()

func _apply_pressed_visuals():
	anim.play("pressed")
	click_sfx.play()

func _release_other_floors():
	for flr in get_tree().get_nodes_in_group("cell_floor"):
		if flr is RigidBody2D and not flr.is_flimsy and not flr.is_open:
			flr.rpc("rpc_unfreeze")
