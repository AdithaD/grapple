extends Spatial

export var vertical_sensitivity = 1
export var invert = false
func _input(event):
	if(is_network_master()):
			# Rotates the camera based on mouse input
		if event is InputEventMouseMotion:
			var rotx = event.relative.y / get_viewport().size.y * vertical_sensitivity
			rotx = rotation_degrees.x - clamp(rotation_degrees.x + rotx, -90, 90)
			rpc("apply_rot_x", rotx)

remotesync func apply_rot_x(rotx):
		var final_rot_x = rotx if not invert else -rotx
		rotate_x(final_rot_x)
