extends KinematicBody

export var speed = 500
var direction
var position
var random

func _ready():
    random = RandomNumberGenerator.new()
    reset_position()
    scale = Vector3(2,2,2)
    var animation_player = get_node("AnimationPlayer")
    get_node("AnimationPlayer").get_animation("Run").set_loop(true)
    animation_player.play("Run")

func _input(event):
    if event.is_action_pressed("ui_right"):
        reset_position()
    if event.is_action_pressed("ui_up"):
        randomize_direction()

func _physics_process(delta):
    var velocity = speed * delta * direction
    move_and_slide(velocity, Vector3(0, -1, 0))

func reset_position():
    randomize_direction()
    randomize_position()
    translation = position

func _on_Button_button_up():
    reset_position()

func set_direction(dir):
    direction = dir.normalized()
    rotation.y = atan2(direction.x, direction.z)

func set_position(pos):
    position = pos

func randomize_direction():
    set_direction(Vector3(random.randf_range(-1.0, 1.0), 0.0, random.randf_range(-1.0, 1.0)))

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