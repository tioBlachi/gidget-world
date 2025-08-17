extends Node2D

signal all_cats_herded

var cats_left: int = 0

func _ready():
	cats_left = get_tree().get_nodes_in_group("cats").size()
	print(cats_left, " cats left to herd")
	
	for cat in get_tree().get_nodes_in_group("cats"):
		if cat.has_signal("herded") or cat.has_signal("escaped"):
			cat.connect("herded", Callable(self, "_on_cat_herded"))
			cat.connect("escaped", Callable(self, "_on_cat_escaped"))	


func _on_cat_herded() -> void:
	cats_left -= 1
	print(cats_left, " cats left to herd")
	
	if cats_left <= 0:
		emit_signal("all_cats_herded")
		# use this signal for the end level logic
		

func _on_cat_escaped() -> void:
	cats_left += 1
	print(cats_left, " cats left to herd")
	
