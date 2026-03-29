extends Document
# 插画作品，只保存路径，而非其图像数据
var path:String = ""

func parse(data:Dictionary) -> void:
	super.parse(data)
	path = data["path"]
	$sprite.texture = load(path)

func dict() -> Dictionary:
	var data:Dictionary = super.dict()
	data["path"] = path
	return data
