extends KinematicBody

export var max_speed = 8
export var acceleration = 10
export var deceleration = 10
export var MAX_ANGLE_WITHOUT_STOPPING = 60
export var AT_DESTINATION_DISTANCE = 1.5
export var DISC_CATCHING_DISTANCE = 1.0

var current_direction = Vector3(1, 0, 0)
var current_velocity = Vector3(-1, 0, 0)
var desired_direction = Vector3(0, 0, -1)
var desired_destination = Vector3(0, 0, -1)

enum PLAYER_STATE {
    IDLE,
    RUNNING,
    WITH_DISC,
    THROWING,
    THROWN,
}
var right_hand
var disc
var skeleton
var wrist_rest_position
var animation_player
var selected_marker
var has_disc = false
var is_selected
var disc_calculator
var current_state
var pause_state
var centre_point

var debug_starting_time

# Signal to attach the disc to the throwers arm
signal thrower_arm_position(transform)
# Signal to start throw
signal throw_animation_complete()
# Signal to say that they have caught the disc
signal disc_is_caught(player)

func _ready():
    self.animation_player = self.get_node('AnimationPlayer')
    self.selected_marker = self.get_node('SelectedMarker')
    self.disc_calculator = load('DiscCalculator.gd').new()
    self.animation_player.get_animation('Idle').set_loop(true)
    self.animation_player.get_animation('ArmatureAction').set_loop(true)
    self.animation_player.play('Idle')
    self.skeleton = self.get_node('Armature').get_node('Skeleton')
    self.right_hand = self.skeleton.find_bone('Wrist.R')
    self.wrist_rest_position = self.skeleton.get_bone_transform(right_hand)
    self.animation_player.connect('animation_finished', self, 'handle_animation_completion')
    self.current_state = PLAYER_STATE.IDLE
    self.centre_point = self.get_node('CollisionShape')

func _physics_process(delta):
    if !self.pause_state:
        if self.current_state == PLAYER_STATE.RUNNING:
            self.recalculate_current_velocity(delta)
            self.move_and_slide(self.current_velocity, Vector3(0, -1, 0))
        if self.current_velocity.length() > 1.0:
            self.animation_player.play('ArmatureAction')
        if self.check_if_disc_is_catchable():
            self.catch_disc()
        if self.check_if_at_destination():
            self.stop_running()

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
    return (self.centre_point.translation + self.translation).distance_to(self.disc.get_position()) < self.DISC_CATCHING_DISTANCE

func catch_disc():
    self.set_deselected()
    # self.assign_disc_possession()
    self.has_disc = true
    self.current_state = PLAYER_STATE.WITH_DISC
    self.disc.disc_is_reached()
    self.current_velocity = Vector3(0, 0, 0)
    self.animation_player.play('Idle')
    self.emit_signal('disc_is_caught', self)

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
        self.current_velocity -= self.current_direction*self.deceleration * delta
        if self.current_velocity.normalized() != self.current_direction:
            self.current_velocity = Vector3(0, 0, 0)
            self.run_to_world_point(self.desired_destination)
            self.current_direction = self.desired_direction

func set_desired_direction(dir):
    self.desired_direction = dir.normalized()
    # TODO (22 May 2019 sam): Figure out where the rotation should be changed
    rotation.y = atan2(desired_direction.x, desired_direction.z)

func update_arm_position():
    var global_transform = self.skeleton.get_bone_global_pose(right_hand)
    self.emit_signal('thrower_arm_position', global_transform)

func start_throw_animation(throw_data):
    self.animation_player.play(throw_data['throw'], -1, 3.0, false)
    self.current_state = PLAYER_STATE.THROWING
    # TODO (31 May 2019 sam): Add some sort of timer here to switch the state to idle

func handle_animation_completion(anim_name):
    if anim_name == 'Forehand' or anim_name == 'Backhand':
        self.emit_signal('throw_animation_complete')
        self.has_disc = false
        self.current_state = PLAYER_STATE.THROWN
    if anim_name != 'Idle':
        self.animation_player.play('Idle')

func set_selected():
    self.is_selected = true
    self.selected_marker.visible = true

func set_deselected():
    self.is_selected = false
    self.selected_marker.visible = false

func run_to_world_point(destination):
    self.desired_destination = destination
    var dir = destination - self.translation
    self.set_desired_direction(dir)
    self.debug_starting_time = OS.get_ticks_msec()
    self.current_state = PLAYER_STATE.RUNNING

func disc_is_thrown(curve, throw_details):
    var attack_point = self.calculate_attack_point(curve, throw_details)
    if self.current_state == PLAYER_STATE.RUNNING or attack_point.time < 1.0:
        self.run_to_world_point(attack_point.point)

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
    var number_of_samples = 100
    var best_point = -1
    var best_time_difference = pow(10, 10)
    for i in range(number_of_samples):
        var time_sample = (i+1) * throw_details['time'] / number_of_samples
        var offset_sample = self.disc_calculator.get_disc_offset(time_sample, throw_details['time'], throw_details['max_speed'], throw_details['min_speed'])
        var sample_point = curve.interpolate_baked(offset_sample * curve.get_baked_length())
        # Clamp point to ground
        sample_point.y = 0.0
        var time_to_point = self.get_time_to_point(sample_point, self.translation, self.current_direction, self.current_velocity)
        if abs(time_to_point - time_sample) < best_time_difference:
            best_time_difference = abs(time_to_point-time_sample)
            best_point = sample_point
    return {'point': best_point, 'time': best_time_difference}

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
        dir = (point-pos).normalized()
        vel = Vector3(0, 0, 0)
        change_of_angle = abs(rad2deg(dir.angle_to(direction_to_point)))
        total_time += time_to_stop
    if change_of_angle <= MAX_ANGLE_WITHOUT_STOPPING:
        vel = vel.project(direction_to_point)
    # State 2: Accelerating
    if vel.length() < self.max_speed:
        # We need to calculate the time and distance to max_speed
        var time_to_max = (self.max_speed-vel.length()) / self.acceleration
        var distance_to_max = (pow(self.max_speed, 2) - pow(vel.length(), 2)) / (2*self.acceleration)
        pos += direction_to_point*(distance_to_max)
        dir = direction_to_point
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
