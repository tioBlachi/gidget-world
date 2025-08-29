extends Node2D

var cats_left: int = 0

func _ready():
	cats_left = get_tree().get_nodes_in_group("cats").size()
	
	
func _on_pen_body_entered(body: Node2D) -> void:
	if body.is_in_group("cats"):
		cats_left -= 1
		print(cats_left, " cats left to herd")
	if cats_left <= 0:
		print("All cats herded! You win!")


func _on_pen_body_exited(body: Node2D) -> void:
	if body.is_in_group("cats"):
		cats_left += 1
