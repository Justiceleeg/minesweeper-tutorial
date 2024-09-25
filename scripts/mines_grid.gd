class_name MinesGrid
extends TileMapLayer

signal flag_changed(number_of_flags)
signal game_lost
signal game_won

const CELLS = {
	"1": Vector2i(0,0),
	"2": Vector2i(1,0),
	"3": Vector2i(2,0),
	"4": Vector2i(3,0),
	"5": Vector2i(4,0),
	"6": Vector2i(0,1),
	"7": Vector2i(1,1),
	"8": Vector2i(2,1),
	"CLEAR": Vector2i(3,1),
	"MINE_RED": Vector2i(4,1),
	"FLAG": Vector2i(0,2),
	"MINE": Vector2i(1,2),
	"DEFAULT": Vector2i(2,2),
}

@export var columns := 8
@export var rows := 8

@export var number_of_mines := 20

const TILE_SET_ID = 0

var cells_with_mines: Dictionary = {}
var cells_with_flags: Dictionary = {}
var cleared_cells = 0
var is_game_finished = false

func _ready() -> void:
	clear()
	
	for r in rows:
		for c in columns:
			var cell_coord = Vector2i(r - rows / 2, c - columns / 2)
			set_tile_cell(cell_coord, "DEFAULT")
	
	place_mines()

func _input(event: InputEvent) -> void:
	if event is not InputEventMouseButton || !event.pressed:
		return
	
	var clicked_cell_coord = local_to_map(get_local_mouse_position())
	
	if event.button_index == 1:
		on_cell_clicked(clicked_cell_coord)
	elif event.button_index == 2:
		place_flag(clicked_cell_coord)

func place_mines():
	
	for mine in number_of_mines:
		place_unique_mine()
	
	#necessary?
	for cell in cells_with_mines:
		erase_cell(_str_to_vector2i(cell))
		set_cell(_str_to_vector2i(cell), TILE_SET_ID, CELLS.DEFAULT, 1)

func place_unique_mine() -> void:
	var cell_coord = Vector2i(randi_range(-rows / 2, rows / 2 - 1),randi_range(-columns / 2, columns / 2 - 1))
		
	while cells_with_mines.has(str(cell_coord)):
		cell_coord = Vector2i(randi_range(-rows / 2, rows / 2 - 1),randi_range(-columns / 2, columns / 2 - 1))
	
	cells_with_mines[str(cell_coord)] = true

func set_tile_cell(cell_coord: Vector2i, cell_type: String) -> void:
	
	set_cell(cell_coord, TILE_SET_ID, CELLS[cell_type])

func on_cell_clicked(cell_coord: Vector2i) -> void:
	if cells_with_mines.has(str(cell_coord)):
		# make the first click safe
		if cleared_cells == 0:
			cells_with_mines.erase(str(cell_coord))
			place_unique_mine()
			handle_cells(cell_coord)
			return
		lose(cell_coord)
		return
	
	handle_cells(cell_coord)


func handle_cells(cell_coord: Vector2i, cells_checked_recursively: Array[Vector2i] = []) -> void:
	var tile_data = get_cell_tile_data(cell_coord)
	var atlas_coord = get_cell_atlas_coords(cell_coord)
	
	if tile_data == null:
		return
	
	# don't handle cells that have been handled
	if !(atlas_coord == CELLS.DEFAULT or atlas_coord == CELLS.FLAG):
		return
	
	# don't handle cells that are mines
	var cell_has_mine = cells_with_mines.has(str(cell_coord));
	if cell_has_mine:
		return
	
	var mine_count = get_surrounding_cells_mine_count(cell_coord)
	
	if mine_count == 0:
		set_tile_cell(cell_coord, "CLEAR")
		var surrounding_cells = _get_all_surrounding_cells(cell_coord)
		for cell in surrounding_cells:
			handle_surrounding_cell(cell, cells_checked_recursively)
	else:
		set_tile_cell(cell_coord, str(mine_count))
	
	recover_flag(cell_coord)
	
	cleared_cells += 1
	if cleared_cells + number_of_mines == rows * columns:
			win()

func handle_surrounding_cell(cell_coord: Vector2i, cells_checked_recursively: Array[Vector2i]):
	if cells_checked_recursively.has(cell_coord):
		return
	
	cells_checked_recursively.append(cell_coord)
	handle_cells(cell_coord, cells_checked_recursively)

func get_surrounding_cells_mine_count(cell_coord: Vector2i) -> int:
	var mine_count := 0
	var surrounding_cells = _get_all_surrounding_cells(cell_coord)
	for cell in surrounding_cells:
		var tile_data = get_cell_tile_data(cell)
		if tile_data and cells_with_mines.has(str(cell)):
			mine_count += 1
	
	return mine_count

func lose(cell_coord: Vector2i) -> void:
	game_lost.emit()
	is_game_finished = true
	
	for cell in cells_with_mines:
		if !cells_with_flags.has(str(cell)):
			set_tile_cell(_str_to_vector2i(cell), "MINE")

	set_tile_cell(cell_coord, "MINE_RED")

func place_flag(cell_coord: Vector2i) -> void:
	var tile_data = get_cell_tile_data(cell_coord)
	var atlas_coord = get_cell_atlas_coords(cell_coord)
	var is_empty_cell = atlas_coord == CELLS["DEFAULT"]
	var is_flag_cell = atlas_coord == CELLS["FLAG"]
	
	if is_empty_cell and not is_flag_cell and cells_with_flags.keys().size() < number_of_mines:
		set_tile_cell(cell_coord, "FLAG")
		cells_with_flags[str(cell_coord)] = true
		flag_changed.emit(cells_with_flags.keys().size())
	
	if is_flag_cell:
		set_tile_cell(cell_coord, "DEFAULT")
		cells_with_flags.erase(str(cell_coord))
		flag_changed.emit(cells_with_flags.keys().size())

func recover_flag(cell_coord:Vector2i) -> void:
	if cells_with_flags.has(str(cell_coord)):
		cells_with_flags.erase(str(cell_coord))
		flag_changed.emit(cells_with_flags.keys().size())
		
func win():
	is_game_finished = true
	game_won.emit()

#func vector2i_to_str(vec: Vector2i) -> String:
	#return str(vec).replace(" ", "")
#
func _str_to_vector2i(str: String) -> Vector2i:
	var split_str = str.split(", ")
	return Vector2i(int(split_str[0]), int(split_str[1]))

func _get_all_surrounding_cells(cell_coord: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i]
	for x in range(cell_coord.x - 1, cell_coord.x + 2):
		for y in range(cell_coord.y - 1, cell_coord.y + 2):
			if x == cell_coord.x and y == cell_coord.y:
				continue
			if x not in range(-rows/2, rows/2) or y not in range(-columns/2, columns/2):
				continue
			result.append(Vector2i(x,y))
	return result
