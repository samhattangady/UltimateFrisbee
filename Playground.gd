extends Spatial

var player
var cube
var animation_player

func _ready():
    self.player = self.get_node('PlayerModel')
    self.animation_player = self.get_node('PlayerModel/AnimationPlayer')
#    self.player.connect('thrower_arm_position', self, 'update_pos')

#func update_pos(trans):
#    # print(trans)
#    self.cube.transform = trans[1].translated(trans[0])
#    self.cube.scale = Vector3(0.2, 0.2, 0.2)
#    # self.cube.translation = trans[0]

func _input(event):
    if event.is_action_pressed('ui_right'):
        self.animation_player.play('Forehand')
    if event.is_action_pressed('ui_left'):
        self.animation_player.play('Backhand')
    if event.is_action_pressed('ui_accept'):
        self.animation_player.play('Run')

