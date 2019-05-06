extends RigidBody
var force = Vector3(0,0,0)

func add_acceleration(acceleration_vector):
	pass
	
func _physics_process(delta):
	if Input.is_action_pressed("ui_right"):
		add_central_force(Vector3(10, 0, 0))
	elif Input.is_action_pressed("ui_left"):
		add_central_force(Vector3(-10, 0, 0))

func _on_ThrowCanvas_throw(path):
	var difference = path[-1] - path[0]
	add_central_force(Vector3(difference.x, 0, difference.y))

