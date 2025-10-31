extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var mouth_area: Area2D = $MouthArea

# Tracks if the player is inside the mouth
var player_in_mouth: Node = null

# Timing for fake bite cycle
@export var fake_bite_interval := 3.0 # seconds between bites
@export var fake_bite_randomness := 2.0 # adds some randomness
var bite_timer := 0.0

func _ready():
	# Connect to the global signal to allow external triggering
	Global.alligator_triggered_bite.connect(bite)
	# Start idle animation on load
	anim.play("idle")
	# Start fake bite cycle
	_reset_fake_bite_timer()

func _process(delta: float) -> void:
	# Countdown timer for fake bites
	bite_timer -= delta
	if bite_timer <= 0 and not anim.is_playing():
		fake_bite()
		_reset_fake_bite_timer()

# --- 🪱 FUNCTION: FAKE BITE ---
func fake_bite() -> void:
	print("🐊 Fake bite triggered!")
	anim.play("bite")
	await anim.animation_finished
	anim.play("idle")
	if player_in_mouth:
		_kill_player(player_in_mouth)

# --- 🪱 FUNCTION: REAL BITE (for traps or triggers) ---
func bite() -> void:
	print("💥 Real bite triggered!")
	anim.play("bite")
	await anim.animation_finished
	anim.play("idle")


# --- 🔧 HELPER: Reset timer ---
func _reset_fake_bite_timer() -> void:
	bite_timer = fake_bite_interval + randf() * fake_bite_randomness

# --- ⚙️ Mouth area detection ---
func _on_body_entered(body: Node) -> void:
	print("Body entered mouth area")
	if body.is_in_group("players"):
		player_in_mouth = body

func _on_body_exited(body: Node) -> void:
	print("Body exited mouth area")
	if body == player_in_mouth:
		player_in_mouth = null



# --- 💀 Kill player (you can replace this with your own death logic) ---
func _kill_player(player: Node) -> void:
	print("💀 Player got chomped by the alligator!")
	if player_in_mouth:
		player.die() # or call your custom death method
 


func _on_mouth_area_body_entered(body: Node2D) -> void:
	print("Body entered mouth area")
	if body.is_in_group("players"):
		player_in_mouth = body


func _on_mouth_area_body_exited(body: Node2D) -> void:
	print("Body exited mouth area")
	if body == player_in_mouth:
		player_in_mouth = null
