# Blas Antunez

# Simple script to be used with the AnimationPlayer 
# This player is only for cutscenes

extends CharacterBody2D

@onready var jump := $JumpSound

func play_jump():
	jump.play()
