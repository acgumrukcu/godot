extends GutTest

# data/ altındaki her JSON içerik dosyasının bir şeması olmalı ve ona uymalı (CLAUDE.md kural 3).
# Yeni içerik dosyası eklendiğinde bu test onu otomatik kapsar.


func _data_names() -> Array[String]:
	var names: Array[String] = []
	for file_name: String in DirAccess.get_files_at(DataLoader.DATA_DIR):
		if file_name.ends_with(DataLoader.DATA_EXTENSION):
			names.append(file_name.trim_suffix(DataLoader.DATA_EXTENSION))
	return names


func test_data_dir_is_not_empty() -> void:
	assert_gt(_data_names().size(), 0)


func test_every_data_file_matches_its_schema() -> void:
	for data_name: String in _data_names():
		var result: DataLoadResult = DataLoader.load_data(data_name)
		assert_true(result.is_ok(), "%s.json:\n%s" % [data_name, result.error_text()])


func test_every_schema_is_valid() -> void:
	for file_name: String in DirAccess.get_files_at(DataLoader.SCHEMA_DIR):
		if file_name.ends_with(DataLoader.SCHEMA_EXTENSION):
			var loaded: DataLoadResult = DataLoader.load_json(DataLoader.SCHEMA_DIR + file_name)
			assert_true(loaded.is_ok(), loaded.error_text())
			var errors: Array[String] = SchemaValidator.validate_schema(loaded.data)
			assert_eq(errors.size(), 0, "%s:\n%s" % [file_name, "\n".join(PackedStringArray(errors))])


func test_every_schema_has_a_data_file() -> void:
	var names: Array[String] = _data_names()
	for file_name: String in DirAccess.get_files_at(DataLoader.SCHEMA_DIR):
		if file_name.ends_with(DataLoader.SCHEMA_EXTENSION):
			var data_name: String = file_name.trim_suffix(DataLoader.SCHEMA_EXTENSION)
			assert_has(names, data_name, "Şemanın veri dosyası yok: " + file_name)
