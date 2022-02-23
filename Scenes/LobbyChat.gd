extends Control

var messages = []

remote func distribute_message(id, message):
	if id != 1:
		append_peer_message(GameState.players[id], message)

	for player_id in GameState.players:
		if player_id != id:
			rpc_id(player_id, "append_peer_message", GameState.players[player_id], message)
	pass

func _on_SendButton_button_down():
	var message_text = $SendMessage/MessageEdit.text
	if message_text != "":
		var uid = get_tree().get_network_unique_id()
		if uid != 1:
			rpc_id(1, "distribute_message", get_tree().get_network_unique_id(), message_text)
		else:
			distribute_message(1, message_text)
		
		append_own_message(message_text)
		$SendMessage/MessageEdit.text = ""

func append_own_message(message_text):
	var format = "[color=#0e87eb]\n [b][You][/b]: %s[/color]"
	$ChatLogArea/ChatLog.append_bbcode(format % message_text)
	
remote func append_peer_message(name, message_text):
	var format = "[color=#e8992a]\n [b][%s][/b]: %s[/color]"
	$ChatLogArea/ChatLog.append_bbcode(format % [name, message_text])
