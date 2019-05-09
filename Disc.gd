extends KinematicBody

var currently_thrown = false
var playing = true
var path_tracers = []
# This is the amount of x distance a disc can curve by
# relative to its total distance travelled (straight-line disp)
const MAX_OI_CURVE = 0.5
const DEBUG = true
signal position_update(height)

export var curve_in_x = 0.0
export var curve_in_y = 0.0
export var curve_in_z = 0.0

func _ready():
	path_tracers = get_parent().get_parent().get_parent().get_node("DebugPaths")

func _process(delta):
#	var offset = get_parent().unit_offset
#	if offset < 1:
#		offset += 0.01
	if DEBUG:
		emit_signal("position_update", get_parent().translation)
	if currently_thrown and playing:
		get_parent().unit_offset += 0.006
		if get_parent().unit_offset >= 1:
			currently_thrown = false
			get_parent().unit_offset = 0
			rotation = Vector3(0,0,0)

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

func _on_ThrowCanvas_throw(throw):
	print(throw)
	execute_throw(throw)

func execute_throw(throw):
	# Check if end point meets ground
	var end_point = get_point_in_world(throw['end'])
	if not end_point: return
	var curve = calculate_throw_curve(throw)
	var path = get_parent().get_parent()
	path.curve = curve
	trace_path(curve)
	currently_thrown = true
	get_parent().unit_offset = 0
	get_parent().rotation = Vector3(0,0,0)

func calculate_throw_curve(throw_data):
	var end_point = get_point_in_world(throw_data['end'])
	var world_dist = translation.distance_to(end_point)
	var screen_dist = throw_data['start'].distance_to(throw_data['end'])
	var world_x_disp = throw_data['x_disp']*0.8 * (world_dist/screen_dist)
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
	# FIXME (08 May 2019 sam): When we throw toward the camera
	# it's all fucked up.
	var angle = atan((end.x-start.x)/(end.z-start.z))
	# x, z = x_disp, dist/2. We need to rotate this by angle
	var oix = x_disp*cos(angle) - (dist/2)*sin(angle)
	# in godot, negative z is away from camera
	var oiz = -(x_disp*sin(angle) + (dist/2)*cos(angle))
	# From projectile motion, at 45 deg, max_height = 0.5*Range
	# We then do cos45 as I am picturing the disc to be thrown like that
	var max_height = (dist/2) * cos(deg2rad(45))
	# Then we see what ratio of that our throw is. The idea is
	# that more oi is more height
	var oiy = max_height * (abs(x_disp)/dist*MAX_OI_CURVE)
	oiy += (translation.y+end.y) / 2
	# x, z = 0, -dist/3. We need to rotate this by angle
	var cix = - (-dist/3)*sin(angle)
	var ciz = - (-dist/3)*cos(angle)
	# x, z = 0, dist-dist/3. We need to rotate this by angle
	var cox = - (dist+(-dist/3))*sin(angle)
	var coz = - (dist+(-dist/3))*cos(angle)
	var ciy = 0
	var coy = 0
	return {
		'oi_point': Vector3(oix, oiy, oiz),
		'cin': Vector3(cix, ciy, ciz),
#		'cin': Vector3(curve_in_x, curve_in_y, curve_in_z),
		'cout': Vector3(cox, coy, coz)
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
	return
	var tm = preload("res://TrailMarker.tscn")
	for child in path_tracers.get_children():
		path_tracers.remove_child(child)
	var steps = 10
	for i in range(curve.get_point_count()-1):
		var t = tm.instance()
		t.translation = curve.get_point_position(i)
		path_tracers.add_child(t)
		for j in range(1, steps+1):
			t = tm.instance()
			t.translation = curve.interpolate(i, float(j)/steps)
			path_tracers.add_child(t)
#	var cip = tm.instance()
#	cip.translation = curve.get_point_in(1)
#	cip.scale = Vector3(.5, .5, .5)
#	path_tracers.add_child(cip)
#	var cop = tm.instance()
#	cop.translation = curve.get_point_out(1)
#	cop.scale = Vector3(.5, .5, .5)
#	path_tracers.add_child(cop)
