extends Node2D

var cats_left: int = 0

func _ready() -> void:
	add_to_group("herdingCats")
	cats_left = get_tree().get_nodes_in_group("cats").size()

	var mines = get_tree().get_nodes_in_group("mines")

	for mine in mines:
		if is_instance_valid(mine) and mine.has_signal("exploded"):
			mine.exploded.connect(Callable(self, "_on_mine_exploded"))
			

func _on_mine_exploded():
	print("A mine exploded!")
	get_tree().paused = true
	
# ----- Cat Counting -----
func _on_pen_body_entered(body: Node2D) -> void:
	if body.is_in_group("cats"):
		cats_left -= 1
		print(cats_left, " cats left to herd")
		if cats_left <= 0:
			print("All cats herded! You win!")
			get_tree().paused = true
			# TODO: implement level complete UI message


func _on_pen_body_exited(body: Node2D) -> void:
	if body.is_in_group("cats"):
		cats_left += 1
