extends CharacterBody2D

@onready var sprite := $AnimatedSprite2D
@export var SPEED: float = 200.0
@export var disabled := false
@export var Bullet = preload("res://scenes/player/Bullet.tscn")
@onready var cooldown_timer = $CooldownTimer
@onready var sfx = $AudioStreamPlayer2D

var ready_to_fire := true

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not disabled:
		var x_direction = Input.get_axis("move left", "move right")
		var y_direction = Input.get_axis("move up", "move down")
		var dir = Vector2(x_direction, y_direction)

		if dir != Vector2.ZERO:
			dir = dir.normalized()
			velocity.x = dir.x * SPEED
			velocity.y = dir.y * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
			velocity.y = move_toward(velocity.y, 0.0, SPEED)

		if x_direction > 0:
			sprite.flip_h = false
			SPEED = 100.0
		elif x_direction < 0:
			sprite.flip_h = true
			SPEED = 200.0
		elif y_direction < 0 or y_direction > 0:
			#sprite.flip_h = true
			SPEED = 200.0
		if Input.is_action_pressed("action") && ready_to_fire:
			ready_to_fire = false
			cooldown_timer.start()
			shoot.rpc()
		move_and_slide()
			
@rpc("any_peer", "call_local")
func shoot():
	if sprite.flip_h:
		return
	sfx.play()
	var b = Bullet.instantiate()
	if b:
		var root = get_tree().root
		root.add_child(b)
		b.transform = $Muzzle.global_transform


func _on_cooldown_timer_timeout() -> void:
	ready_to_fire = true
