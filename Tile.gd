extends Node

signal selected
signal aim(target)
signal add_path(to_add)
signal finish_path(to_finish)


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var contents = null
var mouse_over = false
var pressed = false
var height
var width
# grid coords
var x
var y
# actual coords
var x_pos
var y_pos
var current_anim 

export(bool) var covered = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func traversable():
	return contents==null or contents.traversable
func transparent():
	return contents==null or contents.transparent
func valid_firing_target():
	return contents!=null and contents.valid_target
func get_target():
	if valid_firing_target():
		return contents
	else:
		return null
func check_contents(what):
	return contents != null and contents == what
	
func init_tile(x_arg, y_arg, x_pos, y_pos,w,h):
	self.x = x_arg
	self.y = y_arg
	self.x_pos = x_pos
	self.y_pos = y_pos
	width = w
	height = h
	play_normal_sprite()
	
	# if contents != null:
		# $Tile.get_node("Tile_Sprite").hide()

func clear_contents(to_remove):
	to_remove.disconnect("selected",self,"_on_TileContents_selected")
	remove_child(to_remove)
	contents = null
	
func set_contents(to_set):#,pos_x,pos_y,scale):
	add_child(to_set)
	#var ts = to_set.instance()
	#ts.position = Vector2(pos_x, pos_y)
	#ts.scale = Vector2(scale, scale)
	#ts.start()
	#add_child(ts)
	contents = to_set
	to_set.connect("selected", self, "_on_TileContents_selected")
	
func set_tile_texture(to_set):
	$TileArea.get_node("Tile_Sprite").set_sprite_frames(to_set)
func get_tile_texture():
	return $TileArea.get_node("Tile_Sprite").get_sprite_frames()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func get_x_pos():
	return x_pos
func get_y_pos():
	return y_pos
func get_grid_pos():
	return Vector2(x,y)
	
#func get_center_x():
#	return x_pos + width/2
#func get_center_y():
#	return y_pos + height/2	
	
func get_center_pos():
	return Vector2(get_x_pos(),get_y_pos())
func reset_selection():
	play_normal_sprite()

func _on_Tile_mouse_entered():
	mouse_over = true
	if contents != null:
		contents.mouse_enter()
		
func _on_Tile_mouse_exited():
	mouse_over = false
	if contents != null:
		contents.mouse_leave()
		

func _on_Tile_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		var state = get_node("/root/State")
		if event.pressed and state.allow_inputs: 
			if event.button_index == BUTTON_LEFT:
				pressed = true
				if contents != null and !event.doubleclick:
					if state.selection == 0:
						contents.clicked()
						# state.path.append(self)
				else:
					if state.selection > 0:
						if !event.doubleclick:
							#var last_node = state.path[state.path.size]
							state.selection += 1
							emit_signal("add_path", self)
							#state.path.append(self)
						else:
							state.end_tile = self
							emit_signal("finish_path",self)
			elif event.button_index == BUTTON_RIGHT:
				emit_signal("aim",self)
		else:
			if event.button_index == BUTTON_LEFT:
				pressed = false
func play_select_sprite():
	$TileArea.get_node("Tile_Sprite").play("select")
	current_anim = "select"
func play_normal_sprite():
	$TileArea.get_node("Tile_Sprite").play("default")
	current_anim = "default"
func play_avail_sprite():
	if current_anim != "range":
		$TileArea.get_node("Tile_Sprite").play("avail")
		current_anim = "avail"
	else:
		play_avail_range_sprite()
func play_range_sprite():
	if current_anim != "avail":
		$TileArea.get_node("Tile_Sprite").play("range")
		current_anim = "range"
	else:
		play_avail_range_sprite()
func play_blocked_sprite():
	$TileArea.get_node("Tile_Sprite").play("blocked")
	current_anim = "blocked"
func play_avail_range_sprite():
	$TileArea.get_node("Tile_Sprite").play("avail_range")
	current_anim = "avail_range"
	
func get_anim():
	return current_anim
# pass signal from op selected
func _on_TileContents_selected():
	var state = get_node("/root/State")
	state.selected_tile = self
	state.path.append(self)
	state.full_path.append(get_grid_pos())
	play_select_sprite()
	emit_signal("selected")
