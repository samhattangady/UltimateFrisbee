extends KinematicBody

export var max_speed = 500
export var acceleration = 50
export var deceleration = 50

var current_velocity = Vector3(0, 0, 0)
var desired_direction
var current_direction
var position
var random

func _ready():
    random = RandomNumberGenerator.new()
    reset_position()
    current_direction = desired_direction
    scale = Vector3(2,2,2)
    var animation_player = get_node("AnimationPlayer")
    get_node("AnimationPlayer").get_animation("Run").set_loop(true)
    animation_player.play("Run")

func _input(event):
    if event.is_action_pressed("ui_right"):
        reset_position()
    if event.is_action_pressed("ui_up"):
        randomize_desired_direction()

func _physics_process(delta):
    recalculate_current_velocity(delta)
    move_and_slide(current_velocity, Vector3(0, -1, 0))

func recalculate_current_velocity(delta):
    # If we are running in desired direction, accelerate to max_speed
    # Otherwise, depending on the angle change,
    #   0-60: Maintain the component of speed along that direction.
    #   15-45: Some kind of banana cut. Try just adding the two directions
    #   45-90: Decelerate to the correct component, and change to 
    #   >90: decelerate to 0, and change to desired direction
    var change_of_angle = abs(rad2deg(current_direction.angle_to(desired_direction)))
    if change_of_angle < 60:
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
    var animation_player = get_node("AnimationPlayer")
    current_velocity = Vector3(0, 0, 0)
    get_node("AnimationPlayer").get_animation("Run").set_loop(true)
    animation_player.play("Idle")

func _on_CatchArea_body_exited(body):
    var animation_player = get_node("AnimationPlayer")
    get_node("AnimationPlayer").get_animation("Run").set_loop(true)
    animation_player.play("Run")

func run_to_screen_point(point):
    var destination = get_point_in_world(point)
    run_to_world_point(destination)

func run_to_world_point(destination):
    var dir = destination - self.translation
    set_desired_direction(dir)

func disc_is_thrown(curve):
    var landing_point = curve.get_point_position(curve.get_point_count()-1)
    run_to_world_point(landing_point)

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
