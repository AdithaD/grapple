extends Camera

export var duration = 0.5
export (Vector3) var target_location

export var vertical_sensitivity = 1
export var invert = false

var current_tween = null

func _input(event):
	if(is_network_master() and current):
			# Rotates the camera based on mouse input
		if event is InputEventMouseMotion:
			var rotx = event.relative.y / get_viewport().size.y * vertical_sensitivity
			rotx = rotation_degrees.x - clamp(rotation_degrees.x + rotx, -90, 90)
			rpc("apply_rot_x", rotx)

remotesync func apply_rot_x(rotx):
		var final_rot_x = rotx if not invert else -rotx
		rotate_x(final_rot_x)


func switch_to_fpv():
	if(current_tween): 
		current_tween.stop_all()
		
	var other_camera = get_viewport().get_camera()

	global_transform.origin = other_camera.global_transform.origin
	global_transform.basis = other_camera.global_transform.basis

	var tween =  Tween.new()

	add_child(tween)
	tween.interpolate_property(self, "translation", translation, target_location, duration,Tween.TRANS_QUAD, Tween.EASE_IN)

	current = true
	current_tween = tween
	tween.start()
	
func switch_back(controller, other_camera):
	
		
	var tween =  Tween.new()

	tween.connect("tween_all_completed", controller, "_on_Tween_all_completed")

	add_child(tween)
	#tween.interpolate_property(self, "global_transform:origin", self.global_transform.origin, other_camera.global_transform.origin, duration,Tween.TRANS_QUAD, Tween.EASE_OUT)
	#tween.interpolate_property(self, "rotation", self.global_transform.basis, other_camera.global_transform.basis, duration,Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.follow_property(self, "global_transform:origin", self.global_transform.origin, other_camera, "global_transform:origin", duration,Tween.TRANS_QUAD, Tween.EASE_OUT)
	if(current_tween): 
		current_tween.stop_all()
	
	current_tween = tween
	tween.start()
