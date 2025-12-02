# Jacob Ashmore

extends Area2D


@export var item_name: String = "Default Item"
@export var item_type: String = "Generic"
@export var sprite_texture: Texture2D:
	set(value):
		sprite_texture = value
		if $Sprite2D: # Assuming you have a Sprite2D child node
			$Sprite2D.texture = value
			
# Add @onready for a reference to the sprite if needed elsewhere
@onready var sprite_node: Sprite2D = $Sprite2D

func _ready():
	# Ensure the texture is applied when the scene runs
	if sprite_texture and $Sprite2D.texture == null:
		$Sprite2D.texture = sprite_texture
		
# Add a function to get item data
func get_item_data():
	return {"name": item_name, "type": item_type}
