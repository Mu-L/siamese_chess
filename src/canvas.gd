extends Node3D

@onready var chessboard:Chessboard = get_parent()

var pointer:Dictionary[String, Array] = {}

var grid:Array[ChessboardPointer] = []

class ChessboardPointer extends Node3D:
	var by:int = 0
	var mixed_color:Dictionary = {}
	var color:Color = Color(1, 1, 1, 1)
	var chessboard:Chessboard = null
	var material:StandardMaterial3D = StandardMaterial3D.new()
	func _ready() -> void:
		material.albedo_color = color
		material.render_priority = 1
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		global_transform = chessboard.get_node(Chess.x88_to_name(by)).global_transform
		for iter:CollisionShape3D in chessboard.get_node(Chess.x88_to_name(by)).get_children():
			var mesh_instance:MeshInstance3D = MeshInstance3D.new()
			mesh_instance.mesh = iter.shape.get_debug_mesh()
			mesh_instance.material_override = material
			add_child(mesh_instance)
			mesh_instance.transform = iter.transform

	func mix_color(type:String, _color:Color) -> void:
		mixed_color[type] = _color
		color = Color(1, 1, 1, 1)
		for iter:Color in mixed_color.values():
			color = color.blend(iter)
		material.albedo_color = color

	func remove_color(type:String) -> void:
		mixed_color.erase(type)
		color = Color(1, 1, 1, 1)
		for iter:Color in mixed_color.values():
			color = color.blend(iter)
		material.albedo_color = color

func _ready() -> void:
	for i:int in 64:
		var new_point:ChessboardPointer = ChessboardPointer.new()
		new_point.chessboard = chessboard
		new_point.by = Chess.c64_to_x88(i)
		grid.push_back(new_point)
		add_child(new_point)

func draw_pointer(type:String, color:Color, by:int) -> void:
	if !pointer.has(type):
		pointer[type] = []
	var instance:ChessboardPointer = grid[Chess.x88_to_c64(by)]
	pointer[type].push_back(instance)
	instance.mix_color(type, color)

func erase_pointer(type:String, by:int) -> void:
	var instance:ChessboardPointer = grid[Chess.x88_to_c64(by)]
	pointer[type].erase(instance)
	instance.remove_color(type)

func clear_pointer(type:String) -> void:
	if !pointer.has(type):
		return
	for iter:ChessboardPointer in pointer[type]:
		iter.remove_color(type)
	pointer.erase(type)
