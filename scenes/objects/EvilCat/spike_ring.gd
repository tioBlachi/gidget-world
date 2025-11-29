extends Node2D

@onready var spikes_pivot: Node2D = $Spikes

@export var ring_radius: float = 60.0
@export var move_speed: float = 150.0
@export var spin_speed: float = 2.0   # radians per second

func _ready() -> void:
	# Arrange existing SpikeBall children in a ring
	var spike_balls := spikes_pivot.get_children()
	var count := spike_balls.size()
	if count == 0:
		return

	for i in count:
		var angle := TAU * float(i) / float(count)  # even spacing
		var offset := Vector2(cos(angle), sin(angle)) * ring_radius
		var ball := spike_balls[i]
		ball.position = offset


func _physics_process(delta: float) -> void:
	# Everyone moves and spins the ring identically.
	# Physics collisions are calculated per-peer anyway.
	position.x -= move_speed * delta      # drift left toward players
	spikes_pivot.rotation += spin_speed * delta
