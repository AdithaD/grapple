extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.


func _player_list_changed():
	for child in $LobbyDialog/Players/Names.get_children():
		child.queue_free()
	
	var your_label = Label.new()
	your_label.text = GameState.player_name + " (You)"
	$LobbyDialog/Players/Names.add_child(your_label)
	
	for player in GameState.get_player_list():
		var label = Label.new()
		label.text = player
		$LobbyDialog/Players/Names.add_child(label)
	
func _ready():
	GameState.connect("player_list_changed", self, "_player_list_changed")
	$LobbyDialog/LobbyName.text = GameState.lobby_name
	
	$LobbyDialog/StartButton.disabled = not get_tree().is_network_server()
	_player_list_changed()


func _on_StartButton_button_down():
	GameState.begin_game()
