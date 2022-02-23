extends ImmediateGeometry

export var line_width = 0.5

var to : Vector3 = Vector3.ZERO
var enabled = false;

func enable():
	enabled = true
	
func disable():
	enabled = false
	clear()

func set_to(new_to: Vector3):
	self.to = new_to
	
func _process(_delta):
	if(enabled):
		draw_grapple()

func draw_grapple():
	clear()
	begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	add_vertex(global_transform.basis.xform_inv(to - global_transform.origin))
	add_vertex(translation)

	end()
