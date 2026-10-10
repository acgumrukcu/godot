extends GutTest

var product_schema: Dictionary = {
	"type": "object",
	"required": ["name", "price_kurus"],
	"properties": {
		"name": {"type": "string", "min_length": 1},
		"price_kurus": {"type": "int", "minimum": 0, "maximum": 100000},
		"size": {"type": "string", "enum": ["small", "large"]},
		"tags": {"type": "array", "min_items": 1, "items": {"type": "string"}},
		"is_hot": {"type": "bool"},
		"rating": {"type": "number"},
	},
}


func _error_text_contains(result: DataLoadResult, fragment: String) -> bool:
	return result.error_text().contains(fragment)


func test_valid_object_passes() -> void:
	var value: Dictionary = {"name": "çay", "price_kurus": 2500.0, "tags": ["sıcak"], "is_hot": true}
	var result: DataLoadResult = SchemaValidator.validate(value, product_schema)
	assert_true(result.is_ok(), result.error_text())


func test_int_fields_are_converted_from_json_float() -> void:
	# JSON.parse tüm sayıları float verir; para alanı int'e dönmeli.
	var value: Dictionary = {"name": "çay", "price_kurus": 2500.0}
	var result: DataLoadResult = SchemaValidator.validate(value, product_schema)
	var data: Dictionary = result.data
	assert_eq(typeof(data["price_kurus"]), TYPE_INT)
	assert_eq(data["price_kurus"], 2500)


func test_fractional_number_rejected_for_int() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": "çay", "price_kurus": 25.5}, product_schema)
	assert_false(result.is_ok())
	assert_true(_error_text_contains(result, "$.price_kurus: beklenen tam sayı"), result.error_text())


func test_bool_is_not_accepted_as_int() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": "çay", "price_kurus": true}, product_schema)
	assert_false(result.is_ok())


func test_wrong_type_reports_path_and_value() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": 5.0, "price_kurus": 100.0}, product_schema)
	assert_true(_error_text_contains(result, "$.name: beklenen metin, bulunan 5"), result.error_text())


func test_missing_required_field() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": "çay"}, product_schema)
	assert_true(_error_text_contains(result, "zorunlu alan eksik: 'price_kurus'"), result.error_text())


func test_unknown_field_rejected_by_default() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": "çay", "price_kurus": 1.0, "prise": 2.0}, product_schema)
	assert_true(_error_text_contains(result, "$.prise: beklenmeyen alan"), result.error_text())


func test_additional_properties_allowed_when_enabled() -> void:
	var schema: Dictionary = {"type": "object", "additional_properties": true}
	var result: DataLoadResult = SchemaValidator.validate({"anything": 1.0}, schema)
	assert_true(result.is_ok(), result.error_text())


func test_minimum_and_maximum() -> void:
	var too_low: DataLoadResult = SchemaValidator.validate({"name": "çay", "price_kurus": -1.0}, product_schema)
	var too_high: DataLoadResult = SchemaValidator.validate({"name": "çay", "price_kurus": 100001.0}, product_schema)
	assert_true(_error_text_contains(too_low, "en az 0"), too_low.error_text())
	assert_true(_error_text_contains(too_high, "en fazla 100000"), too_high.error_text())


func test_enum() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": "çay", "price_kurus": 1.0, "size": "huge"}, product_schema)
	assert_true(_error_text_contains(result, "$.size: değer \"huge\" izin verilenler arasında değil"), result.error_text())


func test_min_length() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": "", "price_kurus": 1.0}, product_schema)
	assert_true(_error_text_contains(result, "$.name: en az 1 karakter"), result.error_text())


func test_array_item_error_has_index_in_path() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": "çay", "price_kurus": 1.0, "tags": ["a", 3.0]}, product_schema)
	assert_true(_error_text_contains(result, "$.tags[1]: beklenen metin"), result.error_text())


func test_min_items() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": "çay", "price_kurus": 1.0, "tags": []}, product_schema)
	assert_true(_error_text_contains(result, "$.tags: en az 1 öğe"), result.error_text())


func test_multiple_errors_are_all_reported() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": 1.0, "price_kurus": "x", "is_hot": "evet"}, product_schema)
	assert_eq(result.errors.size(), 3, result.error_text())


func test_number_accepts_float() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": "çay", "price_kurus": 1.0, "rating": 4.5}, product_schema)
	assert_true(result.is_ok(), result.error_text())


func test_unknown_schema_keyword_is_reported() -> void:
	# Şemadaki yazım hataları sessizce yok sayılmamalı.
	var schema: Dictionary = {"type": "int", "minimun": 0}
	var result: DataLoadResult = SchemaValidator.validate(1.0, schema)
	assert_true(_error_text_contains(result, "şemada bilinmeyen anahtar 'minimun'"), result.error_text())


func test_unknown_schema_type_is_reported() -> void:
	var result: DataLoadResult = SchemaValidator.validate(1.0, {"type": "integer"})
	assert_true(_error_text_contains(result, "şemada bilinmeyen tip 'integer'"), result.error_text())


func test_required_field_missing_from_properties_is_schema_error() -> void:
	var schema: Dictionary = {"type": "object", "required": ["name"], "properties": {}}
	var result: DataLoadResult = SchemaValidator.validate({"name": "çay"}, schema)
	assert_true(_error_text_contains(result, "properties içinde tanımlı değil"), result.error_text())
