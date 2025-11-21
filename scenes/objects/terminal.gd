extends StaticBody2D

signal cat_entered

@onready var sprite := $AnimatedSprite2D

func _ready() -> void:
	sprite.play("deactivated")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("cats"):
		emit_signal("cat_entered")
		body.queue_free()
		sprite.play("actvated")
		
