extends Spatial

var input_controls
var game_camera
var frisbee_things
var disc
var player
var player2
var world_debug

func _ready():
    self.input_controls = self.get_node('InputControls')
    self.game_camera = self.get_node('GameCamera')
    self.frisbee_things = self.get_node('FrisbeeThings')
    self.disc = self.frisbee_things.get_node('Disc')
    self.player = self.frisbee_things.get_node('Players').get_node('Player')
    self.player2 = self.frisbee_things.get_node('Players').get_node('Player2')
    self.world_debug = self.get_node('WorldDebug')
    self.input_controls.connect('pan_start', self.game_camera, 'pan_start')
    self.input_controls.connect('pan_camera', self.game_camera, 'pan_camera')
    self.input_controls.connect('throw', self.disc, 'execute_throw')
    self.input_controls.connect('mark_point', self.player, 'run_to_screen_point')
    self.disc.connect('throw_started', self.player, 'disc_is_thrown')
    self.disc.connect('throw_started', self.world_debug, 'throw_calculated')
    self.disc.connect('throw_complete', self.game_camera, 'throw_complete')
    self.player.connect('attack_point', self.world_debug, 'attack_point_calculated')
    self.player2.connect('thrower_arm_position', self.disc, 'attach_to_wrist')
    # To start off with the camera focussed on the disc.
    self.game_camera.throw_complete(self.disc.path.translation)

# TODO (28 May 2019 sam): Godot keeps throwing up errors for a deleted scene and script
# called `Test.gd`. This clogs up the output, and is really annoying. Figure out how to
# let Godot know that the scene and script have been deleted.
