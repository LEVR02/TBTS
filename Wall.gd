extends "Cover.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func start(x,y):
	show()
	self.cover_lvl = 3
	self.hp = -1
	self.destructible = false
	self.traversable = false
	self.transparent = false
	self.valid_target = false

func clicked():
	pass
func mouse_enter():
	pass
func mouse_leave():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
