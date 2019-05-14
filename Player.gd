extends KinematicBody

export var speed = 5
var direction = Vector3()
var position = Vector3()

func _ready():
    var animation_player = get_node("AnimationPlayer")
    get_node("AnimationPlayer").get_animation("Run").set_loop(true)
    animation_player.play("Run")
    direction = Vector3(1, 0, -1)
    position = Vector3(-10, 0, 0)

func _input(event):
    if event.is_action_pressed("ui_right"):
        reset_position()

func _physics_process(delta):
    rotation.y = atan2(1, -1)
    var velocity = speed * direction.normalized()
    move_and_slide(velocity, Vector3(0, -1, 0))
#   move_and_slide(Vector3(0,0,0), Vector3(0, -1, 0))

func reset_position():
    translation = position
    
func _on_Button_button_up():
    reset_position()

func set_direction(dir):
    direction = direction

func set_position(pos):
    position = pos

