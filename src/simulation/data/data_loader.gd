class_name DataLoader
extends RefCounted

# data/ altındaki JSON içerik dosyalarını okur ve şemasına göre doğrular.
# Kural: data/<ad>.json dosyasının şeması data/schemas/<ad>.schema.json dosyasıdır.

const DATA_DIR: String = "res://data/"
const SCHEMA_DIR: String = "res://data/schemas/"
const DATA_EXTENSION: String = ".json"
const SCHEMA_EXTENSION: String = ".schema.json"


# Ada göre içerik dosyasını yükler, ör. load_data("game_config").
static func load_data(data_name: String) -> DataLoadResult:
	return load_validated(
		DATA_DIR + data_name + DATA_EXTENSION,
		SCHEMA_DIR + data_name + SCHEMA_EXTENSION
	)


static func load_validated(data_path: String, schema_path: String) -> DataLoadResult:
	var schema_result: DataLoadResult = load_json(schema_path)
	if not schema_result.is_ok():
		return schema_result
	if typeof(schema_result.data) != TYPE_DICTIONARY:
		schema_result.errors.append("%s: şema bir JSON nesnesi olmalı" % schema_path)
		return schema_result

	var data_result: DataLoadResult = load_json(data_path)
	if not data_result.is_ok():
		return data_result

	var schema: Dictionary = schema_result.data
	var validated: DataLoadResult = SchemaValidator.validate(data_result.data, schema)
	for i: int in range(validated.errors.size()):
		validated.errors[i] = "%s: %s" % [data_path, validated.errors[i]]
	return validated


static func load_json(path: String) -> DataLoadResult:
	var result: DataLoadResult = DataLoadResult.new()
	if not FileAccess.file_exists(path):
		result.errors.append("%s: dosya bulunamadı" % path)
		return result

	var text: String = FileAccess.get_file_as_string(path)
	var open_error: Error = FileAccess.get_open_error()
	if open_error != OK:
		result.errors.append("%s: dosya okunamadı (%s)" % [path, error_string(open_error)])
		return result

	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(text)
	if parse_error != OK:
		# Godot satırları 0'dan sayar; editörlerle eşleşmesi için 1'den başlat.
		result.errors.append("%s:%d: JSON sözdizimi hatası: %s" % [
			path, json.get_error_line() + 1, json.get_error_message()
		])
		return result
	result.data = json.data
	return result
