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
    # If we are running in desired direction, accelerate to max_speed
    # Otherwise, decelerate to 0, and change to desired direction
    if current_direction == desired_direction:
        if current_velocity.length() < max_speed:
            current_velocity += current_direction*acceleration*delta
        if current_velocity.length() > max_speed:
            current_velocity = current_direction*max_speed
    else:
        current_velocity -= current_direction*deceleration * delta
        if current_velocity.normalized() != current_direction:
            current_velocity = Vector3(0, 0, 0)
            current_direction = desired_direction
    move_and_slide(current_velocity, Vector3(0, -1, 0))

func reset_position():
    randomize_desired_direction()
    randomize_position()
    translation = position

func _on_Button_button_up():
    reset_position()

func set_desired_direction(dir):
    desired_direction = dir.normalized()
    rotation.y = atan2(desired_direction.x, desired_direction.z)

func set_position(pos):
    position = pos

func randomize_desired_direction():
    set_desired_direction(Vector3(random.randf_range(-1.0, 1.0), 0.0, random.randf_range(-1.0, 1.0)))

func randomize_position():
    set_position(Vector3(random.randf_range(-10.0, 10.0), 0, random.randf_range(-10.0, 10.0)))

func _on_CatchArea_body_entered(body):
    var animation_player = get_node("AnimationPlayer")
    get_node("AnimationPlayer").get_animation("Run").set_loop(true)
    animation_player.play("Idle")

func _on_CatchArea_body_exited(body):
    var animation_player = get_node("AnimationPlayer")
    get_node("AnimationPlayer").get_animation("Run").set_loop(true)
    animation_player.play("Run")
