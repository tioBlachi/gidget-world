extends RigidBody2D

@export var is_flimsy := false
@export var jumps_needed := 4
@export var is_open := false

var jump_count := 0


func _ready():
	freeze = true
	if is_open:
		set_deferred("freeze", false)

func count_jumps_local():
	if is_flimsy and not is_open:
		jump_count += 1
		if jump_count >= jumps_needed:
			rpc("rpc_unfreeze")
# optional helper if you want to call locally (not used by server path)
@rpc("authority", "call_local", "reliable")
func rpc_unfreeze():
	if is_open:
		return
	is_open = true
	call_deferred("_apply_unfreeze")

func _apply_unfreeze():
	$OpenDoor.play()
	set_deferred("freeze", false)
	if has_node("PinJoint2D"):
		$"PinJoint2D".queue_free()
