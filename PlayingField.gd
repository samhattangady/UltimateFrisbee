extends Spatial

var input_controls
var game_camera

func _ready():
    input_controls = get_node("InputControls")
    game_camera = get_node("GameCamera")
    input_controls.connect("pan_start", game_camera, "pan_start")
    input_controls.connect("pan_camera", game_camera, "pan_camera")
