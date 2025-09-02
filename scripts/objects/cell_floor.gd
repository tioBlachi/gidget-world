extends RigidBody2D
'''
Mechanics for the cell floor in Lab 1-1
A random cell is designated flimsy
The player in that cell can jump 6 times 
to break the floor beneath them
'''

var is_flimsy = false
var jumps_needed = 4
var jump_count = 0
var is_open = false
var first_cell_open = false

func _ready():
	freeze = true


func count_jumps():
	if is_flimsy and not first_cell_open:
		jump_count += 1
		if jump_count >= jumps_needed:
			await get_tree().create_timer(1.0).timeout
			$OpenDoor.play()
			freeze = false
			first_cell_open = true
			
func unfreeze():
	if is_open:
		return
	is_open = true
	await get_tree().create_timer(0.75).timeout
	$OpenDoor.play()
	freeze = false
