extends Node

@export var mines_grid: MinesGrid
@export var ui: UI

@onready var timer: Timer = $Timer

var time_elapsed = 0

func _ready() -> void:
	mines_grid.game_lost.connect(_on_game_lost)
	mines_grid.game_won.connect(_on_game_won)
	mines_grid.flag_changed.connect(_on_flags_changed)
	timer.timeout.connect(_on_timer_timeout)
	ui.set_mine_count(mines_grid.number_of_mines)
	
func _on_game_lost()-> void:
	timer.stop()
	ui.game_lost()

func _on_game_won()-> void:
	timer.stop()
	ui.game_won()

func _on_flags_changed(flags_count: int)-> void:
	ui.set_mine_count(mines_grid.number_of_mines - flags_count)
	pass

func _on_timer_timeout() -> void:
	time_elapsed += 1
	ui.set_timer_count(time_elapsed)
