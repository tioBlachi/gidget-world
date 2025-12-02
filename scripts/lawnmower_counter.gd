extends Node2D

signal all_keys_collected

var keys_left = 3
@onready var score_label: Label = $CanvasLayer/score_label


func key_collected():
	keys_left = keys_left - 1
	score_label.text = "Keys remaining: " + str(keys_left)
	if keys_left <= 0:
		await get_tree().physics_frame
		emit_signal.call_deferred("all_keys_collected")
