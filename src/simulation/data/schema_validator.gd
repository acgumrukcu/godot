class_name SchemaValidator
extends RefCounted

# JSON verisini basit bir şemaya göre doğrular ve tipleri dönüştürür.
# Godot JSON'daki tüm sayıları float okur; "int" tipli alanlar burada gerçek int'e çevrilir
# (para kuruş olarak int tutulduğu için önemli).
#
# Desteklenen şema anahtarları:
#   type: "object" | "array" | "string" | "int" | "number" | "bool"
#   description: belge amaçlı, doğrulamada kullanılmaz
#   properties, required, additional_properties (object)
#   items, min_items (array)
#   min_length (string)
#   minimum, maximum (int, number)
#   enum (tüm tipler)

const TYPE_NAME_OBJECT: String = "object"
const TYPE_NAME_ARRAY: String = "array"
const TYPE_NAME_STRING: String = "string"
const TYPE_NAME_INT: String = "int"
const TYPE_NAME_NUMBER: String = "number"
const TYPE_NAME_BOOL: String = "bool"

const KNOWN_KEYWORDS: Array[String] = [
	"type", "description", "properties", "required", "additional_properties",
	"items", "min_items", "min_length", "minimum", "maximum", "enum",
]

# float'a kayıpsız sığan en büyük tam sayı (2^53 - 1).
const MAX_SAFE_INT: float = 9007199254740991.0
const MAX_VALUE_PREVIEW_LENGTH: int = 40


static func validate(value: Variant, schema: Dictionary) -> DataLoadResult:
	var result: DataLoadResult = DataLoadResult.new()
	result.data = _check(value, schema, "$", result.errors)
	return result


# Geçersiz değerde null döner ve errors'a ekler. JSON null hiçbir tipte geçerli değildir.
static func _check(value: Variant, schema: Dictionary, path: String, errors: Array[String]) -> Variant:
	for key: Variant in schema:
		if not KNOWN_KEYWORDS.has(key):
			errors.append("%s: şemada bilinmeyen anahtar '%s'" % [path, str(key)])

	var type_value: Variant = schema.get("type")
	if typeof(type_value) != TYPE_STRING:
		errors.append("%s: şemada 'type' eksik veya metin değil" % path)
		return null

	var result: Variant = null
	match type_value as String:
		TYPE_NAME_OBJECT:
			result = _check_object(value, schema, path, errors)
		TYPE_NAME_ARRAY:
			result = _check_array(value, schema, path, errors)
		TYPE_NAME_STRING:
			result = _check_string(value, schema, path, errors)
		TYPE_NAME_INT:
			result = _check_int(value, path, errors)
		TYPE_NAME_NUMBER:
			result = _check_number(value, path, errors)
		TYPE_NAME_BOOL:
			result = _check_bool(value, path, errors)
		_:
			errors.append("%s: şemada bilinmeyen tip '%s'" % [path, type_value])
			return null

	if result == null:
		return null
	if schema.has("enum"):
		var allowed: Array = schema["enum"]
		if not allowed.has(result):
			errors.append("%s: değer %s izin verilenler arasında değil: %s" % [path, _preview(result), str(allowed)])
	if type_value == TYPE_NAME_INT or type_value == TYPE_NAME_NUMBER:
		_check_range(result, schema, path, errors)
	return result


static func _check_object(value: Variant, schema: Dictionary, path: String, errors: Array[String]) -> Variant:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append(_type_error(path, "nesne", value))
		return null
	var source: Dictionary = value
	var properties: Dictionary = schema.get("properties", {})
	var required: Array = schema.get("required", [])
	var allow_extra: bool = schema.get("additional_properties", false)

	for key: Variant in required:
		if not properties.has(key):
			errors.append("%s: şemada zorunlu alan '%s' properties içinde tanımlı değil" % [path, str(key)])
		if not source.has(key):
			errors.append("%s: zorunlu alan eksik: '%s'" % [path, str(key)])

	var output: Dictionary = {}
	for key: Variant in source:
		var child_path: String = "%s.%s" % [path, str(key)]
		if properties.has(key):
			var child_schema: Dictionary = properties[key]
			output[key] = _check(source[key], child_schema, child_path, errors)
		elif allow_extra:
			output[key] = source[key]
		else:
			errors.append("%s: beklenmeyen alan (yazım hatası olabilir)" % child_path)
	return output


static func _check_array(value: Variant, schema: Dictionary, path: String, errors: Array[String]) -> Variant:
	if typeof(value) != TYPE_ARRAY:
		errors.append(_type_error(path, "dizi", value))
		return null
	var source: Array = value
	if schema.has("min_items"):
		var min_items: int = int(schema["min_items"])
		if source.size() < min_items:
			errors.append("%s: en az %d öğe olmalı, %d var" % [path, min_items, source.size()])

	var output: Array = []
	if not schema.has("items"):
		output.assign(source)
		return output
	var item_schema: Dictionary = schema["items"]
	for i: int in range(source.size()):
		output.append(_check(source[i], item_schema, "%s[%d]" % [path, i], errors))
	return output


static func _check_string(value: Variant, schema: Dictionary, path: String, errors: Array[String]) -> Variant:
	if typeof(value) != TYPE_STRING:
		errors.append(_type_error(path, "metin", value))
		return null
	var text: String = value
	if schema.has("min_length"):
		var min_length: int = int(schema["min_length"])
		if text.length() < min_length:
			errors.append("%s: en az %d karakter olmalı" % [path, min_length])
	return text


static func _check_int(value: Variant, path: String, errors: Array[String]) -> Variant:
	if typeof(value) == TYPE_INT:
		return value
	if typeof(value) == TYPE_FLOAT:
		var number: float = value
		if is_finite(number) and number == floorf(number) and absf(number) <= MAX_SAFE_INT:
			return int(number)
	errors.append(_type_error(path, "tam sayı", value))
	return null


static func _check_number(value: Variant, path: String, errors: Array[String]) -> Variant:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return value
	errors.append(_type_error(path, "sayı", value))
	return null


static func _check_bool(value: Variant, path: String, errors: Array[String]) -> Variant:
	if typeof(value) == TYPE_BOOL:
		return value
	errors.append(_type_error(path, "true/false", value))
	return null


static func _check_range(value: Variant, schema: Dictionary, path: String, errors: Array[String]) -> void:
	var number: float = float(value)
	if schema.has("minimum") and number < float(schema["minimum"]):
		errors.append("%s: değer %s, en az %s olmalı" % [path, _preview(value), str(schema["minimum"])])
	if schema.has("maximum") and number > float(schema["maximum"]):
		errors.append("%s: değer %s, en fazla %s olmalı" % [path, _preview(value), str(schema["maximum"])])


static func _type_error(path: String, expected: String, value: Variant) -> String:
	return "%s: beklenen %s, bulunan %s" % [path, expected, _preview(value)]


static func _preview(value: Variant) -> String:
	return JSON.stringify(value).left(MAX_VALUE_PREVIEW_LENGTH)
