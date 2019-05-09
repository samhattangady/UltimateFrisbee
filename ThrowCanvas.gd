extends Node2D

var circles = []
var mouse_down = false
signal throw(throw_data)

func _ready():
	print(rotate_path_to_y_axis([Vector2(0,0), Vector2(2,1)]))

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed(): 
			circles = []
			# TODO (08 May 2019 sam): Check if the user is clicking
			# near the disc/player, and not just drawing randomly.
			mouse_down = true
		else: 
			# TODO (06 May 2019 sam): Make sure there are
			# atleast 3-4 points. Or calculate length of
			# the path. Or some other kind of verification
			mouse_down = false
			if len(circles) < 2:
				return
			#print('starting cubic regression')
			# trimming to see if it improves performance
#			var trimmed_circles = []
#			if len(circles)>10:
#				var step = floor(len(circles)/10)
#				for i in range(0, len(circles), step):
#					trimmed_circles.append(circles[i])
#			else:
#				trimmed_circles = circles
			# circles=cubic_regression(trimmed_circles)
			var throw_data = identify_throw(circles)
			emit_signal("throw", throw_data)
			circles = []
	if mouse_down and event is InputEventMouseMotion:
		circles.append(event.position)
	update()

func _draw():
	for i in range(len(circles)-1):
		draw_line(circles[i], circles[i+1], Color.white, 10.0)

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
	var x1 = path[0].x
	var y1 = path[0].y
	var x2 = path.back().x
	var y2 = path.back().y
	var angle = atan((x2-x1)/(y2-y1))
	var rotated_path = []
	for point in path:
		rotated_path.append(rotate_around_point(point, angle, path[0]))
	rotated_path = anchor_to_origin(rotated_path)
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