extends Area2D

signal lab_door_opened

#@export var requires_keycard = true

var is_open = false

func open_door():
	if not is_open:
		is_open = true
		$AnimatedSprite2D.play("opening")
		$LabDoorOpenSfx.play()
		emit_signal("lab_door_opened")
			
		
func _on_body_entered(body):
	if body.name.begins_with("Player"):
		print("Player has touched the door")
		if is_open or (body.has_keycard == true):
			open_door()
			body.queue_free()
	
