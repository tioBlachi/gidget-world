extends Node2D

@onready var sprite = $AnimatedSprite2D
@onready var original_position = position
@export var press_offset = Vector2(0, 3)

var is_pressed = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not is_pressed and body.name.begins_with("Player"):
		$AnimatedSprite2D.play("pressed")
		$ClickSound.play()
		is_pressed = true
		
		# Open all non-flimsy floors in cell_floor group
		for floor in get_tree().get_nodes_in_group("cell_floor"):
			if floor is RigidBody2D and not floor.is_flimsy and not floor.is_open:
				floor.call_deferred("unfreeze")
