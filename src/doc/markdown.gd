extends Document

var content:String = ""

func set_content(_content:String) -> void:
	content = _content
	$rich_text_label.text = content

func get_rect() -> Rect2:
	return $rich_text_label.get_rect() * $rich_text_label.transform
