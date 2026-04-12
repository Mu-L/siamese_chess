extends Node3D

@onready var chessboard:Chessboard = get_parent()

var pointer:Dictionary[String, Array] = {}

class ChessboardPointer extends Node3D:
	var by:int = 0
	var color:Color = Color(0, 0, 0, 1)
	var priority:int = 0
	var chessboard:Chessboard = null
	func _ready() -> void:
		var material:StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = color
		material.render_priority = priority
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		global_transform = chessboard.get_node(Chess.x88_to_name(by)).global_transform
		for iter:CollisionShape3D in chessboard.get_node(Chess.x88_to_name(by)).get_children():
			var mesh_instance:MeshInstance3D = MeshInstance3D.new()
			mesh_instance.mesh = iter.shape.get_debug_mesh()
			mesh_instance.material_override = material
			add_child(mesh_instance)
			mesh_instance.transform = iter.transform

func draw_pointer(type:String, color:Color, by:int, priority:int = 0) -> void:
	if !pointer.has(type):
		pointer[type] = []
	var new_point:ChessboardPointer = ChessboardPointer.new()
	new_point.chessboard = chessboard
	new_point.color = color
	new_point.by = by
	new_point.priority = priority
	add_child(new_point)
	pointer[type].push_back(new_point)

func clear_pointer(type:String) -> void:
	if !pointer.has(type):
		return
	for iter:Node3D in pointer[type]:
		iter.queue_free()
	pointer.erase(type)
