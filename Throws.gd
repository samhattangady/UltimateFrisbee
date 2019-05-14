extends Spatial

export var number_of_cutters = 50

var player
var random

func _ready():
    random = RandomNumberGenerator.new()
    player = preload("res://Player.tscn")
    for i in range(number_of_cutters):
        generate_random_cutter()

func generate_random_cutter():
    var p = player.instance()
    # set pos and direction and instantiate
