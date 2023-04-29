extends Area2D

signal selected
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var x 
var y
var traversable
var transparent
var valid_target

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func start(x,y):
	self.x = x
	self.y = y
	pass
func start_extra(x,y,extra):
	start(x, y)
	pass
func update_pos(x,y):
	self.x = x
	self.y = y
func clicked():
	pass
func mouse_enter():
	pass
func mouse_leave():
	pass
func end_turn():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
