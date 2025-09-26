extends Control

var default_ip := "localhost"
var default_port := 8080

var my_player_index := -1
var connected: bool = false

@onready var ip_input := $Panel/InputVBox/IPInput
@onready var port_input := $Panel/InputVBox/PortInput
@onready var start_button := $Panel/ButtonVBox/StartButton
@onready var join_button := $Panel/ButtonVBox/JoinButton

func _ready():
	if ip_input:
		ip_input.text = default_ip
	if port_input:
		port_input.text = str(default_port)
	if start_button:
		start_button.disabled = true
		
	if join_button and not join_button.pressed:
		pass
