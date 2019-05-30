extends KinematicBody

export var max_speed = 500
export var acceleration = 50
export var deceleration = 50
export var MAX_ANGLE_WITHOUT_STOPPING = 60

var DISC_CALCULATOR
var current_velocity = Vector3(0, 0, 0)
var desired_direction
var current_direction
var position
var random

signal attack_point(point)

func _ready():
    DISC_CALCULATOR = load('DiscCalculator.gd').new()
    random = RandomNumberGenerator.new()
    reset_position()
    current_direction = desired_direction
    scale = Vector3(2,2,2)
    var animation_player = get_node('AnimationPlayer')
    get_node('AnimationPlayer').get_animation('Run').set_loop(true)
    animation_player.play('Run')

func _input(event):
    if event.is_action_pressed('ui_right'):
        reset_position()
    if event.is_action_pressed('ui_up'):
        randomize_desired_direction()

func _physics_process(delta):
    recalculate_current_velocity(delta)
    move_and_slide(current_velocity, Vector3(0, -1, 0))

func recalculate_current_velocity(delta):
    # If we are running in desired direction, accelerate to max_speed
    # Otherwise, depending on the angle change,
    #   0-60: Maintain the component of speed along that direction.
    #   >60: decelerate to 0, and change to desired direction
    var change_of_angle = abs(rad2deg(current_direction.angle_to(desired_direction)))
    if change_of_angle < MAX_ANGLE_WITHOUT_STOPPING:
        current_velocity = current_velocity.project(desired_direction)
        current_direction = desired_direction
        if current_velocity.length() < max_speed:
            current_velocity += current_direction*acceleration*delta
        if current_velocity.length() > max_speed:
            current_velocity = current_direction*max_speed
    else:
        # !AnimationHook - Chopstop / sliding
        current_velocity -= current_direction*deceleration * delta
        if current_velocity.normalized() != current_direction:
            current_velocity = Vector3(0, 0, 0)
            current_direction = desired_direction

func reset_position():
    randomize_desired_direction()
    randomize_position()
    translation = position

func _on_Button_button_up():
    reset_position()

func set_desired_direction(dir):
    desired_direction = dir.normalized()
    # TODO (22 May 2019 sam): Figure out where the rotation should be changed
    rotation.y = atan2(desired_direction.x, desired_direction.z)

func set_position(pos):
    position = pos

func randomize_desired_direction():
    set_desired_direction(Vector3(random.randf_range(-1.0, 1.0), 0.0, random.randf_range(-1.0, 1.0)))

func randomize_position():
    set_position(Vector3(random.randf_range(-10.0, 10.0), 0, random.randf_range(-10.0, 10.0)))

func _on_CatchArea_body_entered(body):
    var animation_player = get_node('AnimationPlayer')
    current_velocity = Vector3(0, 0, 0)
    get_node('AnimationPlayer').get_animation('Run').set_loop(true)
    animation_player.play('Idle')

func _on_CatchArea_body_exited(body):
    var animation_player = get_node('AnimationPlayer')
    get_node('AnimationPlayer').get_animation('Run').set_loop(true)
    animation_player.play('Run')

func run_to_screen_point(point):
    var destination = get_point_in_world(point)
    run_to_world_point(destination)

func run_to_world_point(destination):
    var dir = destination - self.translation
    set_desired_direction(dir)

func disc_is_thrown(curve, throw_time):
    var attack_point = calculate_attack_point(curve, throw_time)
    self.emit_signal('attack_point', attack_point)
    run_to_world_point(attack_point)

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
    var number_of_samples = 9
    var best_point = -1
    var best_time_difference = pow(10, 10)
    for i in range(number_of_samples):
        var time_sample = (i+1) * throw_details['time'] / number_of_samples
        var offset_sample = DISC_CALCULATOR.get_disc_offset(time_sample, throw_details['time'], throw_details['max_speed'], throw_details['min_speed'])
        var sample_point = curve.interpolate_baked(offset_sample * curve.get_baked_length())
        var time_to_point = self.get_time_to_point(sample_point, self.translation, self.current_direction, self.current_velocity)
        if abs(time_to_point - time_sample) < best_time_difference:
            best_time_difference = abs(time_to_point-time_sample)
            best_point = sample_point
    return best_point

func get_time_to_point(point, pos, dir, vel):
    # Get the time it would take to move to a certain point
    # For further details, refer to `recalculate_current_velocity`
    # We use the pos, dir and vel here so that we can be a little recursive
    var direction_to_point = (point - pos).normalized()
    var change_of_angle = abs(rad2deg(dir.angle_to(direction_to_point)))
    if change_of_angle < 1 and vel.length() != 0:
        return point.distance_to(pos) / vel.length()
    if change_of_angle < MAX_ANGLE_WITHOUT_STOPPING:
        var initial_velocity = vel.project(direction_to_point)
        if initial_velocity.length() < self.max_speed:
            # calculate time to reach max speed, and position at that time
            var time_to_max = (self.max_speed-initial_velocity.length()) / self.acceleration
            var distance_to_max = (pow(self.max_speed, 2) - pow(vel.length(), 2)) / (2*self.acceleration)
            var pos_at_max = pos + direction_to_point*(distance_to_max)
            return time_to_max + self.get_time_to_point(point, pos_at_max, direction_to_point, self.max_speed*direction_to_point)
    else:
        # Chopstop / sliding
        var time_to_stop = (vel.length()) / self.deceleration
        var distance_to_stop = (-pow(vel.length(), 2)) / (2*self.deceleration)
        var pos_at_stop = pos + dir*(distance_to_stop)
        var new_dir = (point-pos_at_stop).normalized()
        return time_to_stop + self.get_time_to_point(point, pos_at_stop, new_dir, Vector3(0, 0, 0))

func get_point_in_world(position):
    # converts point on screen to point in world
    # TODO (08 May 2019 sam): Camera has project_position. See if it's better
    # TODO (08 May 2019 sam): Currently saying get_parent() multiple times
    # See if there is a more elegant approach that isn't so hardcoded.
    # TODO (22 May 2019 sam): This is a very commonly used function. Figure out
    # how it can be used in different places without having to got through all
    # this copy-pasting
    var camera = get_tree().get_root().get_node('PlayingField/GameCamera')
    var start_point = camera.project_ray_origin(position)
    # TODO (15 May 2019 sam): The 10000 marked below is hardcoded. It is meant
    # to ensure that the ray is long enough to intersect with the ground in all
    # cases. See if there is a better way to do this.
    var end_point = start_point + 10000*camera.project_ray_normal(position)
    var point = get_world().direct_space_state.intersect_ray(start_point, end_point)
    if not point: return
    return point.position

