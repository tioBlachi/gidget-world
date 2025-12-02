extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var mouth_area: Area2D = $MouthArea

# Change from a single Node reference to an Array of Nodes
var players_in_mouth: Array[Node] = []

# ... (Timing variables remain the same) ...
@export var fake_bite_interval := 3.0 
@export var fake_bite_randomness := 2.0 
var bite_timer := 0.0

func _ready():
	# Connect to the global signal to allow external triggering
	if Global:
		Global.alligator_triggered_bite.connect(bite)
		
	anim.play("idle")
	_reset_fake_bite_timer()

func _process(delta: float) -> void:
	bite_timer -= delta
	if bite_timer <= 0 and not anim.is_playing():
		fake_bite()
		_reset_fake_bite_timer()

# --- 🪱 FUNCTION: FAKE BITE ---
func fake_bite() -> void:
	print("🐊 Fake bite triggered!")
	# The bite should kill ALL players currently in the mouth
	_process_bite_logic.rpc()


# --- 🪱 FUNCTION: REAL BITE (for traps or triggers) ---

func bite() -> void:
	print("💥 Real bite triggered!")
	# The real bite should also kill ALL players currently in the mouth
	_process_bite_logic.rpc()
	
# --- 🔧 HELPER: Centralized Bite Logic ---
@rpc("any_peer", "call_local")
func _process_bite_logic() -> void:
	anim.play("bite")
	await anim.animation_finished
	anim.play("idle")
	


# --- 🔧 HELPER: Reset timer ---
func _reset_fake_bite_timer() -> void:
	bite_timer = fake_bite_interval + randf() * fake_bite_randomness
	
	
func _animation_kill() -> void:
	for player in players_in_mouth.duplicate():
		_kill_player(player)


func _kill_player(player: Node) -> void:
	# Use is_instance_valid for safety
	
	if is_instance_valid(player):
		print("💀 Player got chomped by the alligator!")
		player.die.rpc() 
		# Remove the player from our tracking array after killing them
		if players_in_mouth.has(player):
			players_in_mouth.erase(player)


# --- ⚙️ Mouth area detection (UPDATED FOR ARRAY) ---
func _on_mouth_area_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("players") and not players_in_mouth.has(body):
		# Add player to the list if they aren't already tracked
		players_in_mouth.append(body)
		print("Body entered mouth area. Players tracked: ", players_in_mouth.size())


func _on_mouth_area_body_exited(body: Node2D) -> void:
	
	if players_in_mouth.has(body):
		# Remove player from the list
		players_in_mouth.erase(body)
		print("Body exited mouth area. Players tracked: ", players_in_mouth.size())
