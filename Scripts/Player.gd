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

export var max_inventory_size = 2
var current_item = null
var items = []

func _ready():
	print("p")
	# Set players camera as the main

func _physics_process(delta):
	if(is_network_master()):
		look_move(delta)
		actions(delta)
		
func _input(event):
	if(is_network_master()):
			# Rotates the camera based on mouse input
		if event is InputEventMouseMotion:
			var roty = event.relative.x / get_viewport().size.x * sensitivity
			rpc("apply_rotation", roty)
		
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
	
			print(velocity)
	rpc("apply_movement", velocity)

remotesync func apply_rotation(roty):
	rotate_y(-roty)

remotesync func apply_movement(new_velocity):
	last_vel = self.velocity
	self.velocity = move_and_slide(new_velocity, Vector3.UP)
	
func actions(_delta):
	if Input.is_action_just_pressed("grapple"):
		if(grappling):
			stop_grappling()
		else:
			print("attempt grapple")
			var camera = get_viewport().get_camera()
			# Project a ray from the screen through the crosshair
			var center = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
			var from = camera.project_ray_origin(center)
			var to = from + camera.project_ray_normal(center) * 100
			var space_state = get_world().direct_space_state
			var camera_result = space_state.intersect_ray(from, to, [], 0b10)
			
			if(camera_result):
				print("camera_hit")
				
				# Project a ray from the player's hand to the hit point.
				var global_hand_pos = $Hand/GrapplePoint.global_transform.origin
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
	if Input.is_action_just_pressed("switch"):
		var new_index = wrapi(items.find(current_item) + 1, 0, items.size())
		print("curr item index ", items.find(current_item),"|| +1 = ", items.find(current_item) + 1 , "|| items.size() = ", items.size(), " || wrapi(items.find(current_item) + 1, 0, items.size() - 1) = ", new_index)
		rpc("switch_item_to",new_index )

# Initiates a grapple to a target point
func start_grapple(to: Vector3):
	# Creates a debug ball at hit position
	var inst = debug_ball.instance()
	get_tree().root.add_child(inst)
	inst.global_transform.origin = to
	
	# Sets parameters for the grapple line
	$Hand/GrapplePoint/GrappleLine.set_to(to)
	$Hand/GrapplePoint/GrappleLine.enable()
	
	grappling = true
	grapple_point = to

func stop_grappling():
	$Hand/GrapplePoint/GrappleLine.disable()
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

# Selects the closest item of the ground if there's space in the inventory. Calls the pick_up method 
# and passes the found body.
remotesync func grab_item():
	var itemsInArea = $ItemPickupArea.get_overlapping_bodies()
	
	if items.size() < max_inventory_size:
		if itemsInArea.size() > 1:
			var closest = 0
			var closest_dist = (itemsInArea[0].global_transform.origin - global_transform.origin).length()
			for i in range(1, itemsInArea.size()):
				var dist = (itemsInArea[i].global_transform.origin - global_transform.origin).length()
				if(dist < closest_dist):
					closest = i
					closest_dist = dist
			print(itemsInArea[closest].player_item)
			pick_up(itemsInArea[closest])
		elif itemsInArea.size() == 1:
			print(itemsInArea.front())
			pick_up(itemsInArea.front())	

# Adds a pickup item to the player inventory
func pick_up(item):
	var player_item = item.player_item.instance()

	item.get_parent().remove_child(item)
	player_item.drop_scene = item

	items.append(player_item)

	var index  = items.size() - 1;
	switch_item_to(index)

# Informs the item that the player is attempting to use the item
func use_item():
	if(current_item):
		print("using item")
		if current_item.has_method("use"):
			current_item.use()
		else:
			print("player has somehow equipped an non-item")

# Drops the item in inventory into the world as an item pickup
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

# Switches between elements of the items array given a specific target index. Controls the 
# instantiation of player models and other switching effects.
remotesync func switch_item_to(index):
	if not index >= items.size():
		for n in $Hand/Items.get_children():
			$Hand/Items.remove_child(n)

		current_item = items[index]
		$Hand/Items.add_child(current_item)
		print("switching to item ", current_item.name)
	else:
		print("attempting to access item index ", index, " when size of inv is only ", items.size())


func set_player_name(name):
	$Sprite3D/Viewport/PlayerName.set_player_name(name)

# Timer for sync
func _on_SyncTimer_timeout():
	if(is_network_master()):
		rpc_unreliable("receive_sync", translation, rotation, velocity)



