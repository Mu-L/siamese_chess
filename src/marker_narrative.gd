extends MarkerEvent
class_name MarkerNarrative

@export var condition:String = ""
@export var text:String = ""

func on_start() -> void:
	if condition:
		var expression:Expression = Expression.new()
		var error:int = expression.parse(condition, ["level", "setting", "progress"])
		if error != OK:
			print(expression.get_error_text())
			return
		var result:Variant = expression.execute([level, Setting, Progress])
		if expression.has_execute_failed():
			return
		if !result:
			return
	var voices:PackedStringArray = DisplayServer.tts_get_voices_for_language(TranslationServer.get_locale())
	if voices.size() == 0:
		return
	var voice:String = voices[0]
	DisplayServer.tts_speak(tr(text), voice)
