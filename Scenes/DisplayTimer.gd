extends Label

export (NodePath) var timer_path

var timer

func _ready():
	timer = get_node(timer_path)
	pass

func _process(_delta):
	text = String(timer.time_left)
