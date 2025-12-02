# Collin Whitney

# Script to update the score label in the game so players
# can see how many keys are left to collect. Emits a signal when
# all keys are collected

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
