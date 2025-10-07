extends Node

var port := 8080
var ip := "54.82.169.128"

func _ready() -> void:
	Net.become_host(port)
	SceneManager.call_deferred("switch_scene","Title")
