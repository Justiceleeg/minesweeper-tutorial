class_name UI
extends CanvasLayer

var game_lost_button_texture = preload("res://assets/button_dead.png")
var game_won_button_texture = preload("res://assets/button_cleared.png")

@onready var mines_count_label: Label = %MinesCountLabel
@onready var game_status_button: TextureButton = %GameStatusButton
@onready var timer_count_label: Label = %TimerCountLabel

func _ready() -> void:
	game_status_button.pressed.connect(_on_game_status_button_pressed)

func set_mine_count(mines_count: int) -> void:
	var mines_count_string = str(mines_count)
	if mines_count_string.length() < 3:
		mines_count_string = mines_count_string.lpad(3,"0")
	
	mines_count_label.text = mines_count_string

func set_timer_count(timer_count:int) -> void:
	var timer_string = str(timer_count)
	if timer_string.length() < 3:
		timer_string = timer_string.lpad(3,"0")
	
	timer_count_label.text = timer_string

func _on_game_status_button_pressed() -> void:
	get_tree().reload_current_scene()

func game_lost() -> void:
	game_status_button.texture_normal = game_lost_button_texture

func game_won() -> void:
	game_status_button.texture_normal = game_won_button_texture
