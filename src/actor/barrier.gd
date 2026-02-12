extends Actor
class_name Barrier

func _ready() -> void:
	var model_count:int = 0
	for iter:Node in get_children():
		if iter is Node3D && iter.name.is_valid_int():
			iter.visible = false
			model_count += 1
	if model_count == 0:
		return
	var index:int = randi() % model_count
	var node_path:String = "%d" % index
	get_node(node_path).visible = true
