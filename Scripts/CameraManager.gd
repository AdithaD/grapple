extends Spatial

func _ready():
	if is_network_master():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		$Pivot/ThirdPersonCamera.make_current()

func _process(_delta):
	if Input.is_action_just_pressed("aim"):
		$FirstPersonCamera.switch_to_fpv()
		pass
	if Input.is_action_just_released("aim"):
		$FirstPersonCamera.switch_back(self, $Pivot/ThirdPersonCamera)
		pass

func _on_Tween_all_completed():
	$Pivot/ThirdPersonCamera.current = true
