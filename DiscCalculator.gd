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
    # return progress
    return (lin_ratio * progress) + (exp_ratio * pow((1-2*progress), 2))

func get_next_disc_offset(offset, delta, total_throw_time, max_speed, min_speed):
    var time = get_disc_time(offset, total_throw_time, max_speed, min_speed)
    var new_offset = get_disc_offset(time+delta, total_throw_time, max_speed, min_speed)
    return new_offset

func get_disc_time(offset, total_throw_time, max_speed, min_speed):
    # print(offset, total_throw_time, max_speed, min_speed)
    # TODO Print all these for debugging in test.
    # We need to return the inverse of `get_disc_offset`
    print('offset ', offset)
    print('total_throw_time ', total_throw_time)
    print('max_speed ', max_speed)
    print('min_speed ', min_speed)
    var lin_ratio = (min_speed / max_speed)
    var exp_ratio = 1.0 - lin_ratio
    print('lin_ratio ', lin_ratio)
    print('exp_ratio ', exp_ratio)
    # Using the quadratic equation to solve the whole mess
    var a = 4.0 * exp_ratio
    var b = lin_ratio - 4.0*exp_ratio
    var c = exp_ratio - offset
    print('a ', a)
    print('b ', b)
    print('c ',c)
    var b2_4ac = pow(b,2) - 4.0*a*c
    print('b2_4ac ', b2_4ac)
    var sol1 = (-b + sqrt(b2_4ac)) / (2.0*a)
    var sol2 = (-b - sqrt(b2_4ac)) / (2.0*a)
    print('sol1 ', sol1)
    print('sol2 ', sol2)
    # return offset*total_throw_time
    return sol1
    if offset <= 0.5:
        if sol1 <= 0.5: return sol1
        else: return sol2
    else:
        if sol1 > 0.5: return sol1
        else: return sol2
    # We return whichever is in 0-1.
    # TODO (23 May 2019 sam): Check if this assumption is correct
    if 0.0 <= sol1 and sol1 <= 1.0:
        return sol1
    else:
        return sol2
