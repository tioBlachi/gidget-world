extends CharacterBody2D

@onready var jump := $JumpSound

func play_jump():
	jump.play()
