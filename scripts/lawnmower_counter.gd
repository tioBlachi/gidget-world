extends Node2D

var keys_left = 3
@onready var score_label: Label = $CanvasLayer/score_label

func key_collected():
	keys_left = keys_left - 1
	score_label.text = "Keys remaining: " + str(keys_left)
	if keys_left <= 0:
		
		pass
	
