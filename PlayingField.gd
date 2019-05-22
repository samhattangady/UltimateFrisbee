extends Spatial

var input_controls
var game_camera
var frisbee_things
var disc
var player

func _ready():
    input_controls = get_node("InputControls")
    game_camera = get_node("GameCamera")
    frisbee_things = get_node('FrisbeeThings')
    disc = frisbee_things.get_node('Disc')
    player = frisbee_things.get_node('Players').get_node('Player')
    input_controls.connect("pan_start", game_camera, "pan_start")
    input_controls.connect("pan_camera", game_camera, "pan_camera")
    input_controls.connect('throw', disc, 'execute_throw')
    disc.connect('throw_started', player, 'disc_is_thrown')
    disc.connect('throw_complete', game_camera, 'throw_complete')
    game_camera.throw_complete(disc.path.translation)
    input_controls.connect('mark_point', player, 'run_to_screen_point')
