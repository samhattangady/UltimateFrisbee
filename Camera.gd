extends Camera
var start_rotation = 0.0
var start_x = 0.0
var start_z = 0.0
var start_origin = Vector3(0, 0, 0)

func _ready():
	calculate_start_origin()

func _on_ThrowCanvas_pan_camera(pan_start, pan_end, origin):
	var start = pan_start - origin
	var end = pan_end - origin
	var angle = start.angle_to(end)
	rotation.y = start_rotation + angle
	var cam_angle = Vector3(start_x-start_origin.x, 0, start_z-start_origin.z).rotated(Vector3(0, 1, 0), angle)
	translation.x = cam_angle.x
	translation.z = cam_angle.z
	
	

func _on_ThrowCanvas_pan_start():
	calculate_start_origin()
	start_rotation = rotation.y
	start_x = translation.x
	start_z = translation.z

func snap_to_disc():
	pass

func get_point_in_world(position):
	# converts point on screen to point in world
	# TODO (08 May 2019 sam): Camera has project_position. See if it's better
	# TODO (08 May 2019 sam): Currently saying get_parent() multiple times
	# See if there is a more elegant approach that isn't so hardcoded.
	var camera = get_node('.')
	var start_point = camera.project_ray_origin(position)
	var end_point = start_point + 100*camera.project_ray_normal(position)
	var point = get_world().direct_space_state.intersect_ray(start_point, end_point)
	if not point: return
	return point.position

func _on_Disc_position_update(position):
	var n = get_node(".")
#	print(n.look_at(translation, position))
	pass # Replace with function body.

func calculate_start_origin():
	# To make a throw, the user will have to start the stroke from
	# 3/4 the way down the screen, and half way across. We will also
	# give a pixel radius of ~100 or so pixels.
	var screen = get_viewport().size
	var disc_points = Vector2(screen.x/2, screen.y*3/4)
	start_origin= get_point_in_world(disc_points)
#	print("start origin", start_origin)