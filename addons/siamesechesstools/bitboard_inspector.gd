extends EditorProperty

var container:GridContainer = GridContainer.new()
var button_list:Array[CheckBox]
var current_bit:int = 0
var updating:bool = false

func _init() -> void:
	container.columns = 8
	add_child(container)
	for i:int in 64:
		var button:CheckBox = CheckBox.new()
		button.toggle_mode = true
		button.flat = true
		button.grow_horizontal = Control.GROW_DIRECTION_BOTH
		button.grow_vertical = Control.GROW_DIRECTION_BOTH
		button.connect("toggled", _on_button_toggled.bind(i))
		button_list.push_back(button)
		container.add_child(button)

func _on_button_toggled(toggled:bool, by_64:int) -> void:
	if updating:
		return
	if toggled:
		current_bit |= (1 << by_64)
	else:
		current_bit &= ~(1 << by_64)
	emit_changed(get_edited_property(), current_bit)

func _update_property() -> void:
	var new_value:int = get_edited_object()[get_edited_property()]
	if new_value == current_bit:
		return
	updating = true
	current_bit = new_value
	refresh()
	updating = false

func refresh() -> void:
	for i:int in 64:
		if current_bit & (1 << i):
			button_list[i].set_pressed_no_signal(true)
		else:
			button_list[i].set_pressed_no_signal(false)
