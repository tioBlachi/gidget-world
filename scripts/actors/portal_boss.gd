# Blas Antunez

# This script was once the code for the orginal final boss idea until scrapped.
# Now used for the portal animation in FinalCutScene

extends Node2D

@onready var portal_sprite = $Sprite2D
#@onready var mat = portal_sprite.material
@onready var mat: ShaderMaterial = (portal_sprite.material as ShaderMaterial)
@onready var timer: Timer = $Timer
@onready var explosion_template: AnimatedSprite2D = $Explosions
@onready var boom: AudioStreamPlayer2D = $Boom
@onready var pull_zone := $PortalPullZone




var colors = [Color.WHITE, Color.AQUA, Color.FOREST_GREEN, Color.ORANGE, Color.RED, Color.RED ]
@export var phase: int

#func _ready() -> void:
	#mat.set_shader_parameter("color_a", colors[phase])
#
	#timer.wait_time = 1.0
	#timer.one_shot = false
	#timer.timeout.connect(_on_timer_timeout)
	#$Sprite2D/AnimatedSprite2D.play("idle")
	##timer.start()
	#phase = 0
	


func _ready() -> void:
	# On dedicated/headless servers, skip all visual work
	if OS.has_feature("server") or DisplayServer.get_name() == "headless":
		return

	if mat == null:
		var sh: Shader = preload("res://scenes/actors/PortalBoss.gdshader")
		mat = ShaderMaterial.new()
		mat.shader = sh
		portal_sprite.material = mat
	else:
		mat = mat.duplicate() as ShaderMaterial
		portal_sprite.material = mat
	phase = 1
	

	
func _physics_process(delta: float) -> void:
	#for id in pulled.keys():
		#var p = pulled[id]
		#if not is_instance_valid(p):
			#pulled.erase(id)
			#continue
			#
		#var to_center = global_position - p.global_position
		#var dist = to_center.length()
		#
		#if dist < 0.5:
			#continue
			#
		#var dir = to_center / dist
		#var step = min(pull_speed * delta, dist)
		#p.global_position += dir * step
		#
	pass
	
func _process(_delta: float) -> void:
	#if OS.has_feature("server") or DisplayServer.get_name() == "headless":
		#return
	if mat == null:
		return 

	match phase:
		0:
			_set_mat(12.0, colors[phase], 0.1, Color.BLACK, 0.0)
		1:
			_set_mat(12.0, colors[phase], 3.0, Color.BLACK, 0.0)
		2:
			_set_mat(8.0,  colors[phase], 2.0, Color.BLACK, 0.0)
		3:
			_set_mat(4.0,  colors[phase], 3.0, Color.BLACK, 0.0)
		4:
			_set_mat(2.0,  colors[phase], 4.0, Color.BLACK, 0.1)
		5:
			mat.set_shader_parameter("tightness", 0.0)
			mat.set_shader_parameter("color_a", colors[phase])
			mat.set_shader_parameter("speed", 0.0)
			$Sprite2D/AnimatedSprite2D.stop()

func _set_mat(tight: float, col: Color, spd: float, bcol: Color, bsoft: float) -> void:
	mat.set_shader_parameter("tightness", tight)
	mat.set_shader_parameter("color_a", col)
	mat.set_shader_parameter("speed", spd)
	mat.set_shader_parameter("border_color", bcol)
	mat.set_shader_parameter("border_softness", bsoft)

			
func _on_timer_timeout() -> void:
	phase += 1
	if phase >= colors.size():
		phase = 0
	if phase == 5:
		timer.stop()		


#func _on_portal_pull_zone_body_entered(body: Node2D) -> void:
	#if body.is_in_group("players") or body.is_in_group("cats"):
		#pulled[body.name] = body
#
#func _on_portal_pull_zone_body_exited(body: Node2D) -> void:
	#if pulled.has(body.name):
		#pulled.erase(body.name)
#
#
#func _on_kill_zone_body_entered(body: Node2D) -> void:
	#if body.is_in_group("players"):
		#dying[body.name] = body
		#await get_tree().create_timer(1.5).timeout
		#if dying.has(body.name):
			#body.die.rpc()
	#elif body.is_in_group("cats"):
		#emit_signal("cat_engulfed", body)
#
#
#func _on_kill_zone_body_exited(body: Node2D) -> void:
	#if body.is_in_group("players"):
		#dying.erase(body.name)
