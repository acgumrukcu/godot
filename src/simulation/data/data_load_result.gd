class_name DataLoadResult
extends RefCounted

# Veri yükleme/doğrulama sonucu. GDScript'te istisna olmadığı için hatalar burada toplanır.

var data: Variant = null
var errors: Array[String] = []


func is_ok() -> bool:
	return errors.is_empty()


func error_text() -> String:
	return "\n".join(PackedStringArray(errors))
