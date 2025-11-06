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
	
func _on_can_collides_with_player(player: Node2D) -> void:
	if player.is_in_group("players"):
		const DROP_SPEED := 900.0
		
		player.velocity.x = 0
		
		while not player.is_on_floor():
			player.velocity.y = DROP_SPEED
			await get_tree().physics_frame
			
		player.staggered = true	
		player.dizzy()
		rpc("despawn_can")
		
@rpc("call_local", "any_peer")
func despawn_can():
	queue_free()
