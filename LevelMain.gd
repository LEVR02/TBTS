extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export(PackedScene) var op_scene
export(PackedScene) var wall_scene

var map_height = 10
var map_width = 19
var team = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize() #Replace with function body.
	new_game() 
	
# Op: Extra args: team number, move range, firing min range, firing (max) range, hp, atk
func new_game():
	var contents = []
	contents.append(start_extra(op_scene,5,4,[1,5,0,7,100,10]))
	contents.append(start_extra(op_scene,10,5,[2,3,5,7,100,10]))
	contents.append(start_extra(op_scene,3,2,[1,5,3,7,100,10]))
	contents.append(start(wall_scene,3,3))
	contents.append(start(wall_scene,3,4))
	contents.append(start(wall_scene,3,5))
	contents.append(start(wall_scene,3,6))
	$Map.start_map(map_height,map_width,contents,1)
	
# instantiates a tile contents (of scene) and adds it to the map
func start(scene,x,y):
	var c = scene.instance()
	c.x = x
	c.y = y
	c.start(x,y)
	return c
	
func start_extra(scene,x,y,extra):
	var c = scene.instance()
	c.x = x
	c.y = y
	c.start_extra(x,y,extra)
	return c
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Map_selected():
	var state = get_node("/root/State")
	if state.selected_op != null:
		var op = state.selected_op
		#print(op.x, ", ", op.y)
		op.get_node("AS").play()
		
# Finish path: clear op from start tile, settle op into end tile, clear state variables
func _on_Map_end_path():
	var state = get_node("/root/State")
	var op = state.selected_op
	var tile = state.selected_tile
	tile.reset_selection()
	if state.selection > 1:
		tile.clear_contents(op)
		state.allow_inputs = false
		# for t in state.path:
			# var x = t.get_x_pos()
			# var y = t.get_y_pos()
		$Map.play_path(op)
	else:
		state.end_path()
	#op.position = state.end_tile.get_center_pos()
func _on_Map_path_tween_completed():
	var state = get_node("/root/State")
	if state.selected_op != null:
		var op = state.selected_op
		if state.end_tile != null:
			op.position = state.end_tile.get_center_pos()
			op.update_pos(state.end_tile.x,state.end_tile.y)
			state.end_tile.set_contents(op)
		op.moved(state.selected_tile.x,state.selected_tile.y,state.end_tile.x,state.end_tile.y)
		state.end_path()
		
		state.allow_inputs = true

