extends Spatial

export var number_of_players = 2

var game_camera
var selected_player
var disc
var players = []
var PLAYER_PIXEL_RADIUS = 25

func _ready():
    var player_scene = preload('res://Player2.tscn')
    for i in range(number_of_players):
        var p = player_scene.instance()
        p.translation = Vector3(0.0, 0.0, -10.0*i)
        p.scale = Vector3(2, 2, 2)
        if i == 0:
            p.has_disc = true
        self.add_child(p)
        self.players.append(p)

func set_game_camera(camera):
    self.game_camera = camera

func set_disc(disc):
    self.disc = disc
    for player in self.players:
        player.set_disc(disc)

func handle_screen_tap(point):
    # First check if the tap is selecting/deselecting any player
    var current_player = self.is_player_being_selected(point)
    if current_player:
        # If it is, then either deselect the current player, or select new player
        if current_player == self.selected_player:
            current_player.set_deselected()
            self.selected_player = null
        else:
            self.deselect_all_players()
            self.selected_player = current_player
            current_player.set_selected()
    elif self.selected_player:
        # Then make player run to that point
        var world_point = self.get_point_in_world(point)
        if world_point:
            self.selected_player.run_to_world_point(world_point.position)

func is_player_being_selected(point):
    for player in self.players:
        # TODO (30 May 2019 sam): If there are 2 players very close to each other
        # this will always select the one who was generated first.
        # TODO (30 May 2019 sam): Select players based on the translation of their
        # hips, not their feet.
        var screen_position = self.game_camera.unproject_position(player.translation)
        if screen_position.distance_to(point) < self.PLAYER_PIXEL_RADIUS:
            return player
    return null

func deselect_all_players():
    for player in self.players:
        player.set_deselected()
    
func get_point_in_world(position):
    # converts point on screen to point in world
    # TODO (08 May 2019 sam): Camera has project_position. See if it's better
    # TODO (08 May 2019 sam): Currently saying get_parent() multiple times
    # See if there is a more elegant approach that isn't so hardcoded.
    # TODO (22 May 2019 sam): This is a very commonly used function. Figure out
    # how it can be used in different places without having to got through all
    # this copy-pasting
    var start_point = self.game_camera.project_ray_origin(position)
    # TODO (15 May 2019 sam): The 10000 marked below is hardcoded. It is meant
    # to ensure that the ray is long enough to intersect with the ground in all
    # cases. See if there is a better way to do this.
    var end_point = start_point + 10000*self.game_camera.project_ray_normal(position)
    var point = get_world().direct_space_state.intersect_ray(start_point, end_point)
    return point

