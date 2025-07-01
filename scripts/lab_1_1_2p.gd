extends Node2D


@onready var cell1 = $LabCell1/CellFloor
@onready var cell2 = $LabCell2/CellFloor
@onready var player1 = $Player
@onready var player2 = $Player2
# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	randomize()
	
	var choice = randi() % 2
	if choice == 0:
		cell1.is_flimsy = true
		player1.cell_floor = cell1
	else:
		cell2.is_flimsy = true
		player2.cell_floor = cell2
