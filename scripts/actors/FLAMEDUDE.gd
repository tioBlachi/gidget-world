extends Path2D

@export var speed: float = 0.2
@export var min_ratio: float = 0.01
@export var max_ratio: float = 0.99
@export var is_big_flame: bool = false
@onready var follower: PathFollow2D = $PathFollow2D

@onready var dude: CharacterBody2D = $PathFollow2D/FlameDude
@onready var face: AnimatedSprite2D = $PathFollow2D/FlameDude/Face
@onready var flames: AnimatedSprite2D = $PathFollow2D/FlameDude/Flames
@onready var blink_timer: Timer = $PathFollow2D/FlameDude/Face/BlinkTimer
var dir := 1
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	face.play("idle")
	flames.play("burning")

	_restart_blink_timer()

	follower.progress_ratio = clampf(follower.progress_ratio, min_ratio, max_ratio)
	dir = 1

func _process(delta: float) -> void:
	follower.progress_ratio += delta * speed * dir
	
	if dir == 1:
		dude.scale.x = 1
	else:
		dude.scale.x = -1
		
	if follower.progress_ratio >= max_ratio:
		follower.progress_ratio = max_ratio
		dir = -1
	elif follower.progress_ratio <= min_ratio:
		follower.progress_ratio = min_ratio
		dir = 1
		
func _on_burn_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		print("A player touched FlameDude")
		queue_free()
		
func _on_blink_timer_timeout() -> void:
	face.play("blink")
	await face.animation_finished
	face.play("idle")
	_restart_blink_timer()
	
func _restart_blink_timer() -> void:
	blink_timer.start(rng.randf_range(1.0, 3.0))
		
