extends Node2D

var throw_path = []
var drag_path = []
var mouse_down = false
var is_throwing = false
var is_panning = false
var pan_start = Vector2(0, 0)
var throw_start_time = 0

signal throw(throw_data)
signal pan_start()
signal pan_camera(pan_start, pan_end, origin)
signal mark_point(point)
signal tap_location(point)

var disc_points = Vector2(0, 0)
var throw_radius = 100
var throw_radius_buffer = 40
var draw_throw_circle = true

func _ready():
    calculate_disc_points()

func _input(event):
    if event is InputEventMouseButton and event.get_button_index() == BUTTON_LEFT:
        if event.is_pressed():
            self.throw_path = []
            self.mouse_down = true
            var distance = event.position.distance_to(disc_points)
            if distance < self.throw_radius:
                self.is_throwing = true
                self.throw_start_time = OS.get_ticks_msec()
            elif distance > self.throw_radius+self.throw_radius_buffer:
                self.is_panning = true
                self.emit_signal("pan_start")
                self.pan_start = event.position
        else:
            if len(drag_path) == 0:
                # Player is tapping. Not dragging
                self.emit_signal('tap_location', event.position)
            if self.is_throwing:
                # TODO (06 May 2019 sam): Make sure there are
                # atleast 3-4 points. Or calculate length of
                # the path. Or some other kind of verification
                # We also ought to be checking if there is any
                # cause for DivisionByZeroError to be cropping
                # up here.
                if len(self.throw_path) > 3:
                    var throw_data = self.identify_throw(throw_path)
                    throw_data['msecs'] = OS.get_ticks_msec() - self.throw_start_time
                    self.emit_signal("throw", throw_data)
            self.mouse_down = false
            self.is_throwing = false
            self.is_panning = false
            self.throw_path = []
            self.drag_path = []
    if event is InputEventMouseButton and event.get_button_index() == BUTTON_RIGHT:
        # DEBUG
        self.emit_signal('mark_point', event.position)
    if mouse_down and event is InputEventMouseMotion:
        self.drag_path.append(event.position)
        if self.is_throwing:
            self.throw_path.append(event.position)
        elif self.is_panning:
            self.emit_signal("pan_camera", pan_start, event.position, disc_points)
    update()

func _draw():
    for i in range(len(throw_path)-1):
        draw_line(throw_path[i], throw_path[i+1], Color.white, 10.0)
    if draw_throw_circle:
        draw_circle(disc_points, throw_radius, Color(1, 1, 1, 0.1))

func identify_throw(path):
    var throw = get_throw(path)
    var rotated_path = rotate_path_to_y_axis(path)
    var max_disp = get_max_displacements(rotated_path)
    return {
        'start': path[0],
        'end': path.back(),
        'throw': throw,
        'x_disp': max_disp['x'],
        'y_disp': max_disp['y'],
    }

func get_throw(path):
    # Tells us whether a throw is a backhand or forehand etc
    var start_point = path[0]
    if start_point.x > disc_points.x:
        return 'Forehand'
    else:
        return 'Backhand'

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

# TODO (23 May 2019 sam): Add a feature so that if the person is throwing and they
# are on the same pixel for n amount of time, the throw is considered complete, and
# the disc is thrown.

# TODO (23 May 2019 sam): Calculate speed of throw using path here itself, and send
# that to Disc. Currently, a fast and blady throw is coming out a little slower than
# I like.
