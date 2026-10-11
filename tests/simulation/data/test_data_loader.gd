extends GutTest

const FIXTURE_DIR: String = "res://tests/fixtures/data/"
const PRODUCT_SCHEMA: String = FIXTURE_DIR + "product.schema.json"


func test_valid_file_loads_with_converted_types() -> void:
	var result: DataLoadResult = DataLoader.load_validated(FIXTURE_DIR + "valid.json", PRODUCT_SCHEMA)
	assert_true(result.is_ok(), result.error_text())
	var data: Dictionary = result.data
	assert_eq(data["name"], "filtre kahve")
	assert_eq(typeof(data["price_kurus"]), TYPE_INT)
	assert_eq(data["price_kurus"], 4500)


func test_missing_file_names_the_path() -> void:
	var path: String = FIXTURE_DIR + "does_not_exist.json"
	var result: DataLoadResult = DataLoader.load_validated(path, PRODUCT_SCHEMA)
	assert_false(result.is_ok())
	assert_true(result.error_text().contains(path + ": dosya bulunamadı"), result.error_text())


func test_missing_schema_names_the_path() -> void:
	var schema_path: String = FIXTURE_DIR + "missing.schema.json"
	var result: DataLoadResult = DataLoader.load_validated(FIXTURE_DIR + "valid.json", schema_path)
	assert_true(result.error_text().contains(schema_path + ": dosya bulunamadı"), result.error_text())


func test_syntax_error_reports_file_and_line() -> void:
	var path: String = FIXTURE_DIR + "broken_syntax.json"
	var result: DataLoadResult = DataLoader.load_validated(path, PRODUCT_SCHEMA)
	assert_false(result.is_ok())
	assert_true(result.error_text().contains(path + ":3: JSON sözdizimi hatası"), result.error_text())


func test_broken_schema_is_reported_with_schema_path() -> void:
	var schema_path: String = FIXTURE_DIR + "broken.schema.json"
	var result: DataLoadResult = DataLoader.load_validated(FIXTURE_DIR + "valid.json", schema_path)
	assert_false(result.is_ok())
	assert_null(result.data)
	assert_true(result.error_text().contains(schema_path + ": şema.properties.name: 'type'"), result.error_text())


func test_schema_error_is_prefixed_with_file_path() -> void:
	var path: String = FIXTURE_DIR + "wrong_type.json"
	var result: DataLoadResult = DataLoader.load_validated(path, PRODUCT_SCHEMA)
	assert_false(result.is_ok())
	assert_null(result.data)
	assert_true(
		result.error_text().contains(path + ": $.price_kurus: beklenen tam sayı, bulunan \"kırk beş\""),
		result.error_text()
	)
