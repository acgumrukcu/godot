extends GutTest


func _ingredients_data() -> Dictionary:
	return {"ingredients": [
		{"id": "coffee", "name": "Kahve", "unit_cost_kurus": 800},
		{"id": "milk", "name": "Süt", "unit_cost_kurus": 150},
	]}


func _recipe_entry(id: String, lines: Array) -> Dictionary:
	return {
		"id": id, "name": id, "ingredients": lines,
		"prep_minutes": 3, "base_price_kurus": 5000, "unlock_cost_kurus": 0,
	}


func _recipes_data(entries: Array) -> Dictionary:
	return {"recipes": entries}


func _latte() -> Dictionary:
	return _recipe_entry("latte", [
		{"ingredient": "coffee", "amount": 1},
		{"ingredient": "milk", "amount": 2},
	])


func test_default_content_loads() -> void:
	var result: DataLoadResult = ContentCatalog.load_default()
	assert_true(result.is_ok(), result.error_text())
	if not result.is_ok():
		return
	var catalog: ContentCatalog = result.data
	# docs/tasarim.md §4.3: başlangıçta 3 ürün.
	assert_eq(catalog.recipe_ids(), ["filter_coffee", "tea", "cookie"] as Array[String])
	for recipe_id: String in catalog.recipe_ids():
		assert_true(catalog.recipe(recipe_id).is_unlocked_at_start(), recipe_id)


func _catalog_or_fail(result: DataLoadResult) -> ContentCatalog:
	assert_true(result.is_ok(), result.error_text())
	return result.data


func test_default_recipes_are_profitable_at_base_price() -> void:
	var catalog: ContentCatalog = _catalog_or_fail(ContentCatalog.load_default())
	if catalog == null:
		return
	for recipe_id: String in catalog.recipe_ids():
		var recipe: Recipe = catalog.recipe(recipe_id)
		assert_gt(recipe.base_price_kurus, catalog.recipe_cost_kurus(recipe_id), recipe_id)


func test_recipe_fields_are_parsed() -> void:
	var result: DataLoadResult = ContentCatalog.from_dicts(_ingredients_data(), _recipes_data([_latte()]))
	assert_true(result.is_ok(), result.error_text())
	var recipe: Recipe = (result.data as ContentCatalog).recipe("latte")
	assert_eq(recipe.prep_minutes, 3)
	assert_eq(recipe.base_price_kurus, 5000)
	assert_eq(recipe.ingredient_amounts, {"coffee": 1, "milk": 2} as Dictionary[String, int])


func test_recipe_cost_is_sum_of_ingredients() -> void:
	var catalog: ContentCatalog = _catalog_or_fail(ContentCatalog.from_dicts(_ingredients_data(), _recipes_data([_latte()])))
	if catalog == null:
		return
	assert_eq(catalog.recipe_cost_kurus("latte"), 800 + 2 * 150)


func test_lookup_of_unknown_id_is_safe() -> void:
	var catalog: ContentCatalog = _catalog_or_fail(ContentCatalog.from_dicts(_ingredients_data(), _recipes_data([_latte()])))
	if catalog == null:
		return
	assert_null(catalog.recipe("nope"))
	assert_null(catalog.ingredient("nope"))
	assert_eq(catalog.recipe_cost_kurus("nope"), 0)


func test_unlock_cost_controls_start_availability() -> void:
	var locked: Dictionary = _latte()
	locked["unlock_cost_kurus"] = 20000
	var catalog: ContentCatalog = _catalog_or_fail(ContentCatalog.from_dicts(_ingredients_data(), _recipes_data([locked])))
	if catalog == null:
		return
	assert_false(catalog.recipe("latte").is_unlocked_at_start())


func test_unknown_ingredient_reference_is_error() -> void:
	var entry: Dictionary = _recipe_entry("mocha", [{"ingredient": "chocolate", "amount": 1}])
	var result: DataLoadResult = ContentCatalog.from_dicts(_ingredients_data(), _recipes_data([entry]))
	assert_false(result.is_ok())
	assert_null(result.data)
	assert_string_contains(result.error_text(), "'mocha' tarifi bilinmeyen malzemeye başvuruyor: 'chocolate'")


func test_duplicate_ingredient_id_is_error() -> void:
	var data: Dictionary = _ingredients_data()
	(data["ingredients"] as Array).append({"id": "milk", "name": "Süt 2", "unit_cost_kurus": 1})
	var result: DataLoadResult = ContentCatalog.from_dicts(data, _recipes_data([_latte()]))
	assert_string_contains(result.error_text(), "ingredients: 'milk' id'si birden fazla kez tanımlı")


func test_duplicate_recipe_id_is_error() -> void:
	var result: DataLoadResult = ContentCatalog.from_dicts(_ingredients_data(), _recipes_data([_latte(), _latte()]))
	assert_string_contains(result.error_text(), "recipes: 'latte' id'si birden fazla kez tanımlı")


func test_duplicate_ingredient_line_in_recipe_is_error() -> void:
	var entry: Dictionary = _recipe_entry("double", [
		{"ingredient": "coffee", "amount": 1},
		{"ingredient": "coffee", "amount": 1},
	])
	var result: DataLoadResult = ContentCatalog.from_dicts(_ingredients_data(), _recipes_data([entry]))
	assert_string_contains(result.error_text(), "'double' tarifinde 'coffee' birden fazla kez geçiyor")


# --- Müşteri tipleri ---

func _customer_entry(id: String) -> Dictionary:
	return {
		"id": id, "name": id,
		"arrival_windows": [{"start_hour": 8, "end_hour": 10, "customers_per_hour": 4}],
		"preferences": [{"recipe": "latte", "weight": 1}],
		"price_sensitivity_percent": 100, "patience_minutes": 10,
	}


func _with_customers(entries: Array) -> DataLoadResult:
	return ContentCatalog.from_dicts(_ingredients_data(), _recipes_data([_latte()]), {"customer_types": entries})


func test_default_customer_types_load_in_file_order() -> void:
	var catalog: ContentCatalog = _catalog_or_fail(ContentCatalog.load_default())
	if catalog == null:
		return
	assert_eq(catalog.customer_type_ids(), ["fisherman", "student", "retiree"] as Array[String])


func test_customer_type_fields_are_parsed() -> void:
	var catalog: ContentCatalog = _catalog_or_fail(_with_customers([_customer_entry("regular")]))
	if catalog == null:
		return
	var customer_type: CustomerType = catalog.customer_type("regular")
	assert_eq(customer_type.preferences, {"latte": 1} as Dictionary[String, int])
	assert_eq(customer_type.customers_per_hour_at(8), 4)
	assert_eq(customer_type.customers_per_hour_at(9), 4)
	assert_eq(customer_type.customers_per_hour_at(10), 0, "end_hour hariç")


func test_overlapping_windows_add_up() -> void:
	var entry: Dictionary = _customer_entry("regular")
	(entry["arrival_windows"] as Array).append({"start_hour": 9, "end_hour": 11, "customers_per_hour": 2})
	var catalog: ContentCatalog = _catalog_or_fail(_with_customers([entry]))
	if catalog == null:
		return
	assert_eq(catalog.customer_type("regular").customers_per_hour_at(9), 6)


func test_customer_preference_must_reference_known_recipe() -> void:
	var entry: Dictionary = _customer_entry("regular")
	entry["preferences"] = [{"recipe": "mocha", "weight": 1}]
	assert_string_contains(_with_customers([entry]).error_text(), "'regular' bilinmeyen tarife başvuruyor: 'mocha'")


func test_arrival_window_must_end_after_start() -> void:
	var entry: Dictionary = _customer_entry("regular")
	entry["arrival_windows"] = [{"start_hour": 10, "end_hour": 10, "customers_per_hour": 1}]
	assert_string_contains(_with_customers([entry]).error_text(), "end_hour (10) start_hour'dan (10) büyük olmalı")


func test_duplicate_customer_type_id_is_error() -> void:
	var result: DataLoadResult = _with_customers([_customer_entry("regular"), _customer_entry("regular")])
	assert_string_contains(result.error_text(), "customer_types: 'regular' id'si birden fazla kez tanımlı")


func test_duplicate_preference_is_error() -> void:
	var entry: Dictionary = _customer_entry("regular")
	(entry["preferences"] as Array).append({"recipe": "latte", "weight": 2})
	assert_string_contains(_with_customers([entry]).error_text(), "'regular' tercihlerinde 'latte' birden fazla kez geçiyor")


func test_overlapping_windows_cannot_exceed_one_customer_per_minute() -> void:
	var entry: Dictionary = _customer_entry("crowd")
	entry["arrival_windows"] = [
		{"start_hour": 8, "end_hour": 10, "customers_per_hour": 40},
		{"start_hour": 9, "end_hour": 11, "customers_per_hour": 40},
	]
	assert_string_contains(_with_customers([entry]).error_text(), "'crowd' saat 9'de toplam customers_per_hour 80, en fazla 60")
