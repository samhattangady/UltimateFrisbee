extends Node

static func get_disc_offset(time, total_throw_time, max_speed, min_speed):
    return time/total_throw_time

static func get_next_disc_offset(offset, delta, total_throw_time, max_speed, min_speed):
    var time = get_disc_time(offset, total_throw_time, max_speed, min_speed)
    return get_disc_offset(time+delta, total_throw_time, max_speed, min_speed)

static func get_disc_time(offset, total_throw_time, max_speed, min_speed):
    return offset*total_throw_time
