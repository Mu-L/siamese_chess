extends Notable

@export var img_path:String = ""

func _ready() -> void:
	if ResourceLoader.exists(img_path):
		$sprite_2d.texture = load(img_path)
	else:
		var image:Image = Image.load_from_file(img_path)
		$sprite_2d.texture = ImageTexture.create_from_image(image)

func parse(data:String) -> void:
	super.parse(data)
	var data_dict:Dictionary = JSON.parse_string(data)
	img_path = data_dict["path"]
	if ResourceLoader.exists(img_path):
		$sprite_2d.texture = load(img_path)
	else:
		var image:Image = Image.load_from_file(img_path)
		$sprite_2d.texture = ImageTexture.create_from_image(image)

func stringify() -> String:
	var data_dict:Dictionary = JSON.parse_string(super.stringify())
	data_dict["path"] = img_path
	return JSON.stringify(data_dict)

func get_rect() -> Rect2:
	return $sprite_2d.get_rect() * $sprite_2d.transform
