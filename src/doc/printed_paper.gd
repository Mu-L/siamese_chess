extends Notable

@export var img_path:String = ""

func _ready() -> void:
	if ResourceLoader.exists(img_path):
		$sprite_2d.texture = load(img_path)
	else:
		var image:Image = Image.load_from_file(img_path)
		$sprite_2d.texture = ImageTexture.create_from_image(image)

func parse(data:Dictionary) -> void:
	super.parse(data)
	img_path = data["path"]
	if ResourceLoader.exists(img_path):
		$sprite_2d.texture = load(img_path)
	else:
		var image:Image = Image.load_from_file(img_path)
		$sprite_2d.texture = ImageTexture.create_from_image(image)

func dict() -> Dictionary:
	var data:Dictionary = super.dict()
	data["path"] = img_path
	return data

func get_rect() -> Rect2:
	return $sprite_2d.get_rect() * $sprite_2d.transform

func page_index() -> int:
	return 0

func page_size() -> int:
	return 1
