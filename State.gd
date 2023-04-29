extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Number of tiles that have been (left) clicked, valid or invalid, duplicates counted
# if selection = 1 then just op selected
# selection = -1 means cancelled
var selection = 0
var selected_op = null
var selected_tile = null
var end_tile = null
var remain_selection_depth = 0
var path = []
var full_path = []
var allow_inputs = true
var fire_target = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func end_path():
	selection = 0
	selected_op = null
	selected_tile = null
	end_tile = null
	path = []
	remain_selection_depth = 0
	full_path = []
	fire_target = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
