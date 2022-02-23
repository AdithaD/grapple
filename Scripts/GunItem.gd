extends "Item.gd"

export var damage  = 50
export var fire_rate = 2
export var max_fire_range = 100

var drop_scene

func _ready():
	$FireTimer.wait_time = 1 / fire_rate

func use():
	if $FireTimer.is_stopped():
		# Project a ray from the screen through the crosshair
		
		var camera = get_viewport().get_camera()
		
		var center = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
		var from = camera.project_ray_origin(center)
		var to = from + camera.project_ray_normal(center) * 100
		var space_state = get_world().direct_space_state
		var camera_result = space_state.intersect_ray(from, to, [], 0b1)
		
		if(camera_result):
			print("camera_hit")
			
			# Project a ray from the player's hand to the hit point.
			var global_tip_pos = $Tip.global_transform.origin
			var result = space_state.intersect_ray(global_tip_pos, global_tip_pos + (camera_result.position - global_tip_pos) * max_fire_range, [self], 0b1)
			
			#Where it hits grapple to it.
			if(result):
				print("player_hit")
				print(result.collider)
				shoot(result.collider)
		
		$FireTimer.start()
		rpc("play_effects")
	
func shoot(target):
	if (target.has_method("take_damage")):
		print(target.get_name())
		target.rpc_id(int(target.get_name()), "take_damage", damage)
		$HitSound.play()
		
remotesync func play_effects():
	$FireSound.play()

	
	
