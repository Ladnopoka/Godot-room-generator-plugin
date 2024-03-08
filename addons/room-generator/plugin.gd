@tool
extends EditorPlugin

#const dungeon_menu_script = preload("res://addons/room-generator/dungeon/DungeonMenu.gd")
const panel = preload("res://addons/room-generator/panel.tscn")
const RoomTemplate = preload("res://addons/room-generator/room_template/room_template.tscn")
#dungeon textures
const dungeon_corner_in = preload("res://addons/room-generator/dungeon_tiles/dungeon_corner_in.tscn")
const dungeon_corner_out = preload("res://addons/room-generator/dungeon_tiles/dungeon_corner_out.tscn")
const dungeon_floor = preload("res://addons/room-generator/dungeon_tiles/dungeon_floor.tscn")
const dungeon_wall = preload("res://addons/room-generator/dungeon_tiles/dungeon_wall.tscn")
#wooden cabin textures
const WOODEN_CABIN_CEILING = preload("res://addons/room-generator/texture_tiles/wooden_cabin_ceiling.tscn")
const WOODEN_CABIN_DOOR = preload("res://addons/room-generator/texture_tiles/wooden_cabin_door.tscn")
const WOODEN_CABIN_FLOOR = preload("res://addons/room-generator/texture_tiles/wooden_cabin_floor.tscn")
const WOODEN_CABIN_WALL = preload("res://addons/room-generator/texture_tiles/wooden_cabin_wall.tscn")
#frozen caves textures
const FROZEN_CAVES_CEILING = preload("res://addons/room-generator/texture_tiles/frozen_caves_ceiling.tscn")
const FROZEN_CAVES_DOOR = preload("res://addons/room-generator/texture_tiles/frozen_caves_door.tscn")
const FROZEN_CAVES_FLOOR = preload("res://addons/room-generator/texture_tiles/frozen_caves_floor.tscn")
const FROZEN_CAVES_WALL = preload("res://addons/room-generator/texture_tiles/frozen_caves_wall.tscn")
#player controllers
const THIRD_PERSON_PLAYER = preload("res://addons/room-generator/player/third_person_player.tscn")
#images
const DUNGEON_BACKGROUND = preload("res://addons/room-generator/icons/dungeon_background.png")
const WOODEN_CABIN_BACKGROUND = preload("res://addons/room-generator/icons/wooden_cabin_background.png")
const FROZEN_CAVES_BACKGROUND = preload("res://addons/room-generator/icons/frozen_caves_background.png")
#this is the dungeon generator
const dungeon_menu = preload("res://addons/room-generator/dungeon/dungeon_menu.tscn")

var dockedScene
#var toggle_button: Button
var tab_container: TabContainer
var is_content_visible: bool = false  # Tracks whether the content is currently visible

var stored_gridmaps: Array[GridMap] = []
var wall_button: Button
var first_person_controller: Button
var isometric_controller: Button
var hideout_button: Button
var dungeon_menu_button: MenuButton
var dungeon_layout_button: Button
var dungeon_popup_menu
var wooden_cabins_popup_menu
var wooden_cabin_menu_button
var frozen_caves_menu_button
var frozen_caves_popup_menu

# Get the undo/redo object
var undo_redo = get_undo_redo()

func _enter_tree():
	dockedScene = panel.instantiate()
	print("RoomGenerator panel scene instantiated!")
	
	tab_container = dockedScene.get_node("TabContainer")
	tab_container.visible = true
	
	setup_button_connections()
	setup_dungeon_menu_button()
		
	# Initial setup when the plugin is enabled
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dockedScene)

func setup_button_connections():
	# Connect the toggle button signal
	first_person_controller = dockedScene.get_node("TabContainer/Player Controller/First Person Player Controller")
	isometric_controller = dockedScene.get_node("TabContainer/Player Controller/Isometric Player Controller")
	hideout_button = dockedScene.get_node("TabContainer/Layouts/Hideout")
	dungeon_menu_button = dockedScene.get_node("TabContainer/Models/DungeonGeneratorMenu")
	wooden_cabin_menu_button = dockedScene.get_node("TabContainer/Models/DungeonGeneratorMenu")
	dungeon_layout_button = dockedScene.get_node("TabContainer/Layouts/Dungeon")
	wooden_cabin_menu_button = dockedScene.get_node("TabContainer/Models/WoodenCabinGeneratorMenu")	
	frozen_caves_menu_button = dockedScene.get_node("TabContainer/Models/FrozenCaveGeneratorMenu")	

	first_person_controller.connect("pressed", create_first_person_controller)
	isometric_controller.connect("pressed", create_isometric_controller)
	#menu_button.connect("pressed", menu_button_pressed)
	wooden_cabin_menu_button.connect("pressed", wooden_cabin_menu_button_pressed)
	frozen_caves_menu_button.connect("pressed", frozen_caves_menu_button_pressed)
	
func wooden_cabin_menu_button_pressed():
	if wooden_cabins_popup_menu:
		wooden_cabins_popup_menu.clear()
		if wooden_cabins_popup_menu.is_connected("id_pressed", instantiate_wooden_cabin_texture):
			wooden_cabins_popup_menu.disconnect("id_pressed", instantiate_wooden_cabin_texture)
			
	wooden_cabins_popup_menu = wooden_cabin_menu_button.get_popup()
	var popup_theme = Theme.new()  # Create a new theme
	
	var style_box = StyleBoxTexture.new()
	var bg_image = WOODEN_CABIN_BACKGROUND
	style_box.texture = bg_image

	var popup_font = FontFile.new()
	popup_font.font_data = load("res://addons/room-generator/fonts/Diablo Heavy.ttf")  # Replace with the path to your font file
	popup_theme.set_font("font", "PopupMenu", popup_font)
	popup_theme.set_color("font_color", "PopupMenu", Color(0.663, 0.91, 0))  
	popup_theme.set_font_size("font_size", "PopupMenu", 30)

	wooden_cabins_popup_menu.theme = popup_theme
	wooden_cabins_popup_menu.add_theme_stylebox_override("panel", style_box)
	
	wooden_cabins_popup_menu.add_item("Wall")
	wooden_cabins_popup_menu.add_item("Entrance")
	wooden_cabins_popup_menu.add_item("Ceiling")
	wooden_cabins_popup_menu.add_item("Floor")
	wooden_cabins_popup_menu.add_item("GridMap Generator")
	wooden_cabins_popup_menu.connect("id_pressed", instantiate_wooden_cabin_texture)
	
func frozen_caves_menu_button_pressed():
	print("frozen cabins pressed")
	if frozen_caves_popup_menu:
		frozen_caves_popup_menu.clear()
		if frozen_caves_popup_menu.is_connected("id_pressed", instantiate_frozen_caves_texture):
			frozen_caves_popup_menu.disconnect("id_pressed", instantiate_frozen_caves_texture)
			
	frozen_caves_popup_menu = frozen_caves_menu_button.get_popup()
	var popup_theme = Theme.new()  # Create a new theme
	
	var style_box = StyleBoxTexture.new()
	var bg_image = FROZEN_CAVES_BACKGROUND
	style_box.texture = bg_image

	var popup_font = FontFile.new()
	popup_font.font_data = load("res://addons/room-generator/fonts/Diablo Heavy.ttf")  # Replace with the path to your font file
	popup_theme.set_font("font", "PopupMenu", popup_font)
	popup_theme.set_color("font_color", "PopupMenu", Color(0.902, 0.686, 1))  
	popup_theme.set_font_size("font_size", "PopupMenu", 30)

	frozen_caves_popup_menu.theme = popup_theme
	frozen_caves_popup_menu.add_theme_stylebox_override("panel", style_box)
	
	frozen_caves_popup_menu.add_item("Wall")
	frozen_caves_popup_menu.add_item("Tunnel")
	frozen_caves_popup_menu.add_item("Roof")
	frozen_caves_popup_menu.add_item("Floor")
	frozen_caves_popup_menu.add_item("GridMap Generator")
	frozen_caves_popup_menu.connect("id_pressed", instantiate_frozen_caves_texture)
	
func instantiate_frozen_caves_texture(id):
	var current_scene = get_editor_interface().get_edited_scene_root()
	var frozen_caves_texture
	
	match id:
		0:
			frozen_caves_texture = FROZEN_CAVES_WALL.instantiate()
		1:
			frozen_caves_texture = FROZEN_CAVES_DOOR.instantiate()
		2:
			frozen_caves_texture = FROZEN_CAVES_CEILING.instantiate()
		3:
			frozen_caves_texture = FROZEN_CAVES_FLOOR.instantiate()
		4:
			instantiate_dungeon_gridmap()
			return
		_:
			print("Unknown model selected")
		
	if current_scene:
		frozen_caves_texture.name = "frozen_caves_texture_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Frozen Texture")
		undo_redo.add_do_method(current_scene, "add_child", frozen_caves_texture)
		undo_redo.add_do_reference(frozen_caves_texture)
		undo_redo.add_undo_method(current_scene, "remove_child", frozen_caves_texture)
		undo_redo.commit_action(true)
		frozen_caves_texture.owner = current_scene
	else:
		print("No active scene!")	

func instantiate_wooden_cabin_texture(id):
	var current_scene = get_editor_interface().get_edited_scene_root()
	var wooden_cabin_texture
	
	match id:
		0:
			wooden_cabin_texture = WOODEN_CABIN_WALL.instantiate()
		1:
			wooden_cabin_texture = WOODEN_CABIN_DOOR.instantiate()
		2:
			wooden_cabin_texture = WOODEN_CABIN_CEILING.instantiate()
		3:
			wooden_cabin_texture = WOODEN_CABIN_FLOOR.instantiate()
		4:
			instantiate_dungeon_gridmap()
			return
		_:
			print("Unknown model selected")

	if current_scene:
		wooden_cabin_texture.name = "wooden_cabin_texture_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Wooden Cabin Texture")
		undo_redo.add_do_method(current_scene, "add_child", wooden_cabin_texture)
		undo_redo.add_do_reference(wooden_cabin_texture)
		undo_redo.add_undo_method(current_scene, "remove_child", wooden_cabin_texture)
		undo_redo.commit_action(true)
		wooden_cabin_texture.owner = current_scene
	else:
		print("No active scene!")	

func setup_dungeon_menu_button():
	dungeon_popup_menu = dungeon_menu_button.get_popup()
	var popup_theme = Theme.new()  # Create a new theme
	var style_box = StyleBoxTexture.new()
	var bg_image = DUNGEON_BACKGROUND
	style_box.texture = bg_image

	var popup_font = FontFile.new()
	#"theme_override_constants/outline_size"
	popup_font.font_data = load("res://addons/room-generator/fonts/Diablo Heavy.ttf")  # Replace with the path to your font file

	popup_theme.set_font("font", "PopupMenu", popup_font)
	popup_theme.set_color("font_color", "PopupMenu", Color(0.922, 0.675, 0.514))  # Set to black
	popup_theme.set_font_size("font_size", "PopupMenu", 30)

	dungeon_popup_menu.theme = popup_theme
	
	dungeon_popup_menu.add_theme_stylebox_override("panel", style_box)
	
	dungeon_popup_menu.add_item("Wall")
	dungeon_popup_menu.add_item("Corner IN")
	dungeon_popup_menu.add_item("Floor")
	dungeon_popup_menu.add_item("Corner OUT")
	dungeon_popup_menu.add_item("GridMap Generator")
	dungeon_popup_menu.connect("id_pressed", _on_dungeon_model_selected)
		
func _on_dungeon_model_selected(id):
	print("Dungeon Model ID: ", id)
	dungeon_menu_button.get_popup().popup()  # Show the popup again
	match id:
		0:
			instantiate_dungeon_wall()
		1:
			instantiate_dungeon_corner_in()
		2:
			instantiate_dungeon_floor()
		3:
			instantiate_dungeon_corner_out()
		4:
			instantiate_dungeon_gridmap()
		_:
			print("Unknown model selected")

#DISABLED FOR NOW, WORKING ON NEW FUNCTIONALITY	
#func dungeon_layout_button_pressed():
#	var dungeon_layout = DungeonTemplate.instantiate()
#	var current_scene = get_editor_interface().get_edited_scene_root()
#
#	if current_scene:
#		dungeon_layout.name = "Dungeon_" + str(current_scene.get_child_count())
#
#		# For undo/redo functionality:
#		undo_redo.create_action("Create Hideout")
#		undo_redo.add_do_method(current_scene, "add_child", dungeon_layout)
#		undo_redo.add_do_reference(dungeon_layout)
#		undo_redo.add_undo_method(current_scene, "remove_child", dungeon_layout)
#		undo_redo.commit_action(true)
#		dungeon_layout.owner = current_scene
#	else:
#		print("No active scene!")

func _exit_tree():
	# Clean up when the plugin is disabled
	remove_control_from_docks(dockedScene)
	dockedScene.free()

func get_plugin_name():
	return "RoomGenerator"

func get_plugin_description():
	return "An editor for creating 3D rooms, tunnels, gridmaps and more."
	
#func create_wall():
	#print("Inside create wall")
#
	## Create a new MeshInstance node
	#var wall = MeshInstance3D.new()
#
	## Create a CubeMesh for our wall
	#var cube_mesh = BoxMesh.new()
	#cube_mesh.size = Vector3(4, 2, 0.2) # adjust size as per your requirements
	#wall.mesh = cube_mesh
#
	#var current_scene = get_editor_interface().get_edited_scene_root()
	#if current_scene:
				## Name the box instance with counting already existing boxes
		#wall.name = "Wall_" + str(current_scene.get_child_count())
		## Begin a new action called "Create Box"
		#undo_redo.create_action("Create Wall")
		#
		## For the "do" operation: Add the box to the scene
		#undo_redo.add_do_method(current_scene, "add_child", wall)
		#undo_redo.add_do_reference(wall)  # Ensure box is kept in memory
		#
		## For the "undo" operation: Remove the box from the scene
		#undo_redo.add_undo_method(current_scene, "remove_child", wall)
		#undo_redo.add_undo_reference(wall)  # Ensure box is kept in memory
		#
		## Commit the action with execution
		#undo_redo.commit_action(true)
		#wall.owner = current_scene
	#else:
		#print("No active scene!")
	
func create_isometric_controller():
	print("inside isometric controller")
	#var room = RoomTemplate.instantiate()
	#var current_scene = get_editor_interface().get_edited_scene_root()
#
	#if current_scene:
		#room.name = "Room_" + str(current_scene.get_child_count())
#
		## For undo/redo functionality:
		#undo_redo.create_action("Create Room")
		#undo_redo.add_do_method(current_scene, "add_child", room)
		#undo_redo.add_do_reference(room)
		#undo_redo.add_undo_method(current_scene, "remove_child", room)
		#undo_redo.commit_action(true)
		#room.owner = current_scene
	#else:
		#print("No active scene!")
	
#TURNED OFF FOR NOW TO NOT LOAD ASSETS		
#func create_hideout():
#	var hideout = HideoutTemplate.instantiate()
#	var current_scene = get_editor_interface().get_edited_scene_root()
#
#	if current_scene:
#		hideout.name = "Hideout_" + str(current_scene.get_child_count())
#
#		# For undo/redo functionality:
#		undo_redo.create_action("Create Hideout")
#		undo_redo.add_do_method(current_scene, "add_child", hideout)
#		undo_redo.add_do_reference(hideout)
#		undo_redo.add_undo_method(current_scene, "remove_child", hideout)
#		undo_redo.commit_action(true)
#		hideout.owner = current_scene
#	else:
#		print("No active scene!")

func instantiate_dungeon_wall():
	var _dungeon_wall = dungeon_wall.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()

	if current_scene:
		_dungeon_wall.name = "dungeon_wall_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Wall")
		undo_redo.add_do_method(current_scene, "add_child", _dungeon_wall)
		undo_redo.add_do_reference(_dungeon_wall)
		undo_redo.add_undo_method(current_scene, "remove_child", _dungeon_wall)
		undo_redo.commit_action(true)
		_dungeon_wall.owner = current_scene
	else:
		print("No active scene!")
		
func instantiate_dungeon_corner_in():
	var _dungeon_corner_in = dungeon_corner_in.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()

	if current_scene:
		_dungeon_corner_in.name = "dungeon_corner_in_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Wall")
		undo_redo.add_do_method(current_scene, "add_child", _dungeon_corner_in)
		undo_redo.add_do_reference(_dungeon_corner_in)
		undo_redo.add_undo_method(current_scene, "remove_child", _dungeon_corner_in)
		undo_redo.commit_action(true)
		_dungeon_corner_in.owner = current_scene
	else:
		print("No active scene!")

func instantiate_dungeon_floor():
	var _dungeon_floor = dungeon_floor.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()

	if current_scene:
		_dungeon_floor.name = "dungeon_floor_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Wall")
		undo_redo.add_do_method(current_scene, "add_child", _dungeon_floor)
		undo_redo.add_do_reference(_dungeon_floor)
		undo_redo.add_undo_method(current_scene, "remove_child", _dungeon_floor)
		undo_redo.commit_action(true)
		_dungeon_floor.owner = current_scene
	else:
		print("No active scene!")	
		
func instantiate_dungeon_corner_out():
	var _dungeon_corner_out = dungeon_corner_out.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()

	if current_scene:
		_dungeon_corner_out.name = "dungeon_corner_out_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Wall")
		undo_redo.add_do_method(current_scene, "add_child", _dungeon_corner_out)
		undo_redo.add_do_reference(_dungeon_corner_out)
		undo_redo.add_undo_method(current_scene, "remove_child", _dungeon_corner_out)
		undo_redo.commit_action(true)
		_dungeon_corner_out.owner = current_scene
	else:
		print("No active scene!")	
		
func instantiate_dungeon_gridmap():
	var dungeon_menu_inst = dungeon_menu.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()
	
	dungeon_menu_inst.connect("dungeon_generated", plugin_connection)#

	if current_scene:
		dungeon_menu_inst.name = "Dungeon Generator " + str(current_scene.get_child_count())
		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Gridmap")
		undo_redo.add_do_method(current_scene, "add_child", dungeon_menu_inst)
		undo_redo.add_do_reference(dungeon_menu_inst)
		undo_redo.add_undo_method(current_scene, "remove_child", dungeon_menu_inst)
		undo_redo.commit_action(true)
		dungeon_menu_inst.owner = current_scene
		for n in dungeon_menu_inst.get_children():
			n.owner = current_scene
	else:
		print("No active scene!")	
		
		
func instantiate_frozen_caves_gridmap():
	var dungeon_menu_inst = dungeon_menu.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()
	
	dungeon_menu_inst.connect("dungeon_generated", plugin_connection)#

	if current_scene:
		dungeon_menu_inst.name = "Dungeon Generator " + str(current_scene.get_child_count())
		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Gridmap")
		undo_redo.add_do_method(current_scene, "add_child", dungeon_menu_inst)
		undo_redo.add_do_reference(dungeon_menu_inst)
		undo_redo.add_undo_method(current_scene, "remove_child", dungeon_menu_inst)
		undo_redo.commit_action(true)
		dungeon_menu_inst.owner = current_scene
		for n in dungeon_menu_inst.get_children():
			n.owner = current_scene
	else:
		print("No active scene!")			
		
		
		
		
		
		
		

func create_first_person_controller():
	print("Inside first person controller creator")
	var third_person_controller = THIRD_PERSON_PLAYER.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()
	
	if current_scene:
		third_person_controller.name = "Player_" + str(current_scene.get_child_count())
		third_person_controller.scale = Vector3(0.6, 0.6, 0.6)
		third_person_controller.position = Vector3(4.206, 0.63, 6.766)

		undo_redo.create_action("Create First Person Player")
		undo_redo.add_do_method(current_scene, "add_child", third_person_controller)
		undo_redo.add_do_reference(third_person_controller)  # Ensure box is kept in memory
		undo_redo.add_undo_method(current_scene, "remove_child", third_person_controller)
		undo_redo.add_undo_reference(third_person_controller)  # Ensure box is kept in memory
		undo_redo.commit_action(true)
		
		third_person_controller.owner = current_scene
	else:
		print("No active scene!")	

func plugin_connection(gridmap):
	print("Plugin connected to the dungeon menu")
	stored_gridmaps.append(gridmap)
	
	print("My gridmaps: ", stored_gridmaps.size())
