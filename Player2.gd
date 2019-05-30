extends Spatial

var right_hand
var skeleton
var wrist_rest_position

signal thrower_arm_position(transform)

func _ready():
    var animation_player = self.get_node('AnimationPlayer')
    animation_player.get_animation('Forehand').set_loop(true)
    animation_player.play('Forehand')
    self.skeleton = self.get_node('Armature').get_node('Skeleton')
    self.right_hand = self.skeleton.find_bone('Wrist.R')
    self.wrist_rest_position = self.skeleton.get_bone_transform(right_hand)

func _process(delta):
    var global_transform = self.skeleton.get_bone_transform(right_hand)
    self.emit_signal('thrower_arm_position', global_transform)
