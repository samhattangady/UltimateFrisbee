extends Node

onready var disc = get_parent().get_node('FrisbeeThings').get_node('Disc')
var players_controller
var player_labels
var game_camera
var debug_points

var debug = true

func _ready():
    self.player_labels = self.get_node('PlayerLabels')
    self.game_camera = self.get_parent().get_node('GameCamera')
    self.debug_points = []

func _physics_process(delta):
    if not self.debug:
        return
    if not self.players_controller:
        return
    for child in self.player_labels.get_children():
        self.player_labels.remove_child(child)
    for player in self.players_controller.players:
        var l = Label.new()
        l.text = player.get_debug_name()
        l.rect_position = self.game_camera.unproject_position(player.translation+Vector3(0,2,0))
        self.player_labels.add_child(l)
    for p in self.debug_points:
        var l = Label.new()
        l.text = p.string
        l.rect_position = self.game_camera.unproject_position(p.pos)
        self.player_labels.add_child(l)
        
func debug_point(point, string):
    self.debug_points.append({'pos': point, 'string':string})

func clear_debug_points():
    self.debug_points = []

func set_player_controller(pc):
    self.players_controller = pc
