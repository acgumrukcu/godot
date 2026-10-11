class_name SchemaValidator
extends RefCounted

# JSON verisini basit bir şemaya göre doğrular ve tipleri dönüştürür.
# Godot JSON'daki tüm sayıları float okur; "int" tipli alanlar burada gerçek int'e çevrilir
# (para kuruş olarak int tutulduğu için önemli). Ayrıntı: docs/kararlar/002-veri-semalari.md
#
# Desteklenen şema anahtarları:
#   type: "object" | "array" | "string" | "int" | "number" | "bool"
#   description: belge amaçlı, doğrulamada kullanılmaz
#   enum (tüm tipler)
#   properties, required, additional_properties (object)
#   items, min_items (array)
#   min_length (string)
#   minimum, maximum (int, number)
#
# additional_properties: true ile kabul edilen ek alanlar doğrulanmaz ve dönüştürülmez
# (sayılar float kalır).

const TYPE_NAME_OBJECT: String = "object"
const TYPE_NAME_ARRAY: String = "array"
const TYPE_NAME_STRING: String = "string"
const TYPE_NAME_INT: String = "int"
const TYPE_NAME_NUMBER: String = "number"
const TYPE_NAME_BOOL: String = "bool"

const TYPE_NAMES: Array[String] = [
	TYPE_NAME_OBJECT, TYPE_NAME_ARRAY, TYPE_NAME_STRING,
	TYPE_NAME_INT, TYPE_NAME_NUMBER, TYPE_NAME_BOOL,
]

# Anahtar → kullanılabildiği tipler. Boş liste: tüm tiplerde geçerli.
const KEYWORD_TYPES: Dictionary = {
	"type": [],
	"description": [],
	"enum": [],
	"properties": [TYPE_NAME_OBJECT],
	"required": [TYPE_NAME_OBJECT],
	"additional_properties": [TYPE_NAME_OBJECT],
	"items": [TYPE_NAME_ARRAY],
	"min_items": [TYPE_NAME_ARRAY],
	"min_length": [TYPE_NAME_STRING],
	"minimum": [TYPE_NAME_INT, TYPE_NAME_NUMBER],
	"maximum": [TYPE_NAME_INT, TYPE_NAME_NUMBER],
}

# float'a kayıpsız sığan en büyük tam sayı (2^53 - 1).
const MAX_SAFE_INT: float = 9007199254740991.0
const MAX_VALUE_PREVIEW_LENGTH: int = 40
const SCHEMA_ROOT_PATH: String = "şema"
const DATA_ROOT_PATH: String = "$"


# Önce şemayı, geçerliyse veriyi doğrular. Hata varsa result.data null'dır.
static func validate(value: Variant, schema: Variant) -> DataLoadResult:
	var result: DataLoadResult = DataLoadResult.new()
	result.errors = validate_schema(schema)
	if not result.is_ok():
		return result
	var schema_dict: Dictionary = schema
	var checked: Variant = _check(schema_dict, value, DATA_ROOT_PATH, result.errors)
	if result.is_ok():
		result.data = checked
	return result


# Şemanın kendisini veriden bağımsız ve eksiksiz doğrular (isteğe bağlı alanlar ve
# items dahil), böylece şema yazım hataları veri ne olursa olsun yakalanır.
static func validate_schema(schema: Variant) -> Array[String]:
	var errors: Array[String] = []
	_check_schema(schema, SCHEMA_ROOT_PATH, errors)
	return errors


static func _check_schema(schema: Variant, path: String, errors: Array[String]) -> void:
	if typeof(schema) != TYPE_DICTIONARY:
		errors.append("%s: şema bir nesne olmalı, bulunan %s" % [path, _preview(schema)])
		return
	var node: Dictionary = schema

	var type_value: Variant = node.get("type")
	if typeof(type_value) != TYPE_STRING or not TYPE_NAMES.has(type_value):
		errors.append("%s: 'type' şunlardan biri olmalı: %s, bulunan %s" % [
			path, ", ".join(PackedStringArray(TYPE_NAMES)), _preview(type_value)
		])
		return
	var type_name: String = type_value

	for key: Variant in node:
		if not KEYWORD_TYPES.has(key):
			errors.append("%s: bilinmeyen anahtar '%s'" % [path, str(key)])
			continue
		var allowed_types: Array = KEYWORD_TYPES[key]
		if not allowed_types.is_empty() and not allowed_types.has(type_name):
			errors.append("%s: '%s' anahtarı '%s' tipinde kullanılamaz" % [path, str(key), type_name])

	if node.has("description") and typeof(node["description"]) != TYPE_STRING:
		errors.append("%s.description: metin olmalı" % path)
	if node.has("enum"):
		_check_schema_enum(node["enum"], type_name, path, errors)
	if node.has("properties"):
		_check_schema_properties(node["properties"], path, errors)
	if node.has("required"):
		_check_schema_required(node["required"], node.get("properties", {}), path, errors)
	if node.has("additional_properties") and typeof(node["additional_properties"]) != TYPE_BOOL:
		errors.append("%s.additional_properties: true/false olmalı" % path)
	if node.has("items"):
		_check_schema(node["items"], path + ".items", errors)
	for key: String in ["min_items", "min_length"]:
		if node.has(key) and not (_is_whole_number(node[key]) and float(node[key]) >= 0.0):
			errors.append("%s.%s: negatif olmayan tam sayı olmalı" % [path, key])
	for key: String in ["minimum", "maximum"]:
		if node.has(key) and not _is_number(node[key]):
			errors.append("%s.%s: sayı olmalı" % [path, key])


static func _check_schema_enum(enum_value: Variant, type_name: String, path: String, errors: Array[String]) -> void:
	if typeof(enum_value) != TYPE_ARRAY or (enum_value as Array).is_empty():
		errors.append("%s.enum: boş olmayan bir dizi olmalı" % path)
		return
	var item_errors: Array[String] = []
	_coerce_enum(enum_value, type_name, path + ".enum", item_errors)
	errors.append_array(item_errors)


static func _check_schema_properties(properties_value: Variant, path: String, errors: Array[String]) -> void:
	if typeof(properties_value) != TYPE_DICTIONARY:
		errors.append("%s.properties: nesne olmalı" % path)
		return
	var properties: Dictionary = properties_value
	for key: Variant in properties:
		_check_schema(properties[key], "%s.properties.%s" % [path, str(key)], errors)


static func _check_schema_required(required_value: Variant, properties_value: Variant, path: String, errors: Array[String]) -> void:
	if typeof(required_value) != TYPE_ARRAY:
		errors.append("%s.required: dizi olmalı" % path)
		return
	var has_properties: bool = typeof(properties_value) == TYPE_DICTIONARY
	for key: Variant in required_value as Array:
		if typeof(key) != TYPE_STRING:
			errors.append("%s.required: öğeler metin olmalı, bulunan %s" % [path, _preview(key)])
		elif not has_properties or not (properties_value as Dictionary).has(key):
			errors.append("%s.required: '%s' properties içinde tanımlı değil" % [path, key])


# Enum değerlerini şemadaki tipe çevirir (ör. JSON'dan gelen 2.0 → 2), böylece
# dönüştürülmüş veriyle karşılaştırılabilir.
static func _coerce_enum(enum_value: Array, type_name: String, path: String, errors: Array[String]) -> Array:
	var coerced: Array = []
	for i: int in range(enum_value.size()):
		coerced.append(_check({"type": type_name}, enum_value[i], "%s[%d]" % [path, i], errors))
	return coerced


# Şemanın validate_schema'dan geçtiğini varsayar.
# Geçersiz değerde null döner ve errors'a ekler. JSON null hiçbir tipte geçerli değildir.
static func _check(schema: Dictionary, value: Variant, path: String, errors: Array[String]) -> Variant:
	var type_name: String = schema["type"]
	var result: Variant = null
	match type_name:
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

	if result == null:
		return null
	if schema.has("enum"):
		var allowed: Array = _coerce_enum(schema["enum"], type_name, path, [])
		if not allowed.has(result):
			errors.append("%s: değer %s izin verilenler arasında değil: %s" % [
				path, _preview(result), _preview(allowed)
			])
	if type_name == TYPE_NAME_INT or type_name == TYPE_NAME_NUMBER:
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
		if not source.has(key):
			errors.append("%s: zorunlu alan eksik: '%s'" % [path, str(key)])

	var output: Dictionary = {}
	for key: Variant in source:
		var child_path: String = "%s.%s" % [path, str(key)]
		if properties.has(key):
			var child_schema: Dictionary = properties[key]
			output[key] = _check(child_schema, source[key], child_path, errors)
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
		output.append(_check(item_schema, source[i], "%s[%d]" % [path, i], errors))
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
	if _is_whole_number(value):
		return int(value)
	errors.append(_type_error(path, "tam sayı", value))
	return null


static func _check_number(value: Variant, path: String, errors: Array[String]) -> Variant:
	if _is_number(value):
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
		errors.append("%s: değer %s, en az %s olmalı" % [path, _preview(value), _preview(schema["minimum"])])
	if schema.has("maximum") and number > float(schema["maximum"]):
		errors.append("%s: değer %s, en fazla %s olmalı" % [path, _preview(value), _preview(schema["maximum"])])


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


# int ya da kayıpsız int'e çevrilebilen float (JSON'dan gelen 4500.0 gibi).
static func _is_whole_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT:
		return false
	var number: float = value
	return is_finite(number) and number == floorf(number) and absf(number) <= MAX_SAFE_INT


static func _type_error(path: String, expected: String, value: Variant) -> String:
	return "%s: beklenen %s, bulunan %s" % [path, expected, _preview(value)]


static func _preview(value: Variant) -> String:
	return JSON.stringify(value).left(MAX_VALUE_PREVIEW_LENGTH)
