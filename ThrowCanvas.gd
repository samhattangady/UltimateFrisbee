extends Node2D
var circles = []
signal throw(path)

func _input(event):
	if event is InputEventScreenTouch and not event.is_pressed():
		# On DragEnd
			# TODO (06 May 2019 sam): Make sure there are
			# atleast 3-4 points. Or calculate length of
			# the path.
			emit_signal("throw", circles)
			circles = []
	if event is InputEventScreenDrag:
		circles.append(event.position)
	update()

func _draw():
	for i in range(len(circles)-1):
		draw_line(circles[i], circles[i+1], Color.green, 10.0)
