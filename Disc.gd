extends Spatial


var currently_thrown = false
var playing = true
var path_follow = PathFollow
var path = Path
var random = RandomNumberGenerator
var pause_state
var body

var debug_previous_throw = {}

export var max_throw_speed = 30.0
export var min_throw_speed = 12.0

export var max_throw_distance = 80.0
export var min_throw_distance = 15.0

export var fast_throw_speed = 70.0
export var slow_throw_speed = 17.0
export var fast_to_slow_ratio = 3.0

# These are calculated for each throw
var total_throw_time = 0
var current_max_speed = 0
var current_min_speed = 0
var throw_time_elapsed = 0

var number_of_throws = 0
var throw_start_time = 0

# This is the amount of x distance a disc can curve by
# relative to its total distance travelled (straight-line disp)
const MAX_OI_CURVE = 0.5

# When converting from screen to world, the x displacement is often
# too much, makes throws unintuitive. This reduces that and brings it
# back under control
const X_DISP_FACTOR = 0.8

var DISC_CALCULATOR

const DEBUG = true
signal position_update(position)
signal throw_started(curve, throw_details)
signal throw_complete()
signal disc_position_update(position)

func _ready():
    self.path_follow = self.get_node('Path/PathFollow')
    self.path = self.get_node('Path')
    self.body = self.get_node('Path/PathFollow/DiscKinematicBody')
    self.random = RandomNumberGenerator.new()
    self.DISC_CALCULATOR = load('DiscCalculator.gd').new()
    self.emit_signal('disc_position_update', self.get_position())

func _process(delta):
    if DEBUG:
        emit_signal('position_update', path_follow.translation)
    self.emit_signal('disc_position_update', self.get_position())
    if currently_thrown and !self.pause_state:
        update_offset(delta)

func _input(event):
    if event.is_action_pressed('ui_down'):
        playing = !playing
    if event.is_action_pressed('ui_left'):
        execute_throw(debug_previous_throw)
    if event.is_action_pressed('ui_accept'):
        execute_throw({
            'end':Vector2(532, 208),
            'msecs':518,
            'start':Vector2(572, 431),
            'x_disp':97.806732,
            'y_disp':-226.559036
        })

func get_position():
    # To get the world coordinates of the disc. When in the air, we want
    # the path_follow.translation, but on the ground, we want the path.translation
    # This might be a part of !TranslationError, Don't know.
    if self.currently_thrown:
        return self.path_follow.translation
    else:
        return self.path.translation

func execute_throw(throw):
    # Check if end point meets ground
    var end_point = get_point_in_world(throw['end'])
    if not end_point: return
    var curve = calculate_throw_curve(throw)
    path.curve = curve
    # trace_path(curve)
    start_throw(throw, curve)

func start_throw(throw, curve):
    self.calculate_throw_speed(throw, curve)

func start_throw_animation():
    # FIXME (15 May 2019 sam): !TranslationError. See bottom
    if self.number_of_throws != 0:
        self.translation = -self.path.translation
    self.path.rotation = Vector3(0, 0, 0)
    self.number_of_throws += 1
    self.currently_thrown = true
    self.emit_signal('throw_started', self.path.curve, {
        'time': self.total_throw_time,
        'max_speed': self.current_max_speed,
        'min_speed': self.current_min_speed
    })
    self.throw_start_time = OS.get_ticks_msec()

func calculate_throw_speed(throw, curve):
    var throw_distance = curve.get_point_position(0).distance_to(curve.get_point_position(curve.get_point_count()-1))
    var throw_stroke_speed = throw_distance / (throw['msecs'] / 1000.0)
    # throw_stroke_speed = min(throw_stroke_speed, self.fast_throw_speed)
    # throw_stroke_speed = max(throw_stroke_speed, self.slow_throw_speed)
    var throw_distance_ratio = (throw_distance-self.min_throw_distance)/(self.max_throw_distance-self.min_throw_distance)
    self.current_max_speed = lerp(self.min_throw_speed, self.max_throw_speed, throw_distance_ratio)
    var stroke_speed_ratio = (throw_stroke_speed-self.slow_throw_speed) / (self.fast_throw_speed - self.slow_throw_speed)
    self.current_max_speed *= lerp(0.7, 1.7, stroke_speed_ratio)
    self.total_throw_time = throw_distance / self.current_max_speed
    # TODO (10 May 2019 sam): Add the x_disp here. Lesser x disp, lesser variation in throw
    self.current_min_speed = self.current_max_speed * 0.7

func update_offset(delta):
    self.throw_time_elapsed += delta
    self.path_follow.unit_offset = DISC_CALCULATOR.get_disc_offset(
                                self.throw_time_elapsed,
                                self.total_throw_time,
                                self.current_max_speed,
                                self.current_min_speed)
    var offset = self.path_follow.unit_offset
    if offset >= 1.0:
        self.throw_is_grounded()

func throw_is_grounded():
    # Throw hits the ground
    self.path_follow.unit_offset = 0.999
    self.throw_is_complete()

func throw_is_complete():
    self.currently_thrown = false
    # FIXME (15 May 2019 sam): !TranslationError. See bottom
    self.path.translation = self.path_follow.translation
    self.path_follow.unit_offset = 0.0
    self.throw_time_elapsed = 0.0
    var actual_time = (OS.get_ticks_msec()-self.throw_start_time) / 1000.0
    self.emit_signal('throw_complete')

func disc_is_reached():
    # There are two cases here. Either the throw
    # is caught, or the player approaches the fallen disc
    # Case 1: Catching the disc
    if self.currently_thrown:
        self.throw_is_complete()
    # Case 2: Player is at the fallen disc. No additional logic

func calculate_throw_curve(throw_data):
    var end_point = get_point_in_world(throw_data['end'])
    var world_dist = path.translation.distance_to(end_point)
    var screen_dist = throw_data['start'].distance_to(throw_data['end'])
    var world_x_disp = throw_data['x_disp']* X_DISP_FACTOR * (world_dist/screen_dist)
    if abs(world_x_disp) > world_dist*MAX_OI_CURVE:
        world_x_disp = world_dist*MAX_OI_CURVE * (world_x_disp/abs(world_x_disp))
    var oi_point = calculate_oi_point(world_dist, world_x_disp, path.translation, end_point)
    var world_y_disp = throw_data['y_disp'] * (world_dist/screen_dist)
    var curve = Curve3D.new()
    curve.add_point(path.translation)
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
    oiy += (path.translation.y+end.y) / 2
    # We want some randomness in how the exact curve of the throw looks
    var ci = (start-end)/3.0*random.randf_range(0.8, 1.5)
    var co = (end-start)/3.0*random.randf_range(0.8, 1.5)
    return {
        'oi_point': start + Vector3(oix, oiy, oiz),
        'cin': ci,
        'cout': co
    }

func get_point_in_world(position):
    # converts point on screen to point in world
    # TODO (08 May 2019 sam): Camera has project_position. See if it's better
    # TODO (08 May 2019 sam): Currently saying get_parent() multiple times
    # See if there is a more elegant approach that isn't so hardcoded.
    var camera = get_parent().get_parent().get_node('GameCamera')
    var start_point = camera.project_ray_origin(position)
    # TODO (15 May 2019 sam): The 10000 marked below is hardcoded. It is meant
    # to ensure that the ray is long enough to intersect with the ground in all
    # cases. See if there is a better way to do this.
    var end_point = start_point + 10000*camera.project_ray_normal(position)
    var point = get_world().direct_space_state.intersect_ray(start_point, end_point,
            [], 2)
    if not point: return
    return point.position

func attach_to_wrist(trans):
    # Complicated because of !TranslationError
    # self.path.transform = trans[1].translated(trans[0])
    self.path.translation = trans[0]
    # TODO (05 May 2019 sam): See if the transform can be applied without having
    # to scale again.
    self.path.scale = Vector3(1, 1, 1)

func set_pause_state(state):
    self.pause_state = state

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

# FIXME (15 May 2019 sam): !TranslationError. There seems to be an issue with the
# translation values of path_follow, disc and path. path_follow seems to have a
# global translation while all the others look like the have a relative to parent
# translation value. This results in various errors when we are trying to make a
# throw from anywhere other than Vector3(0, 0, 0). Additionally, it looks like
# when unit_offset is 0, path_follow has a relative translation.

# TODO (22 May 2019 sam): Right now, a straight throw results in the disc travelling
# at ground level from start to end. Figure out how to deal with that once we have
# players catching the disc etc.

# TODO (23 May 2019 sam): On slower throws, we need to add more height to the throws
# and give them a more floaty trajectory. Right now, the timing is good, but the path
# looks a little off.

# FIXME (03 Jun 2019 sam): There is a bug where when we make a throw that ends out of
# bounds, the previous throw is repeated. Or something like that. Need to change that
# into something like a cancellation or rejection of input. There are multiple ways that
# can probably be dealt with.
