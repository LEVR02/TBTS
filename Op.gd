extends "res://TileContents.gd"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var mouse_over = false
var team = -1
var move_range = 3
# NOTE: DO NOT SET MIN AND MAX RANGES TO THE SAME (will cause some extra tiles to be 
# highlighted because of min range explore using outer border explore)
var f_range = 5
var f_min_range = 0
var hp
var atk = 10
var equip = null

var can_fire = false
var can_use_equip = false
var can_move = false

var has_action = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func start(x,y):
	show()
	self.hp = 100
	self.traversable = false
	self.transparent = false
	self.valid_target = true
	change_hp(hp)
	can_fire = true
	can_move = true
	if equip != null:
		can_use_equip = true
	update_action()
	
func update_action():
	has_action = can_fire or can_move or can_use_equip
	if has_action == false:
		end_and_reset_act()
# Extra args: team number, move range, firing min range, firing (max) range, hp, atk
func start_extra(x,y,extra):
	show()
	self.traversable = false
	self.transparent = false
	self.valid_target = true
	team = extra[0]
	move_range = extra[1]
	f_min_range = extra[2]
	f_range = extra[3]
	hp = extra[4]
	atk = extra[5]
	change_hp(hp)
	can_fire = true
	can_move = true
	if equip != null:
		can_use_equip = true
	update_action()

func moved(start_x,start_y,end_x,end_y):
	can_move = false
	update_action()
	pass
func fired(target_x,target_y):
	can_fire = false
	update_action()
	pass
func equip_used():
	pass
	
func end_and_reset_act():
	can_fire = true
	can_move = true
	if equip!= null:
		can_use_equip = true
	has_action = false

func set_team(t):
	self.team = t
	
func clicked():
	var state = get_node("/root/State")
	if state.selection == 0:
		state.selection = 1
		state.selected_op = self
		state.remain_selection_depth = move_range
		emit_signal("selected")
	
func mouse_enter():
	mouse_over = true
	var state = get_node("/root/State")
	if state.selection == 0:
		$AS.play()
func mouse_leave():
	mouse_over = false
	var state = get_node("/root/State")
	if state.selection == 0:
		$AS.stop()
func change_hp(new_hp):
	self.hp = new_hp
	$rect/hp_rect.set_size(Vector2(max(0,self.hp)*10,50))
	if self.hp <= 0:
		queue_free()
func damage(dmg):
	change_hp(self.hp - dmg)

func end_turn():
	$AS.stop()
	has_action = false
	can_fire = false
	can_move = false
	can_use_equip = false
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

