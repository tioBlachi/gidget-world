extends Node2D

@export var car_scene: PackedScene

func spawn_car():
	if car_scene == null:
		push_warning("LaneSpawner missing car_scene!")
		return null

	var car = car_scene.instantiate()
	car.global_position = global_position
	get_tree().current_scene.add_child(car)
	return car
