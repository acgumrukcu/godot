extends GutTest

var inventory: Inventory
var coffee: Ingredient
var milk: Ingredient
var latte: Recipe


func before_each() -> void:
	inventory = Inventory.new()
	coffee = Ingredient.new("coffee", "Kahve", 800)
	milk = Ingredient.new("milk", "Süt", 150)
	latte = Recipe.new()
	latte.id = "latte"
	latte.ingredient_amounts = {"coffee": 1, "milk": 2}


func test_starts_empty() -> void:
	assert_eq(inventory.quantity("coffee"), 0)
	assert_eq(inventory.stock().size(), 0)


func test_add_increases_quantity() -> void:
	assert_true(inventory.add("coffee", 3))
	inventory.add("coffee", 2)
	assert_eq(inventory.quantity("coffee"), 5)


func test_add_rejects_non_positive_amounts() -> void:
	assert_false(inventory.add("coffee", 0))
	assert_false(inventory.add("coffee", -1))
	assert_eq(inventory.quantity("coffee"), 0)


func test_purchase_spends_money_and_adds_stock() -> void:
	var economy: Economy = Economy.new(10000)
	assert_true(inventory.purchase(coffee, 5, economy, 1))
	assert_eq(inventory.quantity("coffee"), 5)
	assert_eq(economy.balance(), 10000 - 5 * 800)
	assert_eq(economy.expense_for_day(1), 5 * 800)


func test_purchase_without_enough_money_changes_nothing() -> void:
	var economy: Economy = Economy.new(1000)
	assert_false(inventory.purchase(coffee, 2, economy, 1))
	assert_eq(inventory.quantity("coffee"), 0)
	assert_eq(economy.balance(), 1000)


func test_purchase_rejects_non_positive_amounts() -> void:
	var economy: Economy = Economy.new(10000)
	assert_false(inventory.purchase(coffee, 0, economy, 1))
	assert_eq(economy.balance(), 10000)


func test_can_prepare_requires_every_ingredient() -> void:
	inventory.add("coffee", 1)
	inventory.add("milk", 1)
	assert_false(inventory.can_prepare(latte), "Süt 2 birim gerekli")
	inventory.add("milk", 1)
	assert_true(inventory.can_prepare(latte))


func test_prepare_consumes_ingredients() -> void:
	inventory.add("coffee", 2)
	inventory.add("milk", 5)
	assert_true(inventory.prepare(latte))
	assert_eq(inventory.quantity("coffee"), 1)
	assert_eq(inventory.quantity("milk"), 3)


func test_prepare_without_stock_changes_nothing() -> void:
	inventory.add("coffee", 1)
	assert_false(inventory.prepare(latte))
	assert_eq(inventory.quantity("coffee"), 1)
	assert_eq(inventory.quantity("milk"), 0)


func test_stock_returns_a_copy() -> void:
	inventory.add("coffee", 1)
	inventory.stock()["coffee"] = 99
	assert_eq(inventory.quantity("coffee"), 1)
