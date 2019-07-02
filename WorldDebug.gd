extends Spatial

var TRACE_PATH = false
var DISC_PATH_CONTROL_POINTS = false
var ATTACK_POINT = true

var path_tracers
var marker

func _ready():
    self.path_tracers = self.get_node('PathTracers')
    self.marker = preload("res://TrailMarker.tscn")

func throw_calculated(curve, throw_details):
    self.trace_path(curve)

func clear_path_tracers():
    for child in self.path_tracers.get_children():
        self.path_tracers.remove_child(child)

func trace_path(curve):
    var tm = preload("res://TrailMarker.tscn")
    self.clear_path_tracers()
    var steps = 60
    if self.TRACE_PATH:
        # FIXME (28 May 2019 sam): Path tracing is not working. Figure it out.
        for i in range(curve.get_point_count()-1):
            var t = tm.instance()
            t.translation = curve.get_point_position(i)
            self.path_tracers.add_child(t)
            for j in range(1, steps+1):
                t = tm.instance()
                t.translation = curve.interpolate(i, float(j)/steps)
                self.path_tracers.add_child(t)
    if self.DISC_PATH_CONTROL_POINTS:
        var cip = tm.instance()
        cip.translation = curve.get_point_in(1) + curve.get_point_position(1)
        cip.scale = Vector3(.5, .5, .5)
        self.path_tracers.add_child(cip)
        var cop = tm.instance()
        cop.translation = curve.get_point_out(1) + curve.get_point_position(1)
        cop.scale = Vector3(.5, .5, .5)
        self.path_tracers.add_child(cop)

func attack_point_calculated(point):
    if self.ATTACK_POINT:
        var tm = preload('res://TrailMarker.tscn')
        var t = tm.instance()
        t.translation = point
        t.scale = Vector3(1, 1, 1)
        self.path_tracers.add_child(t)

func debug_point(point, string):
    var m = self.marker.instance()
    m.translation = point
    self.path_tracers.add_child(m)

func clear_debug_points():
    self.clear_path_tracers()
