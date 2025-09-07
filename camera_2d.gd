extends Camera2D

@export var players: Array[NodePath]  # assign Player1, Player2, ..., PlayerX in inspector
@export var min_zoom: float = 1.0     # closest zoom in
@export var max_zoom: float = 2.0     # furthest zoom out
@export var margin: float = 200.0     # space around players
@export var zoom_speed: float = 5.0   # smoothing for zoom
@export var move_speed: float = 5.0   # smoothing for position

# NOTE: campera limits were set manually using the inspector and the ruler tool in
# the scene to find the top, bottom, left and right limits 
# need to find a way to make this dynamic for every scene so we do not need 
# to manually do this for every level

func _ready():
	var spawned_players = get_tree().get_nodes_in_group("players")
	for p in spawned_players:
		print(p)

func _process(delta: float) -> void:
	if players.size() == 0:
		return

	# Get player positions
	var positions: Array[Vector2] = []
	for path in players:
		var player = get_node_or_null(path)
		if player:
			positions.append(player.global_position)

	if positions.size() == 0:
		return

	# Find bounding box around players
	var min_x = positions[0].x
	var max_x = positions[0].x
	var min_y = positions[0].y
	var max_y = positions[0].y

	for pos in positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)

	var center = Vector2((min_x + max_x) / 2, (min_y + max_y) / 2)

	# Move camera smoothly to center
	global_position = lerp(global_position, center, delta * move_speed)

	# Calculate needed zoom to fit all players
	var screen_size = get_viewport_rect().size
	var dist_x = max_x - min_x + margin
	var dist_y = max_y - min_y + margin

	var zoom_x = dist_x / screen_size.x
	var zoom_y = dist_y / screen_size.y
	var target_zoom = clamp(max(zoom_x, zoom_y), min_zoom, max_zoom)

	# Smooth zoom
	var current_zoom = zoom.x
	var new_zoom = lerp(current_zoom, target_zoom, delta * zoom_speed)
	zoom = Vector2(new_zoom, new_zoom)
