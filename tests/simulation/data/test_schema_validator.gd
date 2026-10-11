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


func test_error_result_has_null_data() -> void:
	var result: DataLoadResult = SchemaValidator.validate({"name": "çay"}, product_schema)
	assert_false(result.is_ok())
	assert_null(result.data)


func test_int_enum_from_json_schema_matches() -> void:
	# JSON'dan okunan şemada enum öğeleri float'tır (1.0, 2.0); int değerle eşleşmeli.
	var schema: Variant = JSON.parse_string('{"type": "int", "enum": [1, 2, 4]}')
	var ok_result: DataLoadResult = SchemaValidator.validate(2.0, schema)
	var bad_result: DataLoadResult = SchemaValidator.validate(3.0, schema)
	assert_true(ok_result.is_ok(), ok_result.error_text())
	assert_eq(ok_result.data, 2)
	assert_true(_error_text_contains(bad_result, "$: değer 3 izin verilenler arasında değil: [1,2,4]"), bad_result.error_text())


# --- Şemanın kendisinin doğrulanması ---

func _schema_errors(schema: Variant) -> String:
	return "\n".join(PackedStringArray(SchemaValidator.validate_schema(schema)))


func test_valid_schema_has_no_errors() -> void:
	assert_eq(_schema_errors(product_schema), "")


func test_unknown_schema_keyword_is_reported() -> void:
	# Şemadaki yazım hataları sessizce yok sayılmamalı.
	assert_string_contains(_schema_errors({"type": "int", "minimun": 0}), "şema: bilinmeyen anahtar 'minimun'")


func test_unknown_schema_type_is_reported() -> void:
	assert_string_contains(_schema_errors({"type": "integer"}), "şema: 'type' şunlardan biri olmalı")


func test_keyword_on_wrong_type_is_reported() -> void:
	assert_string_contains(_schema_errors({"type": "string", "minimum": 0}), "'minimum' anahtarı 'string' tipinde kullanılamaz")


func test_required_field_missing_from_properties_is_schema_error() -> void:
	var schema: Dictionary = {"type": "object", "required": ["name"], "properties": {}}
	assert_string_contains(_schema_errors(schema), "'name' properties içinde tanımlı değil")


func test_wrongly_typed_schema_keywords_are_errors_not_crashes() -> void:
	var broken_schemas: Array = [
		{"type": "object", "properties": ["a"]},
		{"type": "object", "properties": {"a": "int"}},
		{"type": "object", "additional_properties": "yes"},
		{"type": "object", "required": "a"},
		{"type": "string", "enum": "a"},
		{"type": "array", "items": "int"},
		{"type": "array", "min_items": "1"},
		{"type": "string", "min_length": -1.0},
		{"type": "int", "minimum": "0"},
		{"type": "int", "enum": [1.0, 2.5]},
		"not a schema",
	]
	for schema: Variant in broken_schemas:
		var result: DataLoadResult = SchemaValidator.validate({}, schema)
		assert_false(result.is_ok(), "Bozuk şema kabul edildi: %s" % JSON.stringify(schema))
		assert_null(result.data)


func test_schema_error_in_absent_optional_field_is_caught() -> void:
	var schema: Dictionary = {"type": "object", "properties": {"note": {"type": "integer"}}}
	var result: DataLoadResult = SchemaValidator.validate({}, schema)
	assert_true(_error_text_contains(result, "şema.properties.note: 'type'"), result.error_text())


func test_schema_error_in_items_is_caught_for_empty_array() -> void:
	var schema: Dictionary = {"type": "array", "items": {"type": "int", "minimun": 0}}
	var result: DataLoadResult = SchemaValidator.validate([], schema)
	assert_true(_error_text_contains(result, "şema.items: bilinmeyen anahtar 'minimun'"), result.error_text())


func test_schema_error_in_items_is_reported_once() -> void:
	var schema: Dictionary = {"type": "array", "items": {"type": "int", "minimun": 0}}
	var result: DataLoadResult = SchemaValidator.validate([1.0, 2.0, 3.0], schema)
	assert_eq(result.errors.size(), 1, result.error_text())
