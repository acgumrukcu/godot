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
