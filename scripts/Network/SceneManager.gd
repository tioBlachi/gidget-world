extends Node

const SCENES: Dictionary = {
	"Herding Cats": "res://scenes/Levels/herding_cats.tscn",
	"Lab Escape": "res://scenes/Levels/lab-escape.tscn",
	"Urban Uprising": "res://scenes/Levels/urban_uprising.tscn",
	"Car Dodge": "res://scenes/Levels/carDodge.tscn",
	"Main Menu": "res://scenes/UI/MainMenu.tscn"
}

# Map peer_id -> true (or later: a small player info struct)
# maybe make this a simple Array ?
var PLAYERS: Dictionary = {}

func _enter_tree() -> void:
	# Ensure Net is connected as early as possible.
	var net := get_node_or_null("/root/Net")
	if net:
		_wire_net(net)
	else:
		call_deferred("_try_wire_net")

func _try_wire_net() -> void:
	var net := get_node_or_null("/root/Net")
	if net:
		_wire_net(net)
	else:
		push_error("[SceneManager] Net autoload not found. Check AutoLoad order (Net must be above SceneManager).")

func _wire_net(net: Node) -> void:
	if not net.player_connected.is_connected(_on_player_connected):
		net.player_connected.connect(_on_player_connected)
	if not net.player_disconnected.is_connected(_on_player_disconnected):
		net.player_disconnected.connect(_on_player_disconnected)

	# Seed any already-present players (covers dedicated server that auto-hosted).
	if "players" in net:
		PLAYERS.clear()
		for id in net.players:
			PLAYERS[id] = true
		print("[SceneManager] Seeded players: ", PLAYERS)

func _on_player_connected(id: int) -> void:
	PLAYERS[id] = true
	print("[SceneManager] Player joined: %d" % id)

func _on_player_disconnected(id: int) -> void:
	PLAYERS.erase(id)
	print("[SceneManager] Player left: %d" % id)

func load_level(scene_name: String) -> void:
	var path = SCENES.get(scene_name, "")
	if path == "":
		push_error("[SceneManager] Unknown scene name: %s" % scene_name)
		return

	print("The selected level path is: ", path)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("[SceneManager] Failed to load %s (err=%d)" % [path, err])

# Try to remember to use this to get the player ids for player spawining
func get_player_ids() -> Array:
	return PLAYERS.keys()
