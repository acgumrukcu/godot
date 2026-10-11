extends GutTest


func test_starting_menu_has_unlocked_recipes_at_base_price() -> void:
	var catalog: ContentCatalog = ContentCatalog.load_default().data
	var menu: Menu = Menu.with_starting_recipes(catalog)
	for recipe_id: String in catalog.recipe_ids():
		var recipe: Recipe = catalog.recipe(recipe_id)
		assert_eq(menu.has(recipe_id), recipe.is_unlocked_at_start(), recipe_id)
		if recipe.is_unlocked_at_start():
			assert_eq(menu.price(recipe_id), recipe.base_price_kurus)


func test_set_price_and_remove() -> void:
	var menu: Menu = Menu.new()
	assert_true(menu.set_price("tea", 2500))
	assert_eq(menu.price("tea"), 2500)
	menu.remove("tea")
	assert_false(menu.has("tea"))
	assert_eq(menu.price("tea"), -1)


func test_negative_price_is_rejected() -> void:
	var menu: Menu = Menu.new()
	assert_false(menu.set_price("tea", -1))
	assert_false(menu.has("tea"))


func test_free_item_is_allowed() -> void:
	var menu: Menu = Menu.new()
	assert_true(menu.set_price("tea", 0))
	assert_eq(menu.price("tea"), 0)
