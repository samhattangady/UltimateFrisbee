extends KinematicBody

var currently_thrown = false
var playing = true
var path_tracers = []
var path_follow = PathFollow
var random = RandomNumberGenerator

var previous_throw = {}

export var max_throw_speed = 25.0
export var min_throw_speed = 12.0

export var max_throw_distance = 80.0
export var min_throw_distance = 15.0

# These are calculated for each throw
var total_throw_time = 0
var current_max_speed = 0
var current_min_speed = 0
var offset_delta = 0

# This is the amount of x distance a disc can curve by
# relative to its total distance travelled (straight-line disp)
const MAX_OI_CURVE = 0.5

# When converting from screen to world, the x displacement is often
# too much, makes throws unintuitive. This reduces that and brings it
# back under control
const X_DISP_FACTOR = 0.8

const DEBUG = true
signal position_update(position)

func _ready():
    path_tracers = get_parent().get_parent().get_parent().get_node("DebugPaths")
    path_follow = get_parent()
    random = RandomNumberGenerator.new()

func _process(delta):
    if DEBUG:
        emit_signal("position_update", path_follow.translation+path_follow.get_parent().translation)
    if currently_thrown and playing:
        update_offset(delta)
        if path_follow.unit_offset >= 1:
            currently_thrown = false
#           path_follow.unit_offset = 0
#           rotation = Vector3(0,0,0)

func _input(event):
    if event.is_action_pressed("ui_accept"):
        execute_throw({
            "end": Vector2(498, 162),
            "start": Vector2(533, 471),
            "x_disp": 130.949036,
            "y_disp": -310.975891
        })
    if event.is_action_pressed("ui_down"):
        playing = !playing
    if event.is_action_pressed("ui_left"):
        execute_throw(previous_throw)

func _on_ThrowCanvas_throw(throw):
    previous_throw = throw
    print(throw)
    execute_throw(throw)

func execute_throw(throw):
    # Check if end point meets ground
    var end_point = get_point_in_world(throw['end'])
    if not end_point: return
    var curve = calculate_throw_curve(throw)
    var path = get_parent().get_parent()
    path.curve = curve
    # trace_path(curve)
    start_throw(curve)

func start_throw(throw):
    currently_thrown = true
    path_follow.unit_offset = 0
    path_follow.rotation = Vector3(0,0,0)
    var throw_distance = throw.get_point_position(0).distance_to(throw.get_point_position(throw.get_point_count()-1))
    current_max_speed = lerp(min_throw_speed, max_throw_speed, (throw_distance-min_throw_distance)/(max_throw_distance-min_throw_distance))
    # TODO (10 May 2019 sam): Add the x_disp here. Lesser x disp, lesser variation in throw
    current_min_speed = current_max_speed * 0.6
    total_throw_time = throw_distance / current_max_speed
    print('Distance: ', throw_distance, '\tSpeed: ', current_max_speed, '\tTime: ', total_throw_time)

func update_offset(delta):
    var min_delta_offset = 1.0 / (total_throw_time * current_max_speed/current_min_speed)
    var max_delta_offset = 1.0 / (total_throw_time)
    var offset = path_follow.unit_offset
    if offset < 0.5:
        offset_delta = lerp(max_delta_offset, min_delta_offset, offset*2)
    elif offset < 1:
        offset_delta = lerp(min_delta_offset, max_delta_offset, (offset-0.5)*2)
    else:
        offset_delta = 0
    path_follow.unit_offset += offset_delta*delta

func calculate_throw_curve(throw_data):
    var end_point = get_point_in_world(throw_data['end'])
    var world_dist = translation.distance_to(end_point)
    var screen_dist = throw_data['start'].distance_to(throw_data['end'])
    var world_x_disp = throw_data['x_disp']* X_DISP_FACTOR * (world_dist/screen_dist)
    if abs(world_x_disp) > world_dist*MAX_OI_CURVE:
        world_x_disp = world_dist*MAX_OI_CURVE * (world_x_disp/abs(world_x_disp))
    var oi_point = calculate_oi_point(world_dist, world_x_disp, translation, end_point)
    var world_y_disp = throw_data['y_disp'] * (world_dist/screen_dist)
    var curve = Curve3D.new()
    curve.add_point(translation)
    curve.add_point(oi_point['oi_point'], oi_point['cin'], oi_point['cout'])
    curve.add_point(end_point)
    return curve

func calculate_oi_point(dist, x_disp, start, end):
    # The outermost point of the throw. Would be simplified to
    # x, z = x_disp, dist/2. We need to rotate this by angle
    var angle = Vector2(start.x, start.z).angle_to_point(Vector2(end.x, end.z)) - PI/2
    var oi = Vector2(x_disp, dist/2).rotated(-angle)
    var oix = oi.x
    # in godot, negative z is away from camera
    var oiz = -oi.y
    # From projectile motion, at 45 deg, max_height = 0.5*Range
    # We then do cos45 as I am picturing the disc to be thrown like that
    # Then we see what ratio of that our throw is. The idea is
    # that more oi is more height
    var max_height = (dist/2) * cos(deg2rad(45))
    var oiy = lerp(0, max_height, abs(x_disp)/dist*MAX_OI_CURVE)
    oiy += (translation.y+end.y) / 2
    # We want some randomness in how the exact curve of the throw looks
    var ci = (start-end)/3.0*random.randf_range(0.8, 1.5)
    var co = (end-start)/3.0*random.randf_range(0.8, 1.5)
    return {
        'oi_point': Vector3(oix, oiy, oiz),
        'cin': ci,
        'cout': co
    }

func get_point_in_world(position):
    # converts point on screen to point in world
    # TODO (08 May 2019 sam): Camera has project_position. See if it's better
    # TODO (08 May 2019 sam): Currently saying get_parent() multiple times
    # See if there is a more elegant approach that isn't so hardcoded.
    var camera = get_parent().get_parent().get_parent().get_node('Camera')
    var start_point = camera.project_ray_origin(position)
    var end_point = start_point + 100*camera.project_ray_normal(position)
    var point = get_world().direct_space_state.intersect_ray(start_point, end_point)
    if not point: return
    return point.position

func trace_path(curve):
    var tm = preload("res://TrailMarker.tscn")
    for child in path_tracers.get_children():
        path_tracers.remove_child(child)
    var steps = 60
    for i in range(curve.get_point_count()-1):
        var t = tm.instance()
        t.translation = curve.get_point_position(i)
        path_tracers.add_child(t)
        for j in range(1, steps+1):
            t = tm.instance()
            t.translation = curve.interpolate(i, float(j)/steps)
            path_tracers.add_child(t)
    var cip = tm.instance()
    cip.translation = curve.get_point_in(1) + curve.get_point_position(1)
    cip.scale = Vector3(.5, .5, .5)
    path_tracers.add_child(cip)
    var cop = tm.instance()
    cop.translation = curve.get_point_out(1) + curve.get_point_position(1)
    cop.scale = Vector3(.5, .5, .5)
    path_tracers.add_child(cop)

# TODO (10 May 2019 sam): Right now the throw ends at the point on the ground
# Moving forward, we might want to actually throw to a point at a certain height
# in the air. At that juncture, we will have to figure out how to make the disc
# travel till it hits the ground, as well as maybe the bouncing etc.

# TODO (10 May 2019 sam): Deal with all the y_disp stuff in throw calculation
# That is what will allow the users to add height to their throws, for blades
# and maybe hammers

# TODO (10 May 2019 sam): Calculate throw speed. We want the user to be able to
# draw fast lines for fast throws.

# TODO (14 May 2019 sam): See if it makes sense to have a separate script at a
# global level that can handle all of the signal transmission stuff. We can use
# it like a vue-x store. Might be useful for wiring up signals etc. We can also
# have one for each scene or whatever. Might make code organization a little
# more elegant
