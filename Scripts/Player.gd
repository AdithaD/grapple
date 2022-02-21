extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (PackedScene) var debug_ball

export var sensitivity = 1

export var speed = 10
export var sprint_multiplier = 2

export var fall_acceleration = 10
export var air_move_force = 4

export var jump_impulse = 8

export var grapple_acceleration = 70
export var max_grapple_speed = 60
export var max_grapple_distance = 100
var grappling = false
var grapple_point = Vector3.ZERO

export var starting_health: int  = 100
var current_health := starting_health

var falling = false
export var fall_damage_cutoff_velocity = 10
export var fall_damage_factor = 2.4

var velocity = Vector3.ZERO
var last_vel = Vector3.ZERO

signal on_damage
signal on_death

var current_item = null
var items = []

func _input(event):
	if(is_network_master()):
			# Rotates the camera based on mouse input
		if event is InputEventMouseMotion:
			var roty = event.relative.x / get_viewport().size.x * sensitivity
			
			var rotx = event.relative.y / get_viewport().size.y * sensitivity
			
			
			rotx = $Pivot.rotation_degrees.x - clamp($Pivot.rotation_degrees.x + rotx, -90, 90)
			
			rpc("apply_rotation", rotx, roty)
		

remotesync func apply_rotation(rotx, roty):
	$Pivot.rotate_x(rotx)
	rotate_y(-roty)

func _ready():
	print("p")
	# Set players camera as the main
	if is_network_master():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		$Pivot/Camera.make_current()


func _physics_process(delta):
	if(is_network_master()):
		look_move(delta)
		actions(delta)

func look_move(delta):
	var direction = Vector3.ZERO
	
	# Basic Keyboard Movement
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	
	if direction != Vector3.ZERO:
			direction = direction.normalized();
	
	if(is_on_floor()):
		if(falling):
			falling = false
			take_fall_damage()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	
		# Rotates the velocity vector based on the rotation of the player
		velocity = transform.basis.xform(velocity)
	
		if Input.is_action_pressed("sprint"):
			velocity *= sprint_multiplier
		
		if Input.is_action_pressed("jump"):
			velocity.y += jump_impulse
	else:
		direction = transform.basis.xform(direction)
		velocity += direction * air_move_force * delta
		
	velocity.y -= fall_acceleration * delta
	
	if(velocity.y > fall_acceleration * delta):
		falling = true
	
	if(grappling): 
		# Apply a force towards the grapple point that decreases with distance.
		var force = (grapple_point - $Hand.global_transform.origin) * grapple_acceleration
		velocity += force * delta
		if(velocity.length() >  max_grapple_speed):
			velocity = velocity.normalized() * max_grapple_speed
	
	rpc("apply_movement", velocity)
	
remotesync func apply_movement(new_velocity):
	last_vel = self.velocity
	self.velocity = move_and_slide(new_velocity, Vector3.UP)
	
func actions(_delta):
	if Input.is_action_just_pressed("grapple"):
		if(grappling):
			stop_grappling()
		else:
			print("attempt grapple")
			
			# Project a ray from the screen through the crosshair
			var center = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
			var from = $Pivot/Camera.project_ray_origin(center)
			var to = from + $Pivot/Camera.project_ray_normal(center) * 100
			var space_state = get_world().direct_space_state
			var camera_result = space_state.intersect_ray(from, to, [], 0b10)
			
			if(camera_result):
				print("camera_hit")
				
				# Project a ray from the player's hand to the hit point.
				var global_hand_pos = $Hand.global_transform.origin
				var result = space_state.intersect_ray(global_hand_pos, global_hand_pos + (camera_result.position - global_hand_pos) * max_grapple_distance, [self], 0b10)
				
				#Where it hits grapple to it.
				if(result):
					print("player_hit")
					print(result.position)
					print(global_hand_pos)
					print(result.collider.name)
					start_grapple(result.position)
	if Input.is_action_pressed("use"):
		use_item()
	if Input.is_action_just_pressed("drop"):
		drop_item()
	if Input.is_action_just_pressed("grab"):
		rpc("grab_item")
# Initiates a grapple to a target point
func start_grapple(to: Vector3):
	# Creates a debug ball at hit position
	var inst = debug_ball.instance()
	get_tree().root.add_child(inst)
	inst.global_transform.origin = to
	
	# Sets parameters for the grapple line
	$Hand/GrappleLine.set_to(to)
	$Hand/GrappleLine.enable()
	
	grappling = true
	grapple_point = to

func stop_grappling():
	$Hand/GrappleLine.disable()
	grappling = false
	
# Forces the synchronization of translation and velocity between peers
puppet func receive_sync(sync_translation, sync_rotation, sync_velocity):
	print("recieving sync from ", get_tree().get_rpc_sender_id())
	translation = sync_translation
	rotation = sync_rotation
	velocity = sync_velocity

func take_fall_damage():
	var diff = abs(last_vel.y - velocity.y)
	print(diff)
	if(diff >  fall_damage_cutoff_velocity):
		take_damage((diff - fall_damage_cutoff_velocity) * fall_damage_factor)
	
remotesync func take_damage(amnt):
	current_health -= amnt
	emit_signal("on_damage")
	
	print("pid ",  get_name(), " taking ", amnt, " damage. health is now ", current_health)
	
	if(current_health < 0):
		emit_signal("on_death")
		die()
		
func die():
	print("You died")

func pick_up(item):
	var player_item = item.player_item.instance()
	$Hand.add_child(player_item)
	
	items.append(player_item)
	
	if !current_item: 
		current_item = player_item
	
	item.get_parent().remove_child(item)
	player_item.drop_scene = item
	
func use_item():
	if(current_item):
		if current_item.has_method("use"):
			current_item.use()
		else:
			print("player has somehow equipped an non-item")

func drop_item():
	if current_item:
		var pickup = current_item.drop_scene
		get_node("/root/Main/Environment").add_child(current_item.drop_scene)
		current_item.drop_scene.set_owner(get_node("/root/Main/Environment"))
		
		pickup.global_transform.origin = translation + global_transform.basis.xform(Vector3.FORWARD) * 2
		#pickup.add_central_force(global_transform.basis.xform(Vector3.FORWARD).normalized() * 1)
		
		items.erase(current_item)
		current_item.queue_free()
		
		if items.size() > 0:
			current_item =  items.front()
		else:
			current_item = null
		
func set_player_name(name):
	$Sprite3D/Viewport/PlayerName.set_player_name(name)

# Timer for sync
func _on_SyncTimer_timeout():
	if(is_network_master()):
		rpc_unreliable("receive_sync", translation, rotation, velocity)

remotesync func grab_item():
	var items = $ItemPickupArea.get_overlapping_bodies()
	
	if items.size() > 1:
		var closest = 0
		var closest_dist = (items[0].global_transform.origin - global_transform.origin).length()
		for i in range(1, items.size()):
			var dist = (items[i].global_transform.origin - global_transform.origin).length()
			if(dist < closest_dist):
				closest = i
				closest_dist = dist
		print(items[closest].player_item)
		pick_up(items[closest])
	elif items.size() == 1:
		print(items.front())
		pick_up(items.front())	

