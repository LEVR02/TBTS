extends Node2D

signal selected
signal end_turn
signal path_tween_completed
signal collisions_ready
signal end_path 

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

@export var tile_scene: PackedScene
@export var debug: bool
var t_scale = 0.05
var op_scale = 0.75
var c_scale = 0.05
var map_array = []
var base_array_anims = []
#var visited = []
var costs = []
var width
var height
var path
var tween_op
var collisions = []
var fire_target
var firing = false
var fire_start_center_pos
var fire_start_grid_pos
var waiting_collisions = false
var play_collided_tiles = []
var curr_team
#var cycles_waited = 0
var can_fire = false
@onready var state = get_node("/root/State")
# func find_tile(x,y):
func tile_valid(x,y):
	if x >=0 and x < width and y >= 0 and y < height and x < map_array.size() \
	and y < map_array[x].size() and map_array[x][y] != null:
		return true
	else:
		return false
func tile_traversable(x,y):
	return tile_valid(x,y) and map_array[x][y].traversable()
	
func set_tile_anim(x,y,anim):
	if tile_valid(x,y):
		var t = map_array[x][y]
		if anim == "default":
			t.play_normal_sprite()
		elif anim == "avail":
			t.play_avail_sprite()
		elif anim == "range": #and t.get_anim() != "avail":
			t.play_range_sprite()
#		elif anim == "range" and t.get_anim() == "avail":
#			t.play_avail_range_sprite()
		elif anim == "avail_range":
			t.play_avail_range_sprite()
		elif anim == "blocked":
			t.play_blocked_sprite()
		elif anim == "select":
			t.play_select_sprite()

func set_base_anim(x,y,anim):
	if tile_valid(x,y):
		if anim == "default":
			base_array_anims[x][y] = "default"
		elif anim == "avail" and base_array_anims[x][y] != "range":
			base_array_anims[x][y] = "avail"
		elif anim == "avail" and base_array_anims[x][y] == "range":
			base_array_anims[x][y] = "avail_range"
		elif anim == "range" and base_array_anims[x][y] != "avail":
			base_array_anims[x][y] = "range"
		elif anim == "range" and base_array_anims[x][y] == "avail":
			base_array_anims[x][y] = "avail_range"
		elif anim == "blocked":
			base_array_anims[x][y] = "blocked"
		elif anim == "select":
			base_array_anims[x][y] = "select"
			
func reset_collision_markers():
	for collide in play_collided_tiles:
		if !state.full_path.has(collide):
			var t = map_array[collide.x][collide.y]
			set_tile_anim(collide.x,collide.y,base_array_anims[collide.x][collide.y])
	play_collided_tiles = []
func reset_except_path():
	for row in map_array:
		for t in row:
			if !state.full_path.has(t):
				set_tile_anim(t.x,t.y,"default")
				set_base_anim(t.x,t.y,"default")
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func draw_debug(x,y):
	if debug:
		$DebugLine.clear_points()
		$DebugLine.add_point(Vector2(x,y))
		$DebugLine.add_point(Vector2(x-50,y-50))

func start_map(s_height, s_width, contents, s_curr_team):
	self.height = s_height
	self.width = s_width
	self.curr_team = s_curr_team
	path = $Path2D.get_curve()
	
	#var texture = ImageTexture.new()
	#var image = Image.new()
	#var frames = SpriteFrames.new()
	#frames.add_animation("select")
	#image.load("res://art/tile.png")
	#texture.create_from_image(image)
	var temp_tile = tile_scene.instantiate()
	var texture = temp_tile.get_tile_texture()
	var t_width = texture.get_frame_texture("default",0).get_width() * t_scale
	var t_height = texture.get_frame_texture("default",0).get_height() * t_scale
	temp_tile.queue_free()
	var padding = 10
	for x in range(width):
		map_array.append([])
		#visited.append([])
		costs.append([])
		base_array_anims.append([])
		var x_pos = t_width/2 + padding + x * (t_width + padding)
		for y in range(height):
			var y_pos = t_height/2 + padding + y * (t_height + padding)
			var tile = tile_scene.instantiate()
			tile.get_node("TileArea").position = Vector2(x_pos, y_pos)
			tile.get_node("TileArea").scale = Vector2(t_scale, t_scale)
			tile.init_tile(x,y,x_pos,y_pos,t_width,t_height)
			map_array[x].append(tile)
			base_array_anims[x].append("default")
			add_child(tile)
			tile.connect("selected", Callable(self, "_on_Tile_selected"))
			tile.connect("add_path", Callable(self, "_on_Tile_add_path"))
			tile.connect("finish_path", Callable(self, "_on_Tile_finish_path"))
			tile.connect("aim", Callable(self, "_on_Tile_aim"))
			#visited[x].append(false)
			costs[x].append(0)
	for c in contents:
		var c_x = c.x
		var c_y = c.y
		var t = map_array[c_x][c_y]
		c.position = Vector2(t.get_x_pos(),t.get_y_pos())
		c.scale = Vector2(c_scale,c_scale)
		#c.start(c_x,c_y)
		t.set_contents(c)

func _on_Tile_add_path(tile):
	if state.selected_op.can_move:
		var last_node = state.path[state.path.size()-1]
		if tile != last_node:
			reset_except_path()
			var new_path = bfs(last_node.x,last_node.y,tile.x,tile.y,state.remain_selection_depth)
			if new_path != null:
				var last_tile = state.full_path[-1]
				var l = calc_path_length(new_path)
				l += calc_diff_length(last_tile, new_path[0])
				state.remain_selection_depth -= l
				state.path.append(tile)
				for i in new_path:
					state.full_path.append(i)
					var x_c = i.x
					var y_c = i.y
					var i_tile = map_array[x_c][y_c]
					path.add_point(i_tile.get_center_pos() - state.selected_tile.get_center_pos())
					$PathLine.add_point(i_tile.get_center_pos())
					#map_array[x_c][y_c].play_select_sprite()
					set_tile_anim(x_c,y_c,"select")
				if state.remain_selection_depth > 0:
					dfs_explore(tile.x,tile.y,state.remain_selection_depth)
				search_borders(tile.x,tile.y,state.selected_op.f_min_range, \
				state.selected_op.f_range)
		#state.full_path.append_array(new_path)

# return total path length of a path
func calc_path_length(path):
	if path.size() <= 1:
		return 0
	else:
		var total = 0
		var last = path[0]
		for i in path.slice(1,path.size()):
			total += calc_diff_length(i,last)
			last = i
		return total
		
# return path length between two (adjacent) tiles
func calc_diff_length(t1, t2):
	var xdiff = t1.x - t2.x
	var ydiff = t1.y - t2.y
	if xdiff == 0 and ydiff == 0:
		return 0
	elif xdiff == 0 or ydiff == 0:
		return 1
	else:
		return 1.5
		
# return distance between any two tiles
func dist(t1,t2):
	var xdiff = abs(t1.x - t2.x)
	var ydiff = abs(t1.y - t2.y)
	var diags = min(xdiff,ydiff)
	var cardinals = max(xdiff,ydiff) - diags
	return diags * 1.5 + cardinals
# Same as above but for vectors, just in case i decide to change how grid tile coords
# are named
func dist_v(v1,v2):
	var xdiff = abs(v1.x - v2.x)
	var ydiff = abs(v1.y - v2.y)
	var diags = min(xdiff,ydiff)
	var cardinals = max(xdiff,ydiff) - diags
	return diags * 1.5 + cardinals
	
func _on_Tile_selected():
	#path.add_point(state.selected_tile.get_center_pos())
	clear_map()
	if state.selected_op.team == curr_team:
		if state.selected_op.has_action:
			if state.selected_op.can_fire:
			#	border_explore(state.selected_tile.x,state.selected_tile.y,state.selected_op.f_range,true,true)
				search_borders(state.selected_tile.x,state.selected_tile.y,state.selected_op.f_min_range, \
				state.selected_op.f_range)
			if state.selected_op.can_move:
				path.add_point(Vector2(0,0))
				$PathLine.add_point(state.selected_tile.get_center_pos())
				dfs_explore(state.selected_tile.x,state.selected_tile.y,state.remain_selection_depth)
			emit_signal("selected")
		else:			
			emit_signal("end_path")
	else:
		if state.selected_op.can_move and state.selected_op.can_fire:
			var reachable_ts = dfs_explore(state.selected_tile.x,state.selected_tile.y,state.remain_selection_depth)
			for t in reachable_ts:
				search_borders(t.x,t.y,state.selected_op.f_min_range, \
				state.selected_op.f_range)
		elif state.selected_op.can_fire:
			search_borders(state.selected_tile.x,state.selected_tile.y,state.selected_op.f_min_range, \
			state.selected_op.f_range)
		elif state.selected_op.can_move:
			dfs_explore(state.selected_tile.x,state.selected_tile.y,state.selected_op.move_range)
		emit_signal("end_path")
		
func _on_Tile_finish_path(tile):
	if state.remain_selection_depth >= 0 and state.path[-1].x == tile.x \
	and state.path[-1].y == tile.y and state.full_path[-1].x == tile.x \
	and state.full_path[-1].y == tile.y and state.selected_op != null \
	and state.selected_tile != null and state.end_tile != null and state.end_tile.traversable():
		f_end_turn()
		emit_signal('end_path')
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func clear_visited():
	for x in range(width):
		for y in range(height):
			#visited[x][y] = false
			costs[x][y] = 0
func play_path(op):
	$Path2D/PathFollow2D.add_child(op)
	tween_op = op
	var n = path.get_point_count()
	#var tween = get_node("Tween")
	var tween = get_tree().create_tween()
	tween.connect("finished", Callable(self,"_on_Tween_tween_completed"))
	#for i in range(n):
	#	$Path2D/PathFollow2D.set_unit_offset(i/n)
	tween.tween_property($Path2D/PathFollow2D,"progress_ratio",1,n/100.0)
	#tween.start()
	#$Path2D/PathFollow2D.remove_child(op)
	return
func _on_Tween_tween_completed():
	$Path2D.curve.clear_points()
	$Path2D/PathFollow2D.remove_child(tween_op)
	tween_op = null
	emit_signal("path_tween_completed")

# Finds a path using bfs from the start tile to the end tile given the depth limit
# taking step in cardinal direction costs 1, taking step in diagonal costs 1.5
func bfs(start_x,start_y,end_x,end_y,depth_limit):
	if !tile_valid(end_x,end_y) or !tile_traversable(end_x,end_y):
		return null
	if start_x == end_x and start_y == end_y:
		return []
	clear_visited()
	var bfs_queue = [Vector2(start_x,start_y)]
	var bfs_paths = [[]]
	var bfs_costs = [0]
	while(bfs_queue.size() > 0):
		var curr_pos = bfs_queue.pop_front()
		var curr_x = curr_pos.x
		var curr_y = curr_pos.y
		var curr_path = bfs_paths.pop_front()
		var curr_cost = bfs_costs.pop_front()
		#if depth_limit - curr_path.size() <= 0:
		if curr_cost > depth_limit:
			continue
		else:
			# visited[curr_x][curr_y] = true
			for dir in [Vector2(curr_x - 1, curr_y),Vector2(curr_x+1,curr_y), \
			Vector2(curr_x,curr_y-1),Vector2(curr_x,curr_y+1)]:
				if tile_valid(dir.x, dir.y) and tile_traversable(dir.x,dir.y):
					if dir.x == end_x and dir.y == end_y and curr_cost + 1 <= depth_limit:
						curr_path.append(Vector2(end_x,end_y))
						return curr_path
					#if !visited[dir.x][dir.y]:
					if costs[dir.x][dir.y] == 0 or curr_cost + 1 < costs[dir.x][dir.y]:
						var next_left = curr_path.duplicate()
						next_left.append(dir)
						bfs_queue.push_back(dir)
						bfs_paths.push_back(next_left)
						bfs_costs.push_back(curr_cost + 1)
						costs[dir.x][dir.y] = curr_cost + 1
			for dir in [Vector2(curr_x-1,curr_y-1),Vector2(curr_x+1,curr_y+1), \
			Vector2(curr_x-1,curr_y+1), Vector2(curr_x+1,curr_y-1)]:
				if tile_valid(dir.x, dir.y) and tile_traversable(dir.x,dir.y):
					if dir.x == end_x and dir.y == end_y and curr_cost + 1.5 <= depth_limit:
						curr_path.append(Vector2(end_x,end_y))
						return curr_path
					#if !visited[dir.x][dir.y]:
					if costs[dir.x][dir.y] == 0 or curr_cost + 1.5 < costs[dir.x][dir.y]:
						var next_left = curr_path.duplicate()
						next_left.append(dir)
						bfs_queue.push_back(dir)
						bfs_paths.push_back(next_left)
						bfs_costs.push_back(curr_cost + 1.5)
						costs[dir.x][dir.y] = curr_cost + 1.5
	return null

# explores to depth limit, sets all tiles to show availability
func dfs_explore(start_x,start_y,depth_limit):
	clear_visited()
	var dfs_stack = [Vector2(start_x,start_y)]
	var dfs_costs = [0]
	var ret = []
	while(dfs_stack.size() > 0):
		var curr_pos = dfs_stack.pop_back()
		var curr_x = curr_pos.x
		var curr_y = curr_pos.y
		var curr_cost = dfs_costs.pop_back()
		if curr_cost >= depth_limit:
			continue
		else:
			for dir in [Vector2(curr_x - 1, curr_y),Vector2(curr_x+1,curr_y), \
			Vector2(curr_x,curr_y-1),Vector2(curr_x,curr_y+1)]:
				if tile_valid(dir.x, dir.y) and tile_traversable(dir.x,dir.y):
					if curr_cost + 1 <= depth_limit and costs[dir.x][dir.y] == 0:
						set_base_anim(dir.x,dir.y,"avail")
						set_tile_anim(dir.x,dir.y,"avail")
						ret.push_back(dir)
					if curr_cost + 1 <= depth_limit and (curr_cost + 1 < costs[dir.x][dir.y] \
					or costs[dir.x][dir.y] == 0):
						dfs_stack.push_back(dir)
						dfs_costs.push_back(curr_cost + 1)
						costs[dir.x][dir.y] = curr_cost + 1
			for dir in [Vector2(curr_x-1,curr_y-1),Vector2(curr_x+1,curr_y+1), \
			Vector2(curr_x-1,curr_y+1), Vector2(curr_x+1,curr_y-1)]:
				if tile_valid(dir.x, dir.y) and tile_traversable(dir.x,dir.y):
					if curr_cost + 1.5 <= depth_limit and costs[dir.x][dir.y] == 0:
						set_base_anim(dir.x,dir.y,"avail")
						set_tile_anim(dir.x,dir.y,"avail")
						ret.push_back(dir)
					if curr_cost + 1.5 <= depth_limit and (curr_cost + 1.5 < costs[dir.x][dir.y] \
					or costs[dir.x][dir.y] == 0):
						dfs_stack.push_back(dir)
						dfs_costs.push_back(curr_cost + 1.5)
						costs[dir.x][dir.y] = curr_cost + 1.5
	return ret

# generates next tiles to consider for border_explore (adjacent tiles to current
# in direction next_dx next_dy)
func next_possible_tiles(curr_x,curr_y,next_dx,next_dy):
	var dirs = [Vector2(curr_x,curr_y-1),Vector2(curr_x-1,curr_y-1), \
	Vector2(curr_x-1,curr_y), Vector2(curr_x-1,curr_y+1),Vector2(curr_x,curr_y+1), \
	Vector2(curr_x+1,curr_y+1),Vector2(curr_x+1,curr_y),Vector2(curr_x+1,curr_y-1)]
	if next_dx > 0:
		if next_dy == 0:
			return dirs.slice(5,8)
		elif next_dy > 0:
			return dirs.slice(4,7)
		else: 
			var ret = dirs.slice(6,8)
			ret.push_back(dirs[0])
			return ret
	elif next_dx == 0:
		if next_dy > 0: 
			return dirs.slice(3,6)
		elif next_dy < 0:
			var ret = dirs.slice(0,2)
			ret.push_back(dirs[7])
			return ret
		else:
			print("Both 0, something not right")
			return "error"
	else:
		if next_dy == 0:
			return dirs.slice(1,4)
		elif next_dy > 0:
			return dirs.slice(2,5)
		else:
			return dirs.slice(0,3)
			
# OLD IMPLEMENTATION TO SHOW FIRING RANGE
# similar to dfs_explore, except only returns border tiles (note, errors may occur if used with 
# depth 0 or 1, avoid). parameter inner: generates tiles on the inner side of the circle (farthest tile(s)
# who are closer than the depth) if true, outer side if false (closest tile(s) who are farther than depth)
# REUSED IN NEW IMPLEMENTATION
func border_explore(start_x,start_y,depth,inner=true,thick=false,draw=false):
	var curr_x = start_x + depth
	var curr_y = start_y
	var start_v = Vector2(start_x,start_y)
	var next_dx = 0
	var next_dy = depth
	var next_dirs = next_possible_tiles(curr_x,curr_y,next_dx,next_dy)
	var next_x = null
	var next_y = null
	if draw and tile_valid(curr_x,curr_y):
		set_tile_anim(curr_x,curr_y,"range")
		set_base_anim(curr_x,curr_y,"range")
	var ret = [Vector2(curr_x,curr_y)]
	while !next_dirs.has(Vector2(start_x+depth,start_y)):
		for dir in next_dirs:
			if thick and dist_v(start_v,dir) <= depth:
				ret.push_back(Vector2(dir.x,dir.y))
			if inner:
				if dist_v(start_v,dir) <= depth and \
				((next_x == null and next_y == null) or \
				dist_v(start_v,dir) > dist_v(start_v,Vector2(next_x,next_y))):
					next_x = dir.x
					next_y = dir.y
			else:
				if dist_v(start_v,dir) >= depth and \
				((next_x == null and next_y == null) or \
				dist_v(start_v,dir) < dist_v(start_v,Vector2(next_x,next_y))):
					next_x = dir.x
					next_y = dir.y
		curr_x = next_x
		curr_y = next_y
		next_dirs = next_possible_tiles(curr_x,curr_y,start_y-curr_y,curr_x-start_x)
		if !thick:
			ret.push_back(Vector2(curr_x,curr_y))
#		if tile_valid(curr_x,curr_y):
#			var c_tile = map_array[curr_x][curr_y]
#			draw_debug(c_tile.x_pos,c_tile.y_pos)
		if draw and tile_valid(curr_x,curr_y):
			set_tile_anim(curr_x,curr_y,"range")
			set_base_anim(curr_x,curr_y,"range")
		next_x = null
		next_y = null
	return ret

# helper function to generate a line from one point to another, cover is whether
# or not cover is accounted for (if yes, then line will stop at first cover)
# returns an array, first element is true if cover was hit and false otherwise, 
# false if cover is false. Remaining elements are path coordinates. The cover tile
# is included at the end of the array if cover is true and one was hit. The first tile
# and last tile (specified by start and end) are included in the second and last positions
# respectively. Start and end tiles not considered for cover check.
func gen_line(start_x,start_y,end_x,end_y,cover):
	var curr_x = start_x
	var curr_y = start_y
	var start_v = Vector2(start_x,start_y)
	var curr_v = Vector2(start_x,start_y)
	var end_v = Vector2(end_x,end_y)
	var ret = [curr_v]
	var dir_x = end_x - start_x
	var dir_y = end_y - start_y
	var next_x = null
	var next_y = null
	var next_diff = -1
	var i = 0
	while (curr_x != end_x or curr_y != end_y):
		i += 1
		var dirs = next_possible_tiles(curr_x,curr_y,dir_x,dir_y)
		for dir in dirs:
			if dir.x == end_x and dir.y == end_y:
				ret.push_back(dir)
				ret.push_front(false)
				return ret
			#var tot_dist = pow(dist_v(dir,start_v),2) + pow(dist_v(dir,end_v),2)
			var a_diff = abs((dir - start_v).angle_to(end_v - dir))
			if (next_diff == -1) or (a_diff < next_diff):
				next_diff = a_diff
				next_x = dir.x
				next_y = dir.y
		curr_v = Vector2(next_x,next_y)
		curr_x = next_x
		curr_y = next_y
		ret.push_back(curr_v)
		if (curr_v != start_v) and (curr_v != end_v) and cover and \
		tile_valid(curr_x,curr_y) and !map_array[curr_x][curr_y].transparent() and \
		not map_array[curr_x][curr_y].check_contents(state.selected_op):
			ret.push_front(true)
			return ret
		next_x = null
		next_y = null
		next_diff = -1
	ret.push_front(false)
	return ret
	
func search_borders_helper(border_ts,start_x,start_y):
	for border_t in border_ts:
		var curr_b_x = border_t.x
		var curr_b_y = border_t.y
		if tile_valid(curr_b_x,curr_b_y) and map_array[curr_b_x][curr_b_y].get_anim() == "range":
			continue
		var aff_tiles = gen_line(start_x,start_y,curr_b_x,curr_b_y,true)
		# note tiles is an array of vector2s
		if aff_tiles.size() == 0:
			continue
		if !aff_tiles[0] and tile_valid(curr_b_x,curr_b_y):
			set_tile_anim(curr_b_x,curr_b_y,"range")
			set_base_anim(curr_b_x,curr_b_y,"range")
# NEW IMPLEMENTATION for showing firing range borders, covers all area reachable
# -1 or 0 depth if unused (inner unused just means no hole in the middle, outer 
# should not be unused). Accounts for cover
func search_borders(start_x,start_y,inner_depth,outer_depth):
#	for border_t in border_explore(start_x,start_y,outer_depth,true):
#		var curr_b_x = border_t.x
#		var curr_b_y = border_t.y
#		var aff_tiles = gen_line(start_x,start_y,curr_b_x,curr_b_y,true)
#		# note tiles is an array of vector2s
#		var tiles = aff_tiles.slice(2,-1)
#		# var path_length = 0
#		if tiles.size() <= 1:
#			return
#		var curr_tile = tiles[1]
#		for a_t in tiles:
#			# path_length += dist_v(a_t,curr_tile)
#			curr_tile = a_t
#			# path_length >= inner_depth
#			if tile_valid(a_t.x,a_t.y) and ((inner_depth > 0 and \
#			dist_v(a_t,Vector2(start_x,start_y)) >= inner_depth) or inner_depth <= 0):
#				map_array[a_t.x][a_t.y].play_range_sprite()
#				base_array_anims[a_t.x][a_t.y] = "range"
	var inner = max(inner_depth,1)
	for r in range(inner,outer_depth+1):
		if r == inner:
			search_borders_helper(border_explore(start_x,start_y,r,false),start_x,start_y)
		else:
			search_borders_helper(border_explore(start_x,start_y,r),start_x,start_y)
				

func reset_firing():
	if firing:
		collisions = []
		fire_start_center_pos = null
		fire_target = null
		
		firing = false
		$FireLine.clear_points()
	
func _on_Tile_aim(target):
	if state.selected_op == null or not state.selected_op.can_fire:
		return
	if state.selected_op.get_parent() == target:
		state.selection = -1
		f_end_turn()
		emit_signal('end_path')
		return
	# Get the last position of the selected operator (either their current position or the last node
	# on their current path
	var op_last_pos = state.selected_op.get_parent().get_grid_pos()
	if state.selection > 1:
		op_last_pos = state.path[-1].get_grid_pos()
	if firing and (target != state.fire_target or fire_start_grid_pos != op_last_pos):
		# step 1: firing at a different target or from a different position, clear 
		# and redraw at step 3
		reset_firing()
		reset_collision_markers()
	elif firing and target == state.fire_target and fire_start_grid_pos == op_last_pos and can_fire:
		# step 2: double selecting the same target, from the same position: 
		# confirm fire, clear and do not redraw
		target.get_target().damage(state.selected_op.atk)
		reset_firing()
		state.selected_op.fired(target.x,target.y)
		if state.selection > 1:
			state.end_tile = state.path[-1]
			_on_Tile_finish_path(state.path[-1])
		else:
			emit_signal('end_path')
		f_end_turn()
		return
	if state.selected_op != null and target != state.selected_op.get_parent() \
	and target.valid_firing_target() and target.get_target().team != state.selected_op.team \
	and dist(op_last_pos, target) <= state.selected_op.f_range and \
	dist(op_last_pos,target) >= state.selected_op.f_min_range:
		# step 3: if the firing op and the target are valid and the target is not the firing op, 
		# and the range is within the firing op's range,
		# update the fire line and other relevant vars to reflect selection (redraw)
		reset_collision_markers()
		var firing_op = state.selected_op
		if state.selection == 1:
			fire_start_center_pos = firing_op.position
			fire_start_grid_pos = firing_op.get_parent().get_grid_pos()
		elif state.selection > 1:
			fire_start_center_pos = state.path[-1].get_center_pos()
			fire_start_grid_pos = state.path[-1].get_grid_pos()
		else:
			return
		
		var end_pos = target.get_center_pos()

		var lines = gen_line(fire_start_grid_pos.x,fire_start_grid_pos.y,target.x,target.y,true)
#		for l in range(1,lines.size()):
#			map_array[lines[l].x][lines[l].y].play_select_sprite()
		
		fire_target = target
		state.fire_target = target
		firing = true
#		var dx = end_pos.x - fire_start_pos.x
#		var dy = end_pos.y - fire_start_pos.y
#		var midpoint = (end_pos + fire_start_pos) / 2.0
#		var length = sqrt(pow(dx,2)+pow(dy,2))
#		$Area2D.rotation = Vector2(dx,dy).angle()
#		$Area2D.position = midpoint 
#		$Area2D.scale = Vector2(length,1)
#		waiting_collisions = true
		can_fire = process_aim()
		
# OLD IMPLEMENTATION: used area2d collision to check for cover
#func process_aim():
#	if firing:
##		var state = get_node("/root/State")
#		for collide in collisions:
#			var t = collide.get_parent()
#			if !t.transparent() and t != fire_target and t != state.selected_tile:
#				reset_firing()
#				return
#		$FireLine.add_point(fire_start_pos)
#		$FireLine.add_point(fire_target.get_center_pos())

# NEW IMPLEMENTATION: uses gen_line. Returns: whether a valid firing line can be 
# drawn between target and source
func process_aim():
	if firing:
		var path = gen_line(fire_start_grid_pos.x,fire_start_grid_pos.y,fire_target.x,fire_target.y,true)
		var covered = path[0]
		# TODO: may cause issues in the future due to slice functionality update (second argument now inclusive)
		var tiles = path.slice(1,-1)
		for tile in tiles:
			if covered:
				play_collided_tiles.push_back(tile)
				set_tile_anim(tile.x,tile.y,"blocked")
			else:
				play_collided_tiles.push_back(tile)
				set_tile_anim(tile.x,tile.y,"select")
		if !covered:
			$FireLine.add_point(fire_start_center_pos)
			$FireLine.add_point(fire_target.get_center_pos())
		return !covered
	else:
		return false
#func update_sprite(x,y,anim):
	
# OLD IMPLEMENTATION to detect collisions for firing
#func _physics_process(delta):
#	# It seems that get_overlapping_areas is only updated after the code in this 
#	# function is executed, so just wait a cycle before calling collisions ready
#	# a bit jank
#	if waiting_collisions and cycles_waited == 0:
#		cycles_waited = 1
#	elif waiting_collisions and cycles_waited == 1:
#		cycles_waited = 0
#		waiting_collisions = false
#		collisions = $Area2D.get_overlapping_areas()
#		emit_signal("collisions_ready")
		# reset_firing()

#func _on_Area2D_area_entered(area):
#	if area.get_parent().get_filename() == "res://Tile.tscn":
#		area.get_parent().play_select_sprite()
#		collisions.append(area)
#		process_aim()
#
#
#func _on_Area2D_area_exited(area):
#	if area.get_parent().get_filename() == "res://Tile.tscn":
#		area.get_parent().play_normal_sprite()
#		collisions.erase(area)
#		process_aim()
#

# ends or cancels the turn (cancels if state.selection == -1)
# (resets animations and path
func f_end_turn():
	$PathLine.clear_points()
	$FireLine.clear_points()
	for i in range(width):
		for j in range(height):
			set_base_anim(i,j,"default")
			set_tile_anim(i,j,"default")
			#if map_array[i][j].contents != null:
			#	map_array[i][j].contents.end_turn()
	if (state.selection == -1):
		$Path2D.curve.clear_points()
	#emit_signal("end_turn")
	
func clear_map():
	for i in range(width):
		for j in range(height):
			set_base_anim(i,j,"default")
			set_tile_anim(i,j,"default")

func _on_Map_collisions_ready():
	for c in collisions:
		if c.get_parent().get_scene_file_path() != "res://Tile.tscn":
			collisions.erase(c)
		#else: 
			#c.get_parent().play_select_sprite()
			#play_collided_tiles.append(c)
	process_aim()
