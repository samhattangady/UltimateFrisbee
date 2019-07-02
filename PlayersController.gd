extends Spatial

export var number_of_players = 2

var game_camera
var selected_player
var disc
var players = []
var player_attack_bids = {}
var player_with_disc
var PLAYER_PIXEL_RADIUS = 25
var HEX_SPACING = 10.02

func _ready():
    self.create_players()
    var player = self.hex_with_back_2()
    player.assign_disc_possession()
    self.player_with_disc = player

func _process(delta):
    self.resolve_bids()

func set_positions():
    var player = self.hex_with_back_2()
    return player

func n_players():
    var player_scene = preload('res://Player.tscn')
    for i in range(number_of_players):
        var p = player_scene.instance()
        p.translation = Vector3(0.0, 0.0, -20.0*i)
        self.add_child(p)
        self.players.append(p)
        if i == 0:
            p.assign_disc_possession()
            self.player_with_disc = p

func create_players():
    # TODO (01 Jul 2019 sam): Clean up now that it is all simpler
    var player_scene = preload('res://Player.tscn')
    var back_1 = player_scene.instance()
    back_1.set_debug_name('back_2')
    self.add_child(back_1)
    self.players.append(back_1)
    var back_2 = player_scene.instance()
    back_2.set_debug_name('back_1')
    self.add_child(back_2)
    self.players.append(back_2)
    var wing_1 = player_scene.instance()
    wing_1.set_debug_name('wing_1')
    self.add_child(wing_1)
    self.players.append(wing_1)
    var hat = player_scene.instance()
    hat.set_debug_name('hat')
    self.add_child(hat)
    self.players.append(hat)
    var wing_2 = player_scene.instance()
    wing_2.set_debug_name('wing_2')
    self.add_child(wing_2)
    self.players.append(wing_2)
    var front_1 = player_scene.instance()
    front_1.set_debug_name('front_1')
    self.add_child(front_1)
    self.players.append(front_1)
    var front_2 = player_scene.instance()
    front_2.set_debug_name('front_2')
    self.add_child(front_2)
    self.players.append(front_2)

func hex_with_back_2():
    self.players[0].translation = Vector3 (0.0, 0.0, 0.0)
    self.players[1].translation = Vector3 (-2.0*HEX_SPACING, 0.0, -0.0*HEX_SPACING)
    self.players[2].translation = Vector3 (-3.0*HEX_SPACING, 0.0, -1.5*HEX_SPACING)
    self.players[3].translation = Vector3 (-1.0*HEX_SPACING, 0.0, -1.5*HEX_SPACING)
    self.players[4].translation = Vector3 (1.0*HEX_SPACING, 0.0, -1.5*HEX_SPACING)
    self.players[5].translation = Vector3 (-2.0*HEX_SPACING, 0.0, -3.0*HEX_SPACING)
    self.players[6].translation = Vector3 (0.0*HEX_SPACING, 0.0, -3.0*HEX_SPACING)
    return self.players[1]

func run_to_hex_with_back_2():
    # FIXME (01 Jul 2019 sam): Fails because player wiht disc is made to run?
    self.players[0].run_to_world_point(Vector3 (0.0, 0.0, 0.0))
    self.players[1].run_to_world_point(Vector3 (-2.0*HEX_SPACING, 0.0, -0.0*HEX_SPACING))
    self.players[2].run_to_world_point(Vector3 (-3.0*HEX_SPACING, 0.0, -1.5*HEX_SPACING))
    self.players[3].run_to_world_point(Vector3 (-1.0*HEX_SPACING, 0.0, -1.5*HEX_SPACING))
    self.players[4].run_to_world_point(Vector3 (1.0*HEX_SPACING, 0.0, -1.5*HEX_SPACING))
    self.players[5].run_to_world_point(Vector3 (-2.0*HEX_SPACING, 0.0, -3.0*HEX_SPACING))
    self.players[6].run_to_world_point(Vector3 (0.0*HEX_SPACING, 0.0, -3.0*HEX_SPACING))
    return self.players[0]

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
        var world_point = self.disc.get_point_in_world(point)
        if world_point:
            self.selected_player.run_to_world_point(world_point)

func player_trying_to_catch_disc(player):
    if self.player_with_disc == null:
        player.catch_disc()
        self.player_with_disc = player
        for p in self.players:
            if p.state_is_thrown():
                p.set_idle()

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

func start_throw(throw_data):
    if self.player_with_disc:
        self.player_with_disc.start_throw_animation(throw_data)
        self.player_with_disc = null

func disc_is_caught(player):
    self.player_with_disc = player

func players_bidding_to_attack_disc(player, attack_point):
    self.player_attack_bids[player] = attack_point

func resolve_bids():
    if self.player_attack_bids.size() == 0:
        return
    var bidders = 'Bidders: '
    var best_time = pow(10, 10)
    var best_player = null
    for player in self.player_attack_bids.keys():
        bidders += ', ' + player.debug_name
        var time = self.player_attack_bids[player].time_to_catch
        if time < best_time:
            best_time = time
            best_player = player
    best_player.attack_disc(self.player_attack_bids[best_player])
    self.player_attack_bids = {}


# TODO (31 May 2019 sam): So there is a problem with using direct pixel values. Pixel
# has very high hdpi or whatever, so the pixel ratios are terribly small, and unclickable# Need to see how to fix that.
