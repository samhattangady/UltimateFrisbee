extends Node2D

var points = []
export var max_trail = 50

func _draw():
	for i in range(get_point_count()-1):
#		draw_circle(points[i], 5.0*i/get_point_count(), Color.white)
		draw_line(points[i+1], points[i], Color(1, 1, 1, 1.0*i/get_point_count()), 2.0*i/get_point_count())
#		draw_line(points[i+1], points[i], 2.0*i/get_point_count(), Color(1, 1, 1, 1.0*i/get_point_count()))

func add_point(point):
	points.append(point)

func get_point_count():
	return len(points)

func clear():
	points = []

func _process(delta):
	if get_point_count() > max_trail:
		points.pop_front()
	update()