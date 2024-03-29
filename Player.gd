extends KinematicBody

export var max_speed = 20
export var acceleration = 50.0
export var deceleration = 50.0
export var MAX_ANGLE_WITHOUT_STOPPING = 60
export var AT_DESTINATION_DISTANCE = 0.5
export var DISC_CATCHING_DISTANCE = 1.0
export var TIME_DIFFERENCE_TO_CATCH = 0.2

var CLAP_CATCH_ANIMATION_LENGTH = 1.0

var current_direction = Vector3(1, 0, 0)
var current_velocity = Vector3(0, 0, 0)
var desired_direction = Vector3(0, 0, -1)
var desired_destination = Vector3(0, 0, -1)

enum PLAYER_STATE {
    IDLE,
    RUNNING,
    WITH_DISC,
    THROWING,
    THROWN,
}
var player_model
var right_hand
var disc
var skeleton
var animation_player
var animation_tree
var selected_marker
var has_disc = false
var is_selected
var disc_calculator
var current_state
var pause_state
var catching_area
var debug_name
var time_remaining_to_catch
var playing_catch_anim = false
var offence_flag
var shirt_material

var debug_starting_time
var debug=true

# Signal to attach the disc to the throwers arm
signal thrower_arm_position(transform)
# Signal to start throw
signal throw_animation_complete()
# Signal to say that they have caught the disc
signal disc_is_caught(player)
signal try_to_catch_disc(player)
signal bid_to_attack_disc(player, attack_point)

signal debug_point(disc_pos, debug_string)
signal clear_debug_points()

func _ready():
    self.player_model = self.get_node('PlayerModel')
    self.animation_player = self.player_model.get_node('AnimationPlayer')
    self.animation_tree = self.player_model.get_node('AnimationTree')
    self.selected_marker = self.get_node('SelectedMarker')
    self.disc_calculator = load('DiscCalculator.gd').new()
    self.animation_player.get_animation('Idle').set_loop(true)
    self.animation_player.get_animation('Run').set_loop(true)
    self.animation_player.play('Run')
    self.skeleton = self.player_model.get_node('Armature')
    self.right_hand = self.skeleton.find_bone('Wrist.R')
    self.animation_player.connect('animation_finished', self, 'handle_animation_completion')
    self.animation_player.play('Idle')
    self.current_state = PLAYER_STATE.IDLE
    self.animation_tree.active = false
    self.catching_area = self.get_node('CatchingArea')
    self.time_remaining_to_catch = 0
    if self.has_disc:
        self.update_arm_position()

func _physics_process(delta):
    if !self.pause_state:
        if self.current_state == PLAYER_STATE.RUNNING:
            self.recalculate_current_velocity(delta)
            self.move_and_slide(self.current_velocity, Vector3(0, -1, 0))
        if self.current_velocity.length() > 1.0:
            var blend_amount = self.current_velocity.length() / self.max_speed
            self.animation_tree.set('parameters/Idle-Run/blend_amount', blend_amount)
            # FIXME (25 Jun 2019 sam): The blending is no longer working with the new model
            self.animation_player.play('Run')
            # self.animation_tree.active = true
            if self.playing_catch_anim:
                self.animation_player.play('Catching')
        else:
            self.animation_tree.active = false
        if self.check_if_disc_is_catchable():
            self.try_to_catch_disc()
        if self.check_if_at_destination():
            self.stop_running()
        if self.has_disc:
            self.update_arm_position()
        if self.time_remaining_to_catch > self.CLAP_CATCH_ANIMATION_LENGTH:
            self.time_remaining_to_catch -= delta
            if self.time_remaining_to_catch <= self.CLAP_CATCH_ANIMATION_LENGTH:
                pass
                # TODO (19 Jun 2019 sam): Add the catching state to player states
                # self.playing_catch_anim = true
                # self.animation_player.play('Catching', -1, 1.0, false)

func get_wrist_position():
    # TODO (18 Jun 2019 sam): We need to add rotation aspect here I think
    var relative_translation = self.skeleton.get_bone_global_pose(self.right_hand).origin
    return self.transform.translated(relative_translation)

func set_disc(disc):
    self.disc = disc

func check_if_at_destination():
    if self.current_state == PLAYER_STATE.RUNNING:
        return self.translation.distance_to(self.desired_destination) < self.AT_DESTINATION_DISTANCE
    return false

func stop_running():
    self.current_velocity = Vector3(0, 0, 0)
    self.animation_player.play('Idle')
    self.current_state = PLAYER_STATE.IDLE

func check_if_disc_is_catchable():
    if self.current_state == PLAYER_STATE.THROWN or self.current_state == PLAYER_STATE.THROWING or self.current_state == PLAYER_STATE.WITH_DISC:
        return false
    return self.catching_area.overlaps_body(self.disc.body)

func try_to_catch_disc():
    self.emit_signal('try_to_catch_disc', self)

func catch_disc():
    # !AnimationHook Catching the disc
    self.current_velocity = Vector3(0, 0, 0)
    self.animation_player.play('Idle')
    self.current_state = PLAYER_STATE.IDLE
    self.set_deselected()
    self.assign_disc_possession()
    self.disc.disc_is_reached()
    # self.animation_player.play('Catching')
    self.animation_player.play('Idle')
    self.emit_signal('disc_is_caught', self)
    # self.emit_signal('thrower_arm_position', self.get_wrist_position())

func recalculate_current_velocity(delta):
    # If we are running in desired direction, accelerate to max_speed
    # Otherwise, depending on the angle change,
    #   0-60: Maintain the component of speed along that direction.
    #   >60: decelerate to 0, and change to desired direction
    # TODO (03 Jun 2019 sam): If the player is bumped off course, then they keep
    # running to infinity. Ideally, they should be adjusting course.
    var change_of_angle = abs(rad2deg(self.current_direction.angle_to(self.desired_direction)))
    if change_of_angle < self.MAX_ANGLE_WITHOUT_STOPPING:
        self.current_velocity = self.current_velocity.project(self.desired_direction)
        self.current_direction = self.desired_direction
        if self.current_velocity.length() < self.max_speed:
            self.current_velocity += self.current_direction*self.acceleration*delta
        if self.current_velocity.length() > self.max_speed:
            self.current_velocity = self.current_direction*max_speed
    else:
        # !AnimationHook - Chopstop / sliding
        # FIXME (21 Jun 2019 sam): Deceleration doesn't seem to be working correctly
        self.current_velocity -= self.current_direction*self.deceleration*delta
        if self.current_velocity.normalized() != self.current_direction:
            self.current_velocity = Vector3(0, 0, 0)
            self.run_to_world_point(self.desired_destination)
            self.current_direction = self.desired_direction

func set_desired_direction(dir):
    self.desired_direction = dir.normalized()
    # TODO (22 May 2019 sam): Figure out where the rotation should be changed
    rotation.y = atan2(desired_direction.x, desired_direction.z)

func update_arm_position():
    self.emit_signal('thrower_arm_position', self.get_wrist_position())

func start_throw_animation(throw_data):
    # We want to rotate to face where the throw is going. Note that by default the model is facing backwards. So we have to adjust the look_at point accordingly.
    # TODO (18 Jun 2019 sam): Check if this rotation is working correctly. Sometimes the
    # guy is pointing the wrong way.
    # TODO (19 Jun 2019 sam): Ensure that end point is not nil. Make it cleaner
    var point = self.disc.get_point_in_world(throw_data['end'])
    if point == null: return
    self.transform = self.transform.looking_at(self.translation - point, Vector3(0, 1, 0))
    self.animation_player.play(throw_data['throw'], -1, 1.3, false)
    self.current_state = PLAYER_STATE.THROWING
    # TODO (31 May 2019 sam): Add some sort of timer here to switch the state to idle
    # UPDATE (Jul 01 2019 sam): I think this has been sorted by
    # creating the multiple animations?

func handle_animation_completion(anim_name):
    if anim_name == 'Forehand' or anim_name == 'Backhand':
        self.emit_signal('throw_animation_complete')
        self.has_disc = false
        self.current_state = PLAYER_STATE.THROWN
        if anim_name == 'Backhand':
            self.animation_player.play('Backhand.FollowThrough')
        if anim_name == 'Forehand':
            self.animation_player.play('Forehand.FollowThrough')
    elif anim_name != 'Idle':
        self.animation_player.play('Idle')
    if anim_name == 'Catching':
        self.playing_catch_anim = false

func set_selected():
    self.is_selected = true
    self.selected_marker.visible = true

func set_deselected():
    self.is_selected = false
    self.selected_marker.visible = false

func run_to_world_point(destination):
    if self.has_disc:
        # (19 Jun 2019 sam): Will have to figure out what to do here when we
        # have to walk the disc to the line etc.
        return
    self.desired_destination = destination
    var dir = destination - self.translation
    self.set_desired_direction(dir)
    self.debug_starting_time = OS.get_ticks_msec()
    self.current_state = PLAYER_STATE.RUNNING

func disc_is_thrown(curve, throw_details):
    if self.current_state == PLAYER_STATE.THROWN or self.current_state == PLAYER_STATE.THROWING or self.current_state == PLAYER_STATE.WITH_DISC:
        return
    var attack_point = self.calculate_attack_point(curve, throw_details)
    # TODO: If noone is bidding, we still want someone to run toward the falling disc
    # Also, we need to consider once there is defence, we may want multiple people
    # attacking the disc at the same time.
    if self.current_state == PLAYER_STATE.RUNNING or attack_point.time_difference < self.TIME_DIFFERENCE_TO_CATCH:
        self.emit_signal('bid_to_attack_disc', self, attack_point)

func attack_disc(attack_point):
    self.run_to_world_point(attack_point.point)
    self.time_remaining_to_catch = attack_point.time_to_catch

func calculate_attack_point(curve, throw_details):
    # We take different points along the flight of the disc, and measure the
    # time that the disc would take to get there, as well as the time that the
    # player would take to get there. Whichever point has the least difference
    # between the two, that is the attack point, and the player looks to catch
    # the disc there.
    # TODO (28 May 2019 sam): When calculating this point, we also need to see
    # if it falls within some radius (is it really catchable at that point). This
    # also requires us to constrain running to directions with y=0, and also figure
    # out how to add jumping into this calculation, both with regards to skying and
    # laying out.
    var number_of_samples = 1000
    var best_point = -1
    var best_time_difference = pow(10, 10)
    var time_to_catch = 0
    for i in range(number_of_samples):
        var time_sample = (i+1) * throw_details['time'] / number_of_samples
        var offset_sample = self.disc_calculator.get_disc_offset(time_sample, throw_details['time'], throw_details['max_speed'], throw_details['min_speed'])
        var disc_pos = curve.interpolate_baked(offset_sample * curve.get_baked_length())
        if not self.catchable_at_point(disc_pos):
            continue
        var catching_point = disc_pos
        # Clamp to ground
        catching_point.y = 0.0
        var time_to_point = self.get_time_to_point(catching_point, self.translation, self.current_direction, self.current_velocity)
        if abs(time_to_point - time_sample) < best_time_difference:
            best_time_difference = abs(time_to_point-time_sample)
            best_point = catching_point
            time_to_catch = time_sample
    return {'point': best_point,
               'time_difference': best_time_difference,
               'time_to_catch': time_to_catch}

func catchable_at_point(disc_pos):
    # Currently on checks altitude of disc and whether that's catchable.
    # TODO (01 Jul 2019 sam): owner_id, shape_id currently hardcoded.
    # NOTE (01 Jul 2019 sam): get_extents gets half_extents, which is some random
    # confusing nonsense. BUT, all I need is the y, so I'm okay for now
    var highest_catchable_point = self.catching_area.shape_owner_get_shape(0, 0).get_extents().y * 2
    return highest_catchable_point > disc_pos.y

func get_time_to_point(point, pos, dir, vel):
    # Get the time it would take to move to a certain point
    # For further details, refer to `recalculate_current_velocity`
    # There are 3 possible states. Decelerating, accelerating, max_speed.
    # The player could start in any one of these phases, and then move on to the
    # next phase in the cycle.
    var total_time = 0.0
    var direction_to_point = (point-pos).normalized()
    var change_of_angle = abs(rad2deg(dir.angle_to(direction_to_point)))
    # State 1: Decelerating
    if change_of_angle > MAX_ANGLE_WITHOUT_STOPPING:
        # We need to calculate the point at which the velocity is 0
        # Chopstop / sliding
        var time_to_stop = (vel.length()) / self.deceleration
        var distance_to_stop = (-pow(vel.length(), 2)) / (2*self.deceleration)
        pos += dir*(distance_to_stop)
        dir = direction_to_point
        vel = Vector3(0, 0, 0)
        change_of_angle = abs(rad2deg(dir.angle_to(direction_to_point)))
        total_time += time_to_stop
    if change_of_angle <= MAX_ANGLE_WITHOUT_STOPPING:
        vel = vel.project(direction_to_point)
        dir = direction_to_point
    # State 2: Accelerating
    if vel.length() < self.max_speed:
        # We need to calculate the time and distance to max_speed
        var time_to_max = (self.max_speed-vel.length()) / self.acceleration
        var distance_to_max = (pow(self.max_speed, 2) - pow(vel.length(), 2)) / (2*self.acceleration)
        pos += direction_to_point*(distance_to_max)
        vel = self.max_speed*dir
        total_time += time_to_max
    # State 3: At max speed. We don't need any checks at this point
    var time_to_point = point.distance_to(pos) / self.max_speed
    total_time +=  time_to_point
    return total_time

func set_pause_state(state):
    self.pause_state = state
    self.animation_player.set_active(!self.pause_state)

func assign_disc_possession():
    self.has_disc = true
    self.current_state = PLAYER_STATE.WITH_DISC

func set_idle():
    self.current_state = PLAYER_STATE.IDLE

func set_debug_name(name):
    self.debug_name = name

func get_debug_name():
    return self.debug_name

func state_is_thrown():
    return self.current_state == PLAYER_STATE.THROWN

func set_as_offence():
    # set color of offence jersey
    self.offence_flag = true

func set_as_defence():
    # set color of defence jersey
    self.player_model.set_yellow()
    self.offence_flag = false

func is_offence():
    return self.offence_flag

func is_defence():
    return not self.offence_flag

# FIXME (03 Jul 2019 sam): When a throw is made to end out of bounds, then the next
# throws cannot be made. Some very wierd behaviour begins there. Look into it babes.
