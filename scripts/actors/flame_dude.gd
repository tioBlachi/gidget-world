extends CharacterBody2D

@onready var t = $Face/BlinkTimer
@onready var face = $Face
@onready var flames = $Flames

var blink_wait_time: float
var random_blink_time: float
var direction: float

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	t.timeout.connect(_on_timer_timeout)
	face.play("idle")
	flames.play("burning")
	random_blink_time = rng.randf_range(1.0, 3.0)
	t.autostart = true
	t.start(random_blink_time)

func _physics_process(delta: float) -> void:
	move_and_slide()

func _on_burn_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		print("A player touched FlameDude")

func _on_timer_timeout():
	face.play("blink")
	await face.animation_finished
	face.play("idle")
	set_new_blink()

func set_new_blink() -> void:
	random_blink_time = rng.randf_range(1.0, 3.0)
	t.start(random_blink_time)
