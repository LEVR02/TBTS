extends "res://TileContents.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var cover_lvl
var destructible
var hp

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_destructible():
	return destructible
func get_cover_lvl():
	return cover_lvl

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
