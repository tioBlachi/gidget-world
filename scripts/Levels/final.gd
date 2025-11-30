extends Node2D

@onready var angry_meow := $AudioStreamPlayer2D

func play_angry_meow():
	angry_meow.play()
	
func _ready() -> void:
	$AnimationPlayer.play("RESET")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	SceneManager.switch_scene("Portal Fight")
	
