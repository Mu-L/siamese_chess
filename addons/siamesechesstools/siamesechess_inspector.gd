extends EditorInspectorPlugin

var bitboard_inspector = preload("res://addons/siamesechesstools/bitboard_inspector.gd")


func _can_handle(object):
	# We support all objects in this example.
	return true

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	# We handle properties of type integer.
	if type == TYPE_INT && name == "bit":
		# Create an instance of the custom property editor and register
		# it to a specific property path.
		add_property_editor(name, bitboard_inspector.new())
		# Inform the editor to remove the default property editor for
		# this property type.
		return true
	else:
		return false
