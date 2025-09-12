extends Area2D

class_name MovingKillbox

@export var speed: float = 400.0
@export var despawn_x: float = -3000.0
@export var auto_free_on_kill: bool = false

func _ready() -> void:
	# Ensure the hitbox kills players on contact
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Move left every frame
	global_position.x -= speed * delta
	# Despawn once we cross the left boundary
	if global_position.x <= despawn_x:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Treat anything named Player* as lethal target
	if body is CharacterBody2D and body.name.begins_with("Player"):
		body.queue_free()
		if auto_free_on_kill:
			queue_free()
