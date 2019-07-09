extends Spatial

var shirt_material

func _ready():
    self.shirt_material = self.get_node('Armature2/Shirt').mesh.surface_get_material(0)

func set_yellow():
    self.shirt_material.albedo_color = Color(1, 1, 0, 1)
