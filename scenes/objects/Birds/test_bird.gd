#James Wilcox

extends Path2D

@export var loop = true
@export var speed = 2.0
@export var speed_scale = 1.0
@onready var path = $PathFollow2D
@onready var animation = $AnimationPlayer
@onready var body: AnimatableBody2D = $AnimatableBody2D
@onready var sprite: AnimatedSprite2D = $AnimatableBody2D/AnimatedSprite2D

var _prev_pos: Vector2 = Vector2.ZERO
var _prev_follow_pos: Vector2 = Vector2.ZERO

func _ready():
	if not loop:
		animation.play("Move")
		animation.speed_scale = speed_scale
		set_process(false)
	# Initialize previous position for facing flip
	_prev_pos = body.global_position
	_prev_follow_pos = path.global_position
		
func _process(delta):
	path.progress += speed
	# Flip facing based on the tangent direction (rotation) of the PathFollow2D
	var dir_x: float = cos(path.rotation)
	if absf(dir_x) > 0.0001:
		# flip when tangent points right
		sprite.flip_h = dir_x > 0.0
