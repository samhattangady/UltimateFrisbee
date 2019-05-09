extends Node

func quadratic_regression(points):
	# Since we're mostly going to be throwing from bottom to top
	# it makes more sense to keep y as independent variable. This
	# function gets a little confusing because of that, since x and
	# y of the quadratic formulae is getting mixed with the x and y
	# of the input points. Just note that.
	print('calculating quadratic regression for points', points)
	var sumxi = 0
	var sumxi2 = 0
	var sumxi3 = 0
	var sumxi4 = 0
	var sumxi2yi = 0
	var sumxiyi = 0
	var sumyi = 0
	var n = len(points)
	for raw_pos in points:
		var pos = Vector2(raw_pos.y, raw_pos.x)
		sumxi += pos.x
		sumxi2 += pos.x*pos.x 
		sumxi3 += pos.x*pos.x*pos.x
		sumxi4 += pos.x*pos.x*pos.x*pos.x
		sumxi2yi += (pos.x*pos.x) * pos.y
		sumxiyi += pos.x * pos.y
		sumyi += pos.y
	# Quadratic solution taken from https://www.easycalculation.com/statistics/learn-quadratic-regression.php
	var xx = sumxi2 - (sumxi * sumxi)/n
	var xy = sumxiyi - (sumxi * sumyi)/n
	var xx2 = sumxi3 - (sumxi * sumxi2)/n
	var x2y = sumxi2yi - (sumxi2 * sumyi)/n
	var x2x2 = sumxi4 - (sumxi2 * sumxi2)/n
	var a = (x2y*xx - xy*xx2) / (xx*x2x2 - xx2*xx2)
	var b = (xy*x2x2 - x2y*xx2) / (xx*x2x2 - xx2*xx2)
	var c = sumyi/n - (b*(sumxi/n)) - (a*(sumxi2/n))
	var new_points = []
	var x1 = points[0].y
	var x2 = points.back().y
	var step = (x2-x1)/n
	for x in range(x1, x2, step):
		var y = a*x*x + b*x + c
		new_points.append(Vector2(y, x))
		x += step
	return new_points

func cubic_regression(points):
	# TODO (07 May 2019 sam): Cubic regression formulae.
	# Since we're mostly going to be throwing from bottom to top
	# it makes more sense to keep y as independent variable. This
	# function gets a little confusing because of that, since x and
	# y of the quadratic formulae is getting mixed with the x and y
	# of the input points. Just note that.
	# Solved using https://en.wikipedia.org/wiki/Polynomial_regression
	print(points)
	var xs = []
	var ys = []
	for point in points:
		xs.append(point.y)
		ys.append([point.x])
	var xmatrix = []
	for x in xs:
		xmatrix.append([1, x, pow(x,2), pow(x,3)])
	var solution = multiply_matrices(xmatrix, matrix_transpose(xmatrix))
	print('multiplied x and xt')
	solution = inverse_of_matrix(solution)
	print('found inverse')
	solution = multiply_matrices(solution, matrix_transpose(xmatrix))
	print('multiplied with transpose')
	solution = multiply_matrices(solution, ys)
	print('multiplied with y')
	print(solution)
	var new_points = []
	var x1 = points[0].y
	var x2 = points.back().y
	var step = (x2-x1)/len(points)
	for x in range(x1, x2, step):
		var y = 0
		for i in range(len(solution)):
			y += solution[i] * pow(x, i)
		new_points.append(Vector2(y, x))
		x += step
	return new_points

func inverse_of_matrix(X):
	var inv = []
	var det = determinant(X)
	var cofinv = cofactor_matrix(X)
	cofinv = matrix_transpose(cofinv)
#	return cofinv
	for i in range(len(X)):
		for j in range(len(X[0])):
			cofinv[i][j] /= det
	return cofinv

func cofactor_matrix(X):
	var C = []
	for i in range(len(X)):
		var new_row = []
		for j in range(len(X)):
			new_row.append(determinant(del_row_and_col(X, i, j)))
		C.append(new_row)
	return C

func multiply_matrices(a, b):
	# TODO (07 May 2019 sam): Might need to be optimized or replaced
	# We expect arrays as [[1, 2, 3]] or [[1], [2], [3]] and so on
	assert(len(a[0]) == len(b))
	var result = zero_matrix(len(a), len(b[0]))
	var bt = matrix_transpose(b)
	for i in range(len(a)):
		for j in range(len(bt)):
			result[i][j] = multiply_row(a[i], bt[j])
	return result

func multiply_row(a, b):
	# Helper function for matrix operations
	assert(len(a) == len(b))
	var result = 0
	for i in range(len(a)):
		result += a[i]*b[i]
	return result

func matrix_transpose(a):
	# Helper function for matrix operations
	assert(a[0] is Array)
	var at = zero_matrix(len(a[0]), len(a))
	for i in range(len(a[0])):
		for j in range(len(a)):
			at[i][j] = a[j][i]
	return at

func zero_matrix(rows, cols):
	var matrix = []
	for i in range(rows):
		matrix.append([])
		for j in range(cols):
			matrix[i].append(0)
	return matrix

func determinant(X):
	assert(len(X) > 1)
	assert(len(X) == len(X[0]))
	var term_list = []
	#If more than 2 rows, reduce and solve in a piecewise fashion
	if len(X) == 2:
		return X[0][0]*X[1][1] - X[0][1]*X[1][0]
	for j in range(0, len(X)):
		#Remove i and j columns
		var new_x = del_row_and_col(X, 0, j)
		var multiplier = X[0][j] * pow(-1,(2+j))
		var det = determinant(new_x)
		term_list.append(multiplier*det)
	return sum(term_list)   

func sum(list):
	var result = 0
	for i in list:
		result += i
	return result

func del_row_and_col(array, row_index, col_index):
	var result = []  # zero_matrix(len(array)-1, len(array)-1)
	for i in range(len(array)):
		if i==row_index: continue
		var new_row = []
		for j in range(len(array)):
			if j== col_index: continue
			new_row.append(array[i][j])
		result.append(new_row)
	return result