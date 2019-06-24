extends Spatial

var grass
export var rows = 20
export var spacing = 3.0

# TODO (24 Jun 2019 sam): Look into updating AABB

func _ready():
    self.grass = self.get_node('Grass')
    self.grass.amount = self.rows * self.rows
    if self.grass.process_material:
        self.grass.process_material.set_shader_param('rows', self.rows)
        self.grass.process_material.set_shader_param('spacing', self.spacing)

func set_grass_position(pos):
    pos.y = 0
    self.grass.translation = pos
