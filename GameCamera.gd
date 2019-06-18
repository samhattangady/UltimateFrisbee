extends Camera
var start_rotation = 0.0
var start_x = 0.0
var start_z = 0.0
var start_origin = Vector3(0, 0, 0)

# FIXME (22 May 2019 sam): Currently these are hardcoded into the script. It should
# instead be taken from whatever values were set in the editor.
var camera_height = 30
var camera_z_offset = 15 
var camera_x_offset = 0

var camera_tween

signal camera_movement_completed()

func _ready():
    calculate_start_origin()
    self.camera_tween = Tween.new()
    self.add_child(self.camera_tween)
    self.camera_tween.connect('tween_completed', self, 'camera_movement_complete')

func pan_camera(pan_start, pan_end, origin):
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
    # TODO (22 May 2019 sam): The intersect ray should only intersect with the ground
    # Look into collision layers and masks for further guidance on that.
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

func disc_position_update(position):
    # We want the camera to center the disc to the point 3/4th y and 1/2 x
    # `start_origin` is already fixed at that point. So that's what we use
    # TODO (05 Jun 2019 sam): See if we want to prevent disc following during the throwing
    # animation
    # FIXME (05 Jun 2019 sam): There is a camera jitter which might be related to TranslationError
    self.start_origin = position
    var end_translation = Vector3(start_origin.x+camera_x_offset, start_origin.y+camera_height, start_origin.z+camera_z_offset)
    self.translation = end_translation
    self.emit_signal('camera_movement_completed')

func camera_movement_complete(obj, node_path):
    self.emit_signal('camera_movement_completed')


# TODO (22 May 2019 sam): There may be different camera movements that we want to
# explore. Specifically anchored to disc. That might be fun. Also, after the throw
# is complete, we may not want to abruptly snap to disc. A quick pan is probably
# preferable to the sudden snap
