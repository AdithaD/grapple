extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Join_Server_button_down():
	$ServerButtons.visible = false
	$ConnectPrompt.visible = true

func _on_Connect_button_down():
	get_node("/root/Main").join_server($ConnectPrompt/IPEntry.text)

func _on_Cancel_button_down():
	$ServerButtons.visible = true
	$ConnectPrompt.visible = false
