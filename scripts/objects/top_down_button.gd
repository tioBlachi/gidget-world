extends Node2D

signal button_pressed
signal button_released

@onready var button := $AnimatedSprite2D

@export var pressed := false


func _ready() -> void:
	add_to_group("buttons")
	button.play("idle")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		pressed = true
		button.play("activated")
		$ClickSound.play()
		emit_signal("button_pressed")


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		pressed = false
		if button.is_playing():
			button.stop()
		button.play("idle")
		$ClickSound.play()
		emit_signal("button_released")

@rpc("authority", "call_local", "reliable")
func turn_off_collision():
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	
