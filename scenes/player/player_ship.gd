extends CharacterBody2D

@onready var cooldown_timer = $CooldownTimer
@onready var sfx = $AudioStreamPlayer2D
@onready var sprite := $AnimatedSprite2D
@onready var muzzle_right := $MuzzleRight
@onready var muzzle_left  := $MuzzleLeft


@export var SPEED: float = 250.0
@export var disabled := false
@export var reversed := false
@export var Bullet = preload("res://scenes/player/Bullet.tscn")
@export var player_health : int = 100
var invincible := false

var ready_to_fire := true

func _ready() -> void:
	add_to_group("players")
	add_to_group("player_ships")
	$HP.max_value = player_health
	$HP.value = player_health
	Global.player_hit_by_turret.connect(lower_hp)
	Global.player_hit_by_spike.connect(lower_hp)
	Global.player_hit_by_bird.connect(lower_hp)



func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if disabled:
		return

	var x_direction := Input.get_axis("move left", "move right")
	var y_direction := Input.get_axis("move up", "move down")

	if reversed:
		x_direction = -x_direction
		y_direction = -y_direction

	var dir := Vector2(x_direction, y_direction)

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity.x = dir.x * SPEED
		velocity.y = dir.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.y = move_toward(velocity.y, 0.0, SPEED)

	if dir.x > 0:
		sprite.flip_h = false
	elif dir.x < 0:
		sprite.flip_h = true

	if Input.is_action_pressed("action") and ready_to_fire:
		ready_to_fire = false
		cooldown_timer.start()
		shoot.rpc()

	move_and_slide()


func lower_hp(id: int):
	if invincible:
		return
	if id != get_multiplayer_authority():
		return
	if multiplayer.is_server():
		apply_damage.rpc(10)


@rpc("any_peer", "call_local")
func apply_damage(amount: int):
	player_health -= amount
	player_health = max(player_health, 0)
	$HP.value = player_health
	
	if player_health <= 0:
		die()
		

func die():
	sprite.stop()
	sprite.self_modulate = Color(1,1,1)
	sprite.play("explosion")
	$Boom.play()
	await sprite.animation_finished
	Global.emit_signal("player_died")


@rpc("any_peer", "call_local")
func shoot():
	sfx.play()
	var b = Bullet.instantiate()
	if b:
		get_tree().get_current_scene().add_child(b)

		var muzzle := muzzle_right
		if sprite.flip_h:
			muzzle = muzzle_left

		b.transform = muzzle.global_transform


func _on_cooldown_timer_timeout() -> void:
	ready_to_fire = true
