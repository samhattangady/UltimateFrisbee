extends Control

var trail = null
var max_trail = 500

func _ready():
	trail = get_node("Line2D")

func _on_Disc_position_update(position):
	if position.x == 0:
		get_node('Label').text = "" 
		while trail.get_point_count() > 0:
			trail.remove_point(0)
		return
	var camera = get_parent().get_node('Camera')
	position.y += 1
	var coord = camera.unproject_position(position)
	trail.add_point(coord)
	if trail.get_point_count() > max_trail:
		trail.remove_point(0)
	get_node('Label').rect_position = coord
	var pos_data = '('
	pos_data += String(stepify(position.x, 0.01)) + ', '
	pos_data += String(stepify(position.y, 0.01)) + ', '
	pos_data += String(stepify(position.z, 0.01)) + ')'
	get_node('Label').text = pos_data 
#	get_node('Label').text = String(position.y)
