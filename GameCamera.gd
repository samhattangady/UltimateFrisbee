extends Camera
var start_rotation = 0.0
var start_x = 0.0
var start_z = 0.0
var start_origin = Vector3(0, 0, 0)

var camera_height = 30
var camera_z_offset = 15
var camera_x_offset = 0

func _ready():
    calculate_start_origin()

func pan_camera(pan_start, pan_end, origin):
    print("panning", pan_start, pan_end, origin)
    # TODO (15 May 2019 sam): Prevent panning when the disc is in the air?
    var start = pan_start - origin
    var end = pan_end - origin
    var angle = start.angle_to(end)
    rotation.y = start_rotation + angle
    var cam_angle = Vector3(start_x-start_origin.x, 0, start_z-start_origin.z).rotated(Vector3(0, 1, 0), angle) + start_origin
    translation.x = cam_angle.x
    translation.z = cam_angle.z
    camera_z_offset = translation.z - start_origin.z
    camera_x_offset = translation.x - start_origin.x

func pan_start():
    # TODO (15 May 2019 sam): Prevent panning when the disc is in the air?
    print("starting pan")
    calculate_start_origin()
    start_rotation = rotation.y
    start_x = translation.x
    start_z = translation.z

func get_point_in_world(position):
    # converts point on screen to point in world
    # TODO (08 May 2019 sam): Camera has project_position. See if it's better
    var camera = get_node('.')
    var start_point = camera.project_ray_origin(position)
    var end_point = start_point + 100*camera.project_ray_normal(position)
    var point = get_world().direct_space_state.intersect_ray(start_point, end_point)
    if not point: return
    return point.position

func calculate_start_origin():
    # To make a throw, the user will have to start the stroke from
    # 3/4 the way down the screen, and half way across. We will also
    # give a pixel radius of ~100 or so pixels.
    var screen = get_viewport().size
    var disc_points = Vector2(screen.x/2, screen.y*3/4)
    start_origin= get_point_in_world(disc_points)

func throw_complete(position):
    start_origin = position
    translation.x = position.x+camera_x_offset
    translation.y = position.y+camera_height
    translation.z = position.z+camera_z_offset
    pass
