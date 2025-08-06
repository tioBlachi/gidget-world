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
		# Keep position floating above player
		var bob_height = 2.0
		var bob_speed = 4.0
		position = Vector2(0, -24 + sin(Time.get_ticks_msec() / 200.0) * bob_height)


func _on_body_entered(body):
	print("Something touched me! Eww")
	if collected:
		return

	if body.name.begins_with("Player"):
		collected = true
		holder = body

		# Re-parent the keycard so it's now a child of the player
		get_parent().remove_child(self)
		holder.add_child(self)

		# Position above player
		position = Vector2(64, -24)

		# Tell the player they have it (optional)
		if holder.has_method("pickup_keycard"):
			$collect_sfx.play()
			holder.pickup_keycard(self)
