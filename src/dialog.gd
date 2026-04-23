extends CanvasLayer

signal on_next()

const packed_scene:PackedScene = preload("res://scene/dialog.tscn")

var border_position:bool = true
var text_label:RichTextLabel = null
var title_label:RichTextLabel = null
var time_label:RichTextLabel = null
var other_label:RichTextLabel = null

var text:String = ""
var title:String = ""
var selection:PackedStringArray = []
var selected:String = ""
var select_focus:int = -1
var waiting:bool = false
var click_anywhere:bool = false
var force_selection:bool = false
var click_cooldown:float = 0
var tween:Tween = null

func _ready() -> void:
	set_border_position(false)
	$texture_rect_bottom/label.connect("meta_clicked", clicked_selection)
	$texture_rect_right/label.connect("meta_clicked", clicked_selection)
	Setting.connect("language_changed", update_dialog)
	Setting.connect("dialog_border_changed", update_dialog)

func _unhandled_input(event:InputEvent) -> void:
	if click_anywhere && !waiting:
		if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed && Time.get_unix_time_from_system() - click_cooldown >= 0.3:
			next()
			click_cooldown = Time.get_unix_time_from_system()
	if block_input():
		get_viewport().set_input_as_handled()

func push_dialog(_text:String, _title:String, blackscreen:bool = false, _click_anywhere:bool = false, _waiting:bool = false) -> void:
	text = _text
	title = _title
	if tween && tween.is_running():
		tween.kill()
	if text_label.text != "" || title_label.text != "":
		clear()
	tween = create_tween()
	force_selection = false	
	waiting = _waiting
	click_anywhere = _click_anywhere
	text_label.text = ""
	if blackscreen:
		tween.tween_property($texture_rect_full, "visible", true, 0)
	tween.tween_interval(0.3)
	tween.tween_property(text_label, "text", tr(text), 0)
	tween.tween_property(title_label, "text", tr(title), 0)
	tween.tween_property($texture_rect_full, "visible", false, 0)

func push_selection(_selection:PackedStringArray, _title:String, _force_selection:bool = true, blackscreen:bool = false) -> void:
	click_anywhere = false
	force_selection = _force_selection
	selection = _selection
	text = selection_to_bbcode()
	title = _title
	if tween && tween.is_running():
		tween.kill()
	if text_label.text != "" || title_label.text != "":
		clear()
	tween = create_tween()
	if blackscreen:
		tween.tween_property($texture_rect_full, "visible", true, 0)
	tween.tween_interval(0.3)
	tween.tween_property(text_label, "text", text, 0)
	tween.tween_property(title_label, "text", tr(title), 0)
	tween.tween_property($texture_rect_full, "visible", false, 0)

func set_hint_left(_text:String) -> void:
	time_label.text = _text

func set_hint_right(_text:String) -> void:
	other_label.text = _text

func clear() -> void:
	if tween && tween.is_running():
		tween.kill()
	text_label.text = ""
	title_label.text = ""
	click_anywhere = false
	force_selection = false
	waiting = false
	selection.clear()
	select_focus = -1

func next() -> void:
	text_label.text = ""
	title_label.text = ""
	click_anywhere = false
	force_selection = false
	waiting = false
	selection.clear()
	select_focus = -1
	on_next.emit()

func direction(axis:int) -> void:
	if !selection.size():
		return
	if select_focus == -1:
		select_focus = 0 if axis == 1 else selection.size() - 1
	else:
		select_focus += axis
		select_focus = (select_focus + selection.size()) % selection.size()
	selected = selection[select_focus]
	text_label.text = selection_to_bbcode()

func cancel_focus() -> void:
	select_focus = -1
	text_label.text = selection_to_bbcode()

func clicked_selection(_selected:String) -> void:
	selected = _selected
	next()

func selection_to_bbcode() -> String:
	var bbcode:String = ""
	for i:int in selection.size():
		if i == select_focus:
			bbcode += "[url=\"" + selection[i] + "\"][color=red]" + tr(selection[i]) + "[/color][/url]"
		else:
			bbcode += "[url=\"" + selection[i] + "\"]" + tr(selection[i]) + "[/url]"
		if i == selection.size() - 1:
			break
		if !border_position:
			bbcode += "  "
		else:
			bbcode += "\n\n"
	return bbcode

func block_input() -> bool:
	return click_anywhere || force_selection || Time.get_unix_time_from_system() - click_cooldown < 0.3

func update_dialog() -> void:
	set_border_position(Setting.get_value("dialog_border"))
	if selection:
		text = selection_to_bbcode()
		text_label.text = text
	else:
		text_label.text = tr(text)
	title_label.text = tr(title)

func set_border_position(_border_position:bool) -> void:
	border_position = _border_position
	if !border_position:
		$texture_rect_left.visible = false
		$texture_rect_right.visible = false
		$texture_rect_top.visible = true
		$texture_rect_bottom.visible = true
		text_label = $texture_rect_bottom/label
		title_label = $texture_rect_top/label
		time_label = $texture_rect_top/label_hint_left
		other_label = $texture_rect_top/label_hint_right
	else:
		$texture_rect_left.visible = true
		$texture_rect_right.visible = true
		$texture_rect_top.visible = false
		$texture_rect_bottom.visible = false
		text_label = $texture_rect_right/label
		title_label = $texture_rect_left/label
		time_label = $texture_rect_left/label_hint_up
		other_label = $texture_rect_left/label_hint_down
