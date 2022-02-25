extends ProgressBar

var player

func _ready():
	GameState.connect("init_complete", self, "_on_Init_Complete")	
	

func _on_Init_Complete():
	var players = $"/root/Main/Players".get_children()
	for p in players:
		if(p.is_network_master()):
			player = p
			
	max_value = player.starting_health
	value = player.current_health
	
	player.connect("on_damage", self, "_on_Player_Damage")	

func _on_Player_Damage():
	value = player.current_health
