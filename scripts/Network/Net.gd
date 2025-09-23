extends Node

const NET_VERSION := "V1-min"

func _ready():
	print("Net autoloader ready. Version: ", 
	NET_VERSION, 
	" Server=", 
	multiplayer.is_server())
