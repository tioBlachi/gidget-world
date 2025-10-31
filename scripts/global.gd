extends Node


signal player_died
signal alligator_triggered_bite
func trigger_alligator_bite():
	alligator_triggered_bite.emit()
