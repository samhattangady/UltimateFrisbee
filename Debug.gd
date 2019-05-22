extends Node

onready var disc = get_parent().get_node('FrisbeeThings').get_node('Disc')

func _input(event):
    if event.is_action_pressed('ui_accept'):
        print(disc.get_node('Path').translation)

