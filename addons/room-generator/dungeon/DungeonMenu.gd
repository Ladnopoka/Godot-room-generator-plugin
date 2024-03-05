@tool
extends Node3D

@onready var grid_map : GridMap = $GridMap

@export var generate : bool = false : set = set_start
@export var border_size : int = 20 : set = set_border_size
@export var MIN_room_size : int = 3
@export var MAX_room_size: int = 8
@export var room_number : int = 4
@export var room_margin : int = 1 #minimum distance the rooms must keep from each other
@export var room_recursion_tries : int = 15

@export_range(0,1) var survival_chance : float = 0.25
@export_multiline var generate_with_custom_seed : String = "" : set = set_seed
func set_seed(val):
	generate_with_custom_seed = val
	seed(val.hash())

var room_tiles : Array[PackedVector3Array] = []
var room_positions : PackedVector3Array

func set_start(val:bool):
	if Engine.is_editor_hint():
		generate_tiles() #eventually generate a whole dungeon

func set_border_size(val : int):
	border_size = val
	if Engine.is_editor_hint():
		visualize_border()
	
func visualize_border():
	if grid_map:
		grid_map.clear() # need to clear every time because the textures stay
		for pos1 in range(-1, border_size + 1): # border size has to be 1 grid cell bigger because of inner contents
			grid_map.set_cell_item(Vector3i(pos1, 0, -1), 3)
			grid_map.set_cell_item(Vector3i(pos1, 0, border_size), 3)
			grid_map.set_cell_item(Vector3i(border_size, 0, pos1), 3)
			grid_map.set_cell_item(Vector3i(-1, 0, pos1), 3)
	
func generate_tiles():
	room_tiles.clear() #need to clear
	room_positions.clear() #need to clear 
	if generate_with_custom_seed: set_seed(generate_with_custom_seed)
	
	visualize_border()
	for i in room_number: # for every room number
		generate_room(room_recursion_tries)
	
	# Below code is the minimum spanning tree algorithm
	var room_pv2 : PackedVector2Array = []
	var delaunay_graph : AStar2D = AStar2D.new() #AStar2D requires and ID and a position for each point
	var min_span_tree_graph : AStar2D = AStar2D.new()
	
	#turn room positions into Vector2's, this only places the points
	for p in room_positions:
		room_pv2.append(Vector2(p.x, p.z))
		delaunay_graph.add_point(delaunay_graph.get_available_point_id(), Vector2(p.x, p.z))
		min_span_tree_graph.add_point(min_span_tree_graph.get_available_point_id(), Vector2(p.x, p.z))
	
	# Doing the actual triangulation
	# triangulate_delaunay() function here takes in a packed Vector2 array
	# and returns an array of integers in a form of a packed int32 array
	# we need to conver this into a regular array first
	var delaunay_triangulation : Array = Array(Geometry2D.triangulate_delaunay(room_pv2))
	
	# explained more in depth in the report, but this is basically the Delaunay graph
	for i in delaunay_triangulation.size()/3: # 3 for number of triangles
		var p1 : int = delaunay_triangulation.pop_front()
		var p2 : int = delaunay_triangulation.pop_front()
		var p3 : int = delaunay_triangulation.pop_front()
		delaunay_graph.connect_points(p1, p2)
		delaunay_graph.connect_points(p2, p3)
		delaunay_graph.connect_points(p1, p3)
		
	var visited_points : PackedInt32Array = []
	visited_points.append(randi() % room_positions.size()) #this will give us a random point in graph
	while visited_points.size() != min_span_tree_graph.get_point_count(): # loop until size of visited points is higher than graph
		var possible_connections : Array[PackedInt32Array] = []
		for vp in visited_points: #for every visited point in points
			for c in delaunay_graph.get_point_connections(vp): #for each connection within visited point
				if !visited_points.has(c): #make sure the point is not visited already
					var con : PackedInt32Array = [vp, c]
					possible_connections.append(con)
		
		var connection : PackedInt32Array = possible_connections.pick_random()
		for pc in possible_connections: #for each possible connection (pc)
			if room_pv2[pc[0]].distance_squared_to(room_pv2[pc[1]]) < room_pv2[connection[0]].distance_squared_to(room_pv2[connection[1]]):
				connection = pc
				
		visited_points.append(connection[1])
		min_span_tree_graph.connect_points(connection[0], connection[1])
		delaunay_graph.disconnect_points(connection[0], connection[1])
		
	var tunnel_graph = min_span_tree_graph
	for p in delaunay_graph.get_point_ids():
		for c in delaunay_graph.get_point_connections(p):
			if c > p:
				var kill = randf()
				if survival_chance > kill:
					print("Survival: ", survival_chance)
					print("Kill: ", kill)
					tunnel_graph.connect_points(p, c)
					
	create_tunnels(tunnel_graph)
	
func create_tunnels(tunnel_graph):
	# //// this part of the code is for marking the doors on the rooms
	var tunnels : Array[PackedVector3Array] = []
	for p in tunnel_graph.get_point_ids():
		for c in tunnel_graph.get_point_connections(p):
			if c > p:
				var room_from : PackedVector3Array = room_tiles[p]
				var room_to : PackedVector3Array = room_tiles[c]
				var tile_from : Vector3 = room_from[0]
				var tile_to : Vector3 = room_to[0]
				
				print("from: ", tile_from)
				print("to: ", tile_to)
				
				for t in room_from:
					if t.distance_squared_to(room_positions[c]) < tile_from.distance_squared_to(room_positions[c]):
							tile_from = t
				for t in room_to:
					if t.distance_squared_to(room_positions[p]) < tile_to.distance_squared_to(room_positions[p]):
							tile_to = t
				
				var tunnel : PackedVector3Array = [tile_from, tile_to]
				tunnels.append(tunnel)
				grid_map.set_cell_item(tile_from, 2)
				grid_map.set_cell_item(tile_to, 2)
	# /////// end of code for marking doors

	var astar = AStarGrid2D.new()
	astar.size = Vector2i.ONE * border_size
	astar.update()
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	
	#Define the obstacle tiles here
	for t in grid_map.get_used_cells_by_item(0):
		astar.set_point_solid(Vector2i(t.x, t.z))
	
	#actual pathfinding	
	for tun in tunnels: # for every tunnel in tunnels, we are making a hall variable to store the path
		var pos_from = Vector2i(tun[0].x, tun[0].z) #from this point
		var pos_to = Vector2i(tun[1].x, tun[1].z) #to this point
		var hall = astar.get_point_path(pos_from, pos_to)
		
		for t in hall:
			var pos = Vector3i(t.x, 0, t.y)
			if grid_map.get_cell_item(pos) < 0:
				grid_map.set_cell_item(pos, 1) # finally, set the cell to a tunnel tile
				
func generate_room(rec: int):
	if !rec > 0: #don't run if recursion limit is reached
		return
	# get random width and heights
	var width : int = (randi() % (MAX_room_size - MIN_room_size)) + MIN_room_size
	var height : int = (randi() % (MAX_room_size - MIN_room_size)) + MIN_room_size
	
	#pick starting position
	var start_pos : Vector3i
	start_pos.x = randi() % (border_size - width + 1) # need to have +1 there at the end because of how the mod operator works
	start_pos.z = randi() % (border_size - height + 1)
	
	# Minimum distance checker that rooms should keep away form each other (margin)
	for r in range(-room_margin, height + room_margin): #for every row in height
		for c in range(-room_margin, width + room_margin):	#for every column in width
			var pos : Vector3i = start_pos + Vector3i(c, 0, r) # variable for the position
			if grid_map.get_cell_item(pos) == 0: #check if the cell is a previously defined texture (hardcoded number fix later)
				generate_room(rec-1) #gererate rooms until recursion checker is triggered
				return
	
	#we fill in the columns from left to right 
	var room : PackedVector3Array = []
	for r in height: #for every row in height
		for c in width:	#for every column in width
			var pos : Vector3i = start_pos + Vector3i(c, 0, r) # variable for the position
			grid_map.set_cell_item(pos, 0) #set texture for dungeon walls????????
			room.append(pos) 	#add to room array for each iteration
	room_tiles.append(room) #append whole room to the tiles
	
	#calculating x an z positions separately
	var avg_x : float = start_pos.x + (float(width)/2)
	var avg_z : float = start_pos.z + (float(height)/2)
	var pos : Vector3 = Vector3(avg_x, 0, avg_z)
	room_positions.append(pos)
