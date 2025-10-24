extends Node2D

signal portal_defeated

@onready var portal_sprite = $Sprite2D
@onready var mat = portal_sprite.material
@onready var timer: Timer = $Timer
@onready var explosion_template: AnimatedSprite2D = $Explosions
@onready var boom: AudioStreamPlayer2D = $Boom

@export var explosion_radius = 250.0
@export var explosions_total = 7
@export var boom_interval = 0.7

var explosions_started = false

var colors = [Color.WHITE, Color.AQUA, Color.FOREST_GREEN, Color.ORANGE, Color.RED, Color.RED ]
var phase:= 0

func _ready() -> void:
	mat.set_shader_parameter("color_a", colors[phase])

	timer.wait_time = 1.0
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
func _process(delta: float) -> void:
	match phase:
		0:
			mat.set_shader_parameter("tightness", 12.0)
			mat.set_shader_parameter("color_a", colors[phase])
			mat.set_shader_parameter("speed", 0.1)
			mat.set_shader_parameter("border_color", Color.BLACK)
			mat.set_shader_parameter("border_softness", 0.0)
		1:
			mat.set_shader_parameter("tightness", 12.0)
			mat.set_shader_parameter("color_a", colors[phase])
			mat.set_shader_parameter("speed", 1.0)
			mat.set_shader_parameter("border_color", Color.BLACK)
			mat.set_shader_parameter("border_softness", 0.0)
		2:
			mat.set_shader_parameter("tightness", 8.0)
			mat.set_shader_parameter("color_a", colors[phase])
			mat.set_shader_parameter("speed", 2.0)
			mat.set_shader_parameter("border_color", Color.BLACK)
			mat.set_shader_parameter("border_softness", 0.0)
		3:
			mat.set_shader_parameter("tightness", 4.0)
			mat.set_shader_parameter("color_a", colors[phase])
			mat.set_shader_parameter("speed", 3.0)
			mat.set_shader_parameter("border_color", Color.BLACK)
			mat.set_shader_parameter("border_softness", 0.0)
		4:
			mat.set_shader_parameter("tightness", 2.0)
			mat.set_shader_parameter("color_a", colors[phase])
			mat.set_shader_parameter("speed", 4.0)
			mat.set_shader_parameter("border_color", Color.RED)
			mat.set_shader_parameter("border_softness", 0.1)
		5:
			mat.set_shader_parameter("tightness", 0.0)
			mat.set_shader_parameter("color_a", colors[phase])
			mat.set_shader_parameter("speed", 0.0)
			
	if phase == 5 and not explosions_started:
		explosions_started = true
		await get_tree().create_timer(1).timeout
		$Rumble.play()
		emit_signal("portal_defeated")
		start_explosions()
			
func _on_timer_timeout() -> void:
	phase += 1
	if phase >= colors.size():
		phase = 0
	if phase == 5:
		timer.stop()
		
func start_explosions():
	for i in range(explosions_total):
		boom.play()
		get_tree().current_scene.start_screen_shake(20.0, 0.15)
		spawn_explosions(boom_interval)
		await get_tree().create_timer(1).timeout
		
func spawn_explosions(duration: float):
	var e := explosion_template.duplicate() as AnimatedSprite2D
	
	var rng := RandomNumberGenerator.new()
	var r = explosion_radius * sqrt(rng.randf())
	var theta := rng.randf_range(0.0, TAU)
	e.position = Vector2(r * cos(theta), r * sin(theta))
	e.rotation = rng.randf_range(0.0, TAU)
	e.scale = Vector2.ONE * rng.randf_range(0.85, 1.25)
	e.z_index = 10
	e.visible = true
	add_child(e)
	
	var anim := "explode" 
	var frames := e.sprite_frames
	if frames and frames.has_animation(anim):
		var fps := frames.get_animation_speed(anim)
		var count := frames.get_frame_count(anim)
		if fps > 0 and count > 0:
			var original_len := float(count) / float(fps)
			if original_len > 0.0:
				e.speed_scale = original_len / duration
				
	e.frame = 0
	e.play(anim)
	
	await get_tree().create_timer(duration).timeout
	e.queue_free()
