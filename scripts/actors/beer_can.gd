extends Path2D

@export var speed: float = 0.1
@export var paused: bool
@onready var follower: PathFollow2D = $PathFollow2D
@onready var can_sprite: Sprite2D = $PathFollow2D/Sprite2D

func _ready() -> void:
	follower.rotates = true

func _process(delta: float) -> void:
	if not paused:
		follower.progress_ratio += delta * speed
		
		can_sprite.rotation = follower.rotation * 2
		#can_sprite.rotation = follower.rotation + deg_to_rad(90)
	
	if follower.progress_ratio >= 0.99:
		queue_free()
	
func _on_can_collides_with_player(body: Node2D) -> void:
	if body.is_in_group("players"):# or body.name.begins_with("Lowest"):
		print("Ouch!")
		queue_free()
