extends Control

enum Mode { MODE_3D, MODE_2D }
var mode: Mode = Mode.MODE_3D

var toggle2d_state := false

@onready var view3d: SubViewportContainer = $View3D
@onready var view2d: SubViewportContainer = $View2D

@onready var vp3d: SubViewport = $View3D/VP3D
@onready var vp2d: SubViewport = $View2D/VP2D

@onready var world3d: Node = $"View3D/VP3D/3Dview"
@onready var world2d: Node = $"View2D/VP2D/2Dview"

@onready var player3d = $"View3D/VP3D/3Dview/Character"
@onready var player2d = $"View2D/VP2D/2Dview/Character"

@onready var mode_label: Label = $CanvasLayer/State

@onready var otherbox_mesh: MeshInstance3D = $"View3D/VP3D/3Dview/otherbox/MeshInstance3D"


func _ready():
	_sync_viewport_sizes()
	get_viewport().size_changed.connect(_sync_viewport_sizes)
	# Render continuously
	vp3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp2d.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	_force_current_cameras()
	apply_2d_view_to_3d_screen()
	_update_otherbox_color()

	set_mode(Mode.MODE_3D)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if event.is_action_pressed("toggle"):
		set_mode(Mode.MODE_2D if mode == Mode.MODE_3D else Mode.MODE_3D)
		return

	if mode == Mode.MODE_2D and event.is_action_pressed("interact"):
		try_interact_2d()

# pass input to subviewport
func _input(event):
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		if mode == Mode.MODE_3D:
			vp3d.push_input(event, true)
		else:
			vp2d.push_input(event, true)

func set_mode(new_mode: Mode) -> void:
	mode = new_mode

	if mode == Mode.MODE_3D:
		player3d.set_active(true)
		player2d.set_active(false)

		view3d.visible = true
		view2d.visible = false
		mode_label.text = "Mode: 3D (Tab swap, ESC free mouse)"
	else:
		player3d.set_active(false)
		player2d.set_active(true)

		view3d.visible = false
		view2d.visible = true
		mode_label.text = "Mode: 2D (Tab swap, ESC free mouse)"

func _force_current_cameras() -> void:
	var cam3d: Camera3D = $"View3D/VP3D/3Dview/Character/Camera3D"
	if cam3d:
		cam3d.current = true

	var cam2d: Camera2D = $"View2D/VP2D/2Dview/Character/Camera2D"
	if cam2d:
		cam2d.enabled = true
		cam2d.make_current()

func apply_2d_view_to_3d_screen():
	# Mesh in 3D world named "2Dviewport"
	var screen: MeshInstance3D = $"View3D/VP3D/3Dview/2Dviewport"
	if screen == null:
		push_warning("No 3D screen mesh found at View3D/VP3D/3Dview/2Dviewport")
		return

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = vp2d.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen.material_override = mat

func try_interact_2d():
	
	var npc_area: Area2D = $"View2D/VP2D/2Dview/Interactive"
	if npc_area == null:
		push_warning("No 2D Area2D found at View2D/VP2D/2Dview/Interactive")
		return

	var player: CharacterBody2D = player2d
	if player.global_position.distance_to(npc_area.global_position) >= 40:
		return

	var layer: TileMapLayer = $"View2D/VP2D/2Dview/TileMapLayer" 
	if layer == null:
		push_warning("No TileMapLayer found at View2D/VP2D/2Dview/Ground")
		return

	# Tile coordinate under the player
	# needed some help here to figure out the correct tile to use
	var cell: Vector2i = layer.local_to_map(layer.to_local(npc_area.global_position))
	# Read current tile
	var cur_source := layer.get_cell_source_id(cell)
	var cur_atlas  := layer.get_cell_atlas_coords(cell)
	var cur_alt    := layer.get_cell_alternative_tile(cell)
	

	# swap between signage and gravestone
	var A := Vector2i(15, 3)
	var B := Vector2i(16, 3)

	# fallback
	if cur_source == -1:
		cur_source = 0
		cur_atlas = A
		cur_alt = 0

	var new_atlas := B if cur_atlas == A else A
	const SRC := 0
	layer.set_cell(cell, SRC, new_atlas, 0)

	# sancheck
	var script_node := npc_area.get_node_or_null("interactivescript")
	if script_node and script_node.has_method("interact"):
		script_node.interact()

func _sync_viewport_sizes() -> void:
	var s := get_viewport().get_visible_rect().size
	vp3d.size = Vector2i(int(s.x), int(s.y))
	vp2d.size = Vector2i(int(s.x), int(s.y))

# To store the toggle state in the 2d world
func set_toggle2d_state(v: bool) -> void:
	toggle2d_state = v
	_update_otherbox_color()

# To change the colour in the 3d world
func _update_otherbox_color() -> void:
	if otherbox_mesh == null:
		push_warning("Otherbox mesh not found. Check path/name.")
		return

	if otherbox_mesh.material_override == null:
		otherbox_mesh.material_override = StandardMaterial3D.new()

	var mat := otherbox_mesh.material_override as StandardMaterial3D
	mat.albedo_color = Color(1, 1, 1) if toggle2d_state else Color(0, 0, 0)
	
# to flip the tile in the 2d world
# some consts to make it easier
const SRC := 0
const TILE_A := Vector2i(15, 3) # signage
const TILE_B := Vector2i(16, 3) # gravestone
const TARGET_CELL := Vector2i(4, -1)

func flip_2d_tile_at_target():
	var layer: TileMapLayer = $"View2D/VP2D/2Dview/TileMapLayer"
	if layer == null:
		push_warning("TileMapLayer not found at View2D/VP2D/2Dview/TileMapLayer")
		return

	var atl := layer.get_cell_atlas_coords(TARGET_CELL)
	var new_atl := TILE_B if atl == TILE_A else TILE_A
	layer.set_cell(TARGET_CELL, SRC, new_atl, 0)
	
func flip_2d_tile_under_2d_player():
	flip_2d_tile_at_target()
