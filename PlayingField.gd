extends Spatial

var input_controls
var game_camera
var frisbee_things
var disc
var player
var player2
var world_debug
var players_controller

func _ready():
    self.input_controls = self.get_node('InputControls')
    self.game_camera = self.get_node('GameCamera')
    self.frisbee_things = self.get_node('FrisbeeThings')
    self.disc = self.frisbee_things.get_node('Disc')
    self.players_controller = self.frisbee_things.get_node('Players')
    self.world_debug = self.get_node('WorldDebug')
    self.game_camera.make_current()
    self.players_controller.set_game_camera(self.game_camera)
    self.players_controller.set_disc(self.disc)
    self.input_controls.connect('set_pause_state', self.disc, 'set_pause_state')
    self.input_controls.connect('pan_start', self.game_camera, 'pan_start')
    self.input_controls.connect('pan_camera', self.game_camera, 'pan_camera')
    self.input_controls.connect('throw', self.disc, 'execute_throw')
    self.input_controls.connect('tap_location', self.players_controller, 'handle_screen_tap')
    # self.disc.connect('throw_started', self.player, 'disc_is_thrown')
    self.disc.connect('throw_started', self.world_debug, 'throw_calculated')
    self.disc.connect('throw_complete', self.game_camera, 'throw_complete')
    self.connect_player_signals()
    # self.player.connect('attack_point', self.world_debug, 'attack_point_calculated')
    # To start off with the camera focussed on the disc.
    self.game_camera.throw_complete(self.disc.path.translation)

func connect_player_signals():
    for p in self.players_controller.players:
        self.input_controls.connect('set_pause_state', p, 'set_pause_state')
        self.input_controls.connect('throw', p, 'start_throw_animation')
        self.disc.connect('throw_started', p, 'disc_is_thrown')
        p.connect('throw_animation_complete', self.disc, 'start_throw_animation')
        # p.connect('thrower_arm_position', self.disc, 'attach_to_wrist')

func check_player_selected():
    pass

# TODO (28 May 2019 sam): Godot keeps throwing up errors for a deleted scene and script
# called `Test.gd`. This clogs up the output, and is really annoying. Figure out how to
# let Godot know that the scene and script have been deleted.
