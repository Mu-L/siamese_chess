extends Document

var content:String = ""

func get_rect() -> Rect2:
	return $rich_text_label.get_rect() * $rich_text_label.transform
