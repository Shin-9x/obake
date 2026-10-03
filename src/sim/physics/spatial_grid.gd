class_name SpatialGrid
## Uniform-grid broad phase: finds the pegs whose bounds overlap a query box.
##
## Queries write into [member results] without allocating. Candidates come out in a stable
## order: cells row by row, pegs in insertion order within a cell, each peg at most once.

const CELL_SIZE: int = 20 * FixedMath.PX

## Peg indices found by the last query; only the first [member result_count] are valid.
var results: PackedInt32Array = PackedInt32Array()
var result_count: int = 0

var _columns: int = 1
var _rows: int = 1
var _cells: Array[PackedInt32Array] = []
var _enabled: PackedByteArray = PackedByteArray()
var _stamps: PackedInt64Array = PackedInt64Array()
var _query_id: int = 0


func _init(width: int, height: int) -> void:
	_columns = maxi(1, (width + CELL_SIZE - 1) / CELL_SIZE)
	_rows = maxi(1, (height + CELL_SIZE - 1) / CELL_SIZE)
	_cells.resize(_columns * _rows)
	for cell: int in _cells.size():
		_cells[cell] = PackedInt32Array()


## Adds a peg by its bounds. Indices must be inserted in increasing order, starting at 0.
func insert(index: int, min_x: int, min_y: int, max_x: int, max_y: int) -> void:
	_enabled.resize(index + 1)
	_stamps.resize(index + 1)
	results.resize(index + 1)
	_enabled[index] = 1
	for row: int in range(_row_of(min_y), _row_of(max_y) + 1):
		for column: int in range(_column_of(min_x), _column_of(max_x) + 1):
			_cells[row * _columns + column].append(index)


func remove(index: int) -> void:
	_enabled[index] = 0


func query(min_x: int, min_y: int, max_x: int, max_y: int) -> void:
	_query_id += 1
	result_count = 0
	var first_column: int = _column_of(min_x)
	var last_column: int = _column_of(max_x)
	for row: int in range(_row_of(min_y), _row_of(max_y) + 1):
		for column: int in range(first_column, last_column + 1):
			for index: int in _cells[row * _columns + column]:
				if _enabled[index] == 1 and _stamps[index] != _query_id:
					_stamps[index] = _query_id
					results[result_count] = index
					result_count += 1


func _column_of(x: int) -> int:
	return clampi(x / CELL_SIZE, 0, _columns - 1)


func _row_of(y: int) -> int:
	return clampi(y / CELL_SIZE, 0, _rows - 1)
