# Blas Antunez

# Script to animate the CatBoss character

extends CharacterBody2D

@onready var anim := $Anim

func play_idle():
	anim.play("no_patch")
	
func play_angry():
	anim.play("angry")
	
func play_patch():
	anim.play("patch")
	
func stop_anim():
	anim.stop()
