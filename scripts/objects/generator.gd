extends Node2D

@onready var Sprite := $AnimatedSprite2D

func _ready() -> void:
	add_to_group("generators")
	Sprite.play("idle")
		
