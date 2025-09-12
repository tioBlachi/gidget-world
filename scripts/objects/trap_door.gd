extends StaticBody2D

@onready var anim = $AnimationPlayer

@export var is_dropped = false

func drop_floor():
	if is_dropped:
		return
	is_dropped = true
	anim.play("drop")
	
@rpc("authority", "call_local", "reliable")
func rpc_drop():
	drop_floor()
