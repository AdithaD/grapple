extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (PackedScene) var debug_ball

export var speed = 10
export var sprint_multiplier = 2
export var fall_acceleration = 55
export var air_move_force = 8
export var jump_impulse = 20

export var sensitivity = 1

export var grapple_acceleration = 70
export var max_grapple_speed = 60
export var max_grapple_distance = 100

var velocity = Vector3.ZERO
var grapple_time = 0

var grappling = false
var grapple_point = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	look_move(delta)
	actions(delta)
	pass # Replace with function body.

func actions(delta):
	if Input.is_action_just_pressed("grapple"):
		if(grappling):
			stop_grappling()
		else:
			print("attempt grapple")
			var center = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
			var from = $Pivot/Camera.project_ray_origin(center)
			var to = from + $Pivot/Camera.project_ray_normal(center) * 100
			
			var space_state = get_world().direct_space_state
			var camera_result = space_state.intersect_ray(from, to, [], 0b10)
			
			if(camera_result):
				print("camera_hit")
				var global_hand_pos = $Hand.global_transform.origin
				var result = space_state.intersect_ray(global_hand_pos, global_hand_pos + (camera_result.position - global_hand_pos) * max_grapple_distance, [self], 0b10)
				
				if(result):
					print("player_hit")
					print(result.position)
					print(global_hand_pos)
					print(result.collider.name)
					start_grapple(result.position)

					

func start_grapple(to: Vector3):
	grapple_time = 0
	var inst = debug_ball.instance()
	get_tree().root.add_child(inst)
	inst.global_transform.origin = to
	
	$Hand/GrappleLine.set_to(to)
	$Hand/GrappleLine.enable()
	
	grappling = true
	grapple_point = to

func stop_grappling():
	$Hand/GrappleLine.disable()
	grappling = false
	
func look_move(delta):
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x -= 1
	if Input.is_action_pressed("move_left"):
		direction.x += 1
	if Input.is_action_pressed("move_back"):
		direction.z -= 1
	if Input.is_action_pressed("move_forward"):
		direction.z += 1
	
	if direction != Vector3.ZERO:
			direction = direction.normalized();
	
	if(is_on_floor()):
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	
		velocity = transform.basis.xform(velocity)
	
		if(Input.is_action_pressed("sprint")):
			velocity *= sprint_multiplier
		
		if Input.is_action_just_pressed("jump"):
			velocity.y += jump_impulse
	else:
		velocity += direction * air_move_force * delta
		
	velocity.y -= fall_acceleration * delta
	
	if(grappling): 
		grapple_time += delta
		var force = (grapple_point - $Hand.global_transform.origin) * grapple_acceleration
		velocity += force * delta
		if(velocity.length() >  max_grapple_speed):
			velocity = velocity.normalized() * max_grapple_speed
		
	
	
	velocity = move_and_slide(velocity, Vector3.UP)

func _input(event):
	if event is InputEventMouseMotion:
		var roty = event.relative.x / get_viewport().size.x * sensitivity
		
		var rotx = event.relative.y / get_viewport().size.y * sensitivity
		
		rotate_y(-roty)
		
		rotx = $Pivot.rotation_degrees.x - clamp($Pivot.rotation_degrees.x + rotx, -90, 90)
		
		$Pivot.rotate_x(-rotx)
