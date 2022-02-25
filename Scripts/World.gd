extends Node

enum State {STARTING, PLAYING, FINISHED}

export var countdown_duration = 5

func _ready():
	$StartCountdown.wait_time = countdown_duration

func start_game():
	# Freeze all players 
	var players = $Players.get_children()
	for p in players:
		p.rpc("freeze")

	$StartCountdown.start()

func _on_StartCountdown_timeout():
	var players = $Players.get_children()
	for p in players:
		p.rpc("unfreeze")
		
	$UI/CountdownLabel.visible = false
