extends Node2D

@export var is_pressed := false
@export var targets: Array[NodePath] = []
@export var method_name: StringName = "activate"
@export var sprite_path: NodePath
@export var unpressed_texture: Texture2D
@export var pressed_texture: Texture2D

@onready var area: Area2D = $Area2D
@onready var click_sfx := get_node_or_null("ClickSound")
@onready var anim := get_node_or_null("AnimatedSprite2D")
@onready var sprite2d: Sprite2D = sprite_path if sprite_path != NodePath("") and has_node(sprite_path) else get_node_or_null("Sprite2D")

func _ready() -> void:
	if not area.is_connected("body_entered", Callable(self, "_on_body_entered")):
		area.body_entered.connect(_on_body_entered)
	if is_pressed:
		_apply_pressed_visuals()
	else:
		if sprite2d and unpressed_texture:
			sprite2d.texture = unpressed_texture

func _on_body_entered(body: Node2D) -> void:
	if is_pressed:
		return
	if not body.is_in_group("players"):
		return
	# Offline: press locally
	if multiplayer.multiplayer_peer == null:
		is_pressed = true
		_apply_pressed_visuals()
		_trigger_targets()
		return
	# Networked: ask server
	if multiplayer.is_server():
		_request_press()
	else:
		rpc_id(1, "_request_press")

@rpc("any_peer", "reliable")
func _request_press() -> void:
	if not multiplayer.is_server():
		return
	if is_pressed:
		return
	is_pressed = true
	rpc("_apply_pressed")
	_trigger_targets()

@rpc("authority", "call_local", "reliable")
func _apply_pressed() -> void:
	_apply_pressed_visuals()

func _apply_pressed_visuals() -> void:
	if anim:
		anim.play("pressed")
	if click_sfx:
		click_sfx.play()
	if sprite2d and pressed_texture:
		sprite2d.texture = pressed_texture

func _trigger_targets() -> void:
	for p in targets:
		var n := get_node_or_null(p)
		if n and n.has_method(method_name):
			n.call(method_name)
