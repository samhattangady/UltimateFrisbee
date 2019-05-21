extends Spatial

export var number_of_cutters = 0

var player

func _ready():
    player = preload("res://Player.tscn")
    for i in range(number_of_cutters):
        var p = player.instance()
        add_child(p)
        # FIXME (15 May 2019 sam): Calling reset_position() i times. If this
        # is not done, all the instances seem to have the same random seed, and
        # this causes a lot of weird bugs.
        for j in range(i+1):
            p.reset_position()


