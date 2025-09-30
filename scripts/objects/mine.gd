extends Node2D

signal exploded

@export var outer_interval := 1.0
@export var inner_interval := 0.25

@onready var anim  := $AnimatedSprite2D
@onready var boom  := $Boom
@onready var b  := $Beep
@onready var timer := $BeepTimer
@onready var kill  := $KillZone
@onready var inner := $InnerWarning
@onready var outer := $OuterWarning

var triggered := false

func _ready() -> void:
	add_to_group("mines")
	
	anim.play("idle")
	
	timer.one_shot = false
	timer.timeout.connect(_on_timer)

	# warning zones
	inner.body_entered.connect(_on_zone_changed)
	inner.body_exited.connect(_on_zone_changed)
	outer.body_entered.connect(_on_zone_changed)
	outer.body_exited.connect(_on_zone_changed)

	# kill zone
	kill.body_entered.connect(_on_kill_entered)

func _on_timer() -> void:
	if b.playing:
		b.stop()
	b.play()

func _on_zone_changed(_b: Node2D) -> void:
	_refresh_beep()

func _set_anim(n: String) -> void:
	if anim.animation != n:
		anim.play(n)

func _refresh_beep() -> void:
	if triggered:
		_stop_beep()
		return

	if inner.has_overlapping_bodies():
		_set_interval(inner_interval)
		_set_anim("inner_warning")
	elif outer.has_overlapping_bodies():
		_set_interval(outer_interval)
		_set_anim("outer_warning")
	else:
		_stop_beep()
		_set_anim("idle")

func _any_body(a: Area2D) -> bool:
	for body in a.get_overlapping_bodies():
		if body.is_in_group("cats") or body.is_in_group("players"):
			return true
	return false


func _set_interval(sec: float) -> void:
	if not timer.is_stopped() and abs(timer.wait_time - sec) < 0.0001:
		return
	timer.wait_time = sec
	timer.start()

func _stop_beep() -> void:
	if not timer.is_stopped():
		timer.stop()
	if b.playing:
		b.stop()

func _on_kill_entered(body: Node2D) -> void:
	if triggered: return
	triggered = true

	$KillZone.set_deferred("monitoring", false)
	$InnerWarning.set_deferred("monitoring", false)
	$OuterWarning.set_deferred("monitoring", false)
	_stop_beep()

	_set_anim("explosion")
	boom.play()

	if is_instance_valid(body):
		if body.is_in_group("cats") or body.is_in_group("players"):
			body.queue_free()

	await anim.animation_finished
	anim.hide()
	
	emit_signal("exploded")
