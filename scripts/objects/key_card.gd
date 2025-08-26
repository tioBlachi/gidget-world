extends Area2D

var collected := false
var holder: Node = null  # The player holding it


func _ready():
	var door = get_node("../LabExitDoor")
	if door:
		print("Waiting for door signal")
		door.connect("lab_door_opened", _on_door_opened)
	
	
func _on_door_opened():
	queue_free()


func _process(delta: float) -> void:
	if collected and holder:
		# Keep position floating in front of player
		var bob_height = 2.0
		var bob_speed = 4.0
		var x_offset = 90 if holder.facing_right else -90
		var y_offset = -50
		position = Vector2(x_offset, y_offset + sin(Time.get_ticks_msec() / 200.0) * bob_height)


func _on_body_entered(body):
	if not collected:
		print("Keycard grabbed by: ", body.name)
	if collected:
		return

	if body.name.begins_with("Player"):
		collected = true
		holder = body

		# Re-parent the keycard so it's now a child of the player
		get_parent().remove_child(self)
		holder.add_child(self)

		
		if holder.has_method("pickup_keycard"):
			$collect_sfx.play()
			holder.pickup_keycard(self)
