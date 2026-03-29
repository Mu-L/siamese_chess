extends  Notable

var image:Image = Image.new()

func parse(data:Dictionary) -> void:
	super.parse(data)
	image.load_png_from_buffer(Marshalls.base64_to_raw(data["data"]))
	$sprite_2d.texture = ImageTexture.create_from_image(image)

func dict() -> Dictionary:
	var data:Dictionary = super.dict()
	data["data"] = Marshalls.raw_to_base64(image.save_png_to_buffer())
	return data

func get_rect() -> Rect2:
	return $sprite_2d.get_rect() * $sprite_2d.transform
