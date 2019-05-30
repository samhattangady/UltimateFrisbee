extends Node

func get_disc_offset(time, total_throw_time, max_speed, min_speed):
    # We want to know the disc offset at a particular time. We can't use EASE_IN
    # etc, because they cause the disc to come to a complete halt at its apex,
    # which we don't like. The graph for time vs offset consists of the sum of
    # a linearly growing line and a quadratic decline to 0.5, and quadratic growth
    # from there. The quadratic component, < 0.5, is (1-2x)**2, and >0.5 is (2x-1)**2
    # Both of those give us the same value.
    var lin_ratio = (min_speed / max_speed)
    var exp_ratio = 1 - lin_ratio
    var progress = (time/total_throw_time)
    var exp_component = 0
    if progress < 0.5:
        var angle = lerp(0, PI/2, progress*2)
        # exp_component = 0.5 - 0.5*pow((1-2*progress), 2)
        exp_component = 0.5*sin(angle)
    else:
        var angle = lerp(-PI/2, 0, (progress-0.5)*2)
        # exp_component = 0.5 + 0.5*pow((1-2*progress), 2)
        exp_component = 0.5 + 0.5*(sin(angle)+1)
    return (lin_ratio * progress) + (exp_ratio * exp_component)

func get_next_disc_offset(offset, delta, total_throw_time, max_speed, min_speed):
    var time = get_disc_time(offset, total_throw_time, max_speed, min_speed)
    var new_offset = get_disc_offset(time+delta, total_throw_time, max_speed, min_speed)
    return new_offset

func get_disc_time(offset, total_throw_time, max_speed, min_speed):
    # This function returns the inverse of `get_disc_offset`
    # TODO (24 May 2019 sam): Implement inverse of get_disc_offset
    pass
