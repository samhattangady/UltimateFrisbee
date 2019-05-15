extends Node2D

var throw_path = []
var mouse_down = false
var is_throwing = false
var is_panning = false
var pan_start = Vector2(0, 0)
signal throw(throw_data)
signal pan_start()
signal pan_camera(pan_start, pan_end, origin)

var disc_points = Vector2(0, 0)
var throw_radius = 100
var throw_radius_buffer = 40
var draw_throw_circle = true

func _ready():
    calculate_disc_points()

func _input(event):
    if event is InputEventMouseButton:
        if event.is_pressed():
            throw_path = []
            # TODO (08 May 2019 sam): Check if the user is clicking
            # near the disc/player, and not just drawing randomly.
            mouse_down = true
            var distance = event.position.distance_to(disc_points)
            if distance < throw_radius:
                is_throwing = true
            elif distance > throw_radius+throw_radius_buffer:
                is_panning = true
                emit_signal("pan_start")
                pan_start = event.position
        else:
            if is_throwing:
                # TODO (06 May 2019 sam): Make sure there are
                # atleast 3-4 points. Or calculate length of
                # the path. Or some other kind of verification
                # We also ought to be checking if there is any
                # cause for DivisionByZeroError to be cropping
                # up here.
                if len(throw_path) > 3:
                    var throw_data = identify_throw(throw_path)
                    emit_signal("throw", throw_data)
            mouse_down = false
            is_throwing = false
            is_panning = false
            throw_path = []
    if mouse_down and event is InputEventMouseMotion:
        if is_throwing:
            throw_path.append(event.position)
        elif is_panning:
            emit_signal("pan_camera", pan_start, event.position, disc_points)
    update()

func _draw():
    for i in range(len(throw_path)-1):
        draw_line(throw_path[i], throw_path[i+1], Color.white, 10.0)
    if draw_throw_circle:
        draw_circle(disc_points, throw_radius, Color(1, 1, 1, 0.3))

func identify_throw(path):
    var rotated_path = rotate_path_to_y_axis(path)
    var max_disp = get_max_displacements(rotated_path)
    return {
        'start': path[0],
        'end': path.back(),
        'x_disp': max_disp['x'],
        'y_disp': max_disp['y'],
    }

func get_max_displacements(path):
    var maxx = 0
    var maxy = 0
    for point in path:
        if abs(point.x) > abs(maxx):
            maxx = point.x
        if abs(point.y) > abs(maxy):
            maxy = point.y
    return {
        'x': maxx,
        'y': maxy,
    }

func rotate_path_to_y_axis(path):
    # Rotate the path to align end points along y axis
    # This is useful to find max x and y displacement
    # which we use to identify what kind of throw it is
    path = anchor_to_origin(path)
    var angle = path[0].angle_to_point(path.back()) - PI/2
    if rad2deg(angle) < -180:
        angle += 2*PI
    var rotated_path = []
    for point in path:
        rotated_path.append(point.rotated(-angle))
    return rotated_path

func anchor_to_origin(path):
    var anchored_path = []
    for point in path:
        anchored_path.append(point-path[0])
    return anchored_path

func rotate_around_point(point, angle, anchor):
    # formula from https://www.gamefromscratch.com/post/2012/11/24/GameDev-math-recipes-Rotating-one-point-around-another-point.aspx
    var x = (point.x-anchor.x)*cos(angle) - (point.y-anchor.y)*sin(angle) + anchor.x
    var y = (point.x-anchor.x)*sin(angle) + (point.y-anchor.y)*cos(angle) + anchor.y
    return Vector2(x, y)

func distance_from_line(point, line):
    # line is an array of Vector2 of length 2
    # formula from https://stackoverflow.com/a/2233538/5453127
    var x1 = line[0].x
    var y1 = line[0].y
    var x2 = line[1].x
    var y2 = line[1].y
    var x3 = point.x
    var y3 = point.y
    var px = x2-x1
    var py = y2-y1
    var norm = px*px + py*py
    var u =  ((x3 - x1) * px + (y3 - y1) * py) / float(norm)
    if u > 1:
        u = 1
    elif u < 0:
        u = 0
    var x = x1 + u * px
    var y = y1 + u * py
    var dx = x - x3
    var dy = y - y3
    var dist = (dx*dx + dy*dy)  # **.5
    return dist

func calculate_disc_points():
    # To make a throw, the user will have to start the stroke from
    # 3/4 the way down the screen, and half way across. We will also
    # give a pixel radius of ~100 or so pixels.
    var screen = get_viewport().size
    disc_points = Vector2(screen.x/2, screen.y*3/4)

# TODO (13 May 2019 sam): Currently everything is configured to the Pixel
# Once we get to a certain point, we will also have to try to figure out
# how to handle different screen sizes etc.

# TODO (14 May 2019 sam): Currently most of the things are being done manually
# with a lot of rotations to coordinate axes etc. There might be a much cleaner
# way to do all of this with just the Vector2 maths. Look into it. For an example
# see how the control points are calculated in Disc.gd `calculate_oi_point()`
# Ideally things should be cleaned up to that point, rather than all this. Maybe

# TODO (14 May 2019 sam): Clean up calculate disc_points. We are using it across
# different scripts, which is not ideal. Figure out some way to have a central
# store of all these variables so that they can easily be accessed.
