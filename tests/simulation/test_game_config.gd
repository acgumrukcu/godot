extends GutTest


func _valid_dict() -> Dictionary:
	return {
		"open_hour": 8, "close_hour": 20, "real_ms_per_tick": 1000,
		"speed_multipliers": [1, 2, 4], "starting_balance_kurus": 50000,
	}


func test_default_config_loads() -> void:
	var result: DataLoadResult = GameConfig.load_default()
	assert_true(result.is_ok(), result.error_text())
	var config: GameConfig = result.data
	assert_eq(config.open_hour, 8)
	assert_eq(config.close_hour, 20)
	assert_eq(config.speed_multipliers, [1, 2, 4] as Array[int])


func test_from_dict_copies_fields() -> void:
	var result: DataLoadResult = GameConfig.from_dict(_valid_dict())
	assert_true(result.is_ok(), result.error_text())
	if not result.is_ok():
		return
	var config: GameConfig = result.data
	assert_eq(config.real_ms_per_tick, 1000)
	assert_eq(config.starting_balance_kurus, 50000)


func test_close_hour_must_be_after_open_hour() -> void:
	var data: Dictionary = _valid_dict()
	data["close_hour"] = 8
	var result: DataLoadResult = GameConfig.from_dict(data)
	assert_false(result.is_ok())
	assert_null(result.data)
	assert_string_contains(result.error_text(), "close_hour (8) open_hour'dan (8) büyük olmalı")
