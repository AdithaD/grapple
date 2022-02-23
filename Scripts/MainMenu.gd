extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	GameState.connect("connection_succeeded", self, "_connection_success")
	GameState.connect("connection_failed", self, "_connection_failed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _connection_success():
	get_tree().change_scene_to(load("res://Scenes/Lobby.tscn"))
	pass
	
func _connection_failed():
	$Multiplayer/MultiplayerOptions/ErrorText.text = "Connection Failed."

func _on_SingleplayerButton_button_down():
	get_tree().change_scene("res://Scenes/world.tscn")


func _on_MultiplayerButton_button_down():
	$Buttons.visible = false
	$Multiplayer.visible = true


func _on_HostButton_button_down():
	GameState.host_game($Multiplayer/MultiplayerOptions/PlayerName/PlayerNameEdit.text, $Multiplayer/MultiplayerOptions/Host/LobbyName/LobbyNameEdit.text)
	get_tree().change_scene_to(load("res://Scenes/Lobby.tscn"))

func _on_JoinButton_button_down():
	var ip = $Multiplayer/MultiplayerOptions/Join/Control/IPEdit.text
	if ip.is_valid_ip_address():
		GameState.join_game($Multiplayer/MultiplayerOptions/PlayerName/PlayerNameEdit.text, ip)
	else:
		$Multiplayer/MultiplayerOptions/ErrorText.text = "Invalid IP address"
	
	pass # Replace with function body.
