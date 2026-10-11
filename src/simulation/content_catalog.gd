class_name ContentCatalog
extends RefCounted

# Oyun içeriğinin (malzemeler, tarifler, müşteri tipleri) tipli ve çapraz denetlenmiş hali.
# Şemanın ifade edemediği kurallar burada kontrol edilir: benzersiz id'ler, var olan
# kayıtlara başvurma, saat aralıklarının tutarlılığı (bkz. docs/kararlar/002-veri-semalari.md).

const INGREDIENTS_DATA: String = "ingredients"
const RECIPES_DATA: String = "recipes"
const CUSTOMER_TYPES_DATA: String = "customer_types"

var _ingredients: Dictionary[String, Ingredient] = {}
var _recipes: Dictionary[String, Recipe] = {}
# Veri dosyasındaki sıra korunur (menüde gösterim için).
var _recipe_order: Array[String] = []
# Veri dosyasındaki sıra korunur (deterministik müşteri üretimi için).
var _customer_types: Dictionary[String, CustomerType] = {}


# data/ altındaki içerik dosyalarını yükler. Başarılıysa result.data bir ContentCatalog'tur.
static func load_default() -> DataLoadResult:
	var loaded: Array[Dictionary] = []
	for data_name: String in [INGREDIENTS_DATA, RECIPES_DATA, CUSTOMER_TYPES_DATA]:
		var data_result: DataLoadResult = DataLoader.load_data(data_name)
		if not data_result.is_ok():
			return data_result
		loaded.append(data_result.data)
	return from_dicts(loaded[0], loaded[1], loaded[2])


# Şemadan geçmiş sözlüklerden oluşturur.
static func from_dicts(
	ingredients_data: Dictionary,
	recipes_data: Dictionary,
	customer_types_data: Dictionary = {CUSTOMER_TYPES_DATA: []}
) -> DataLoadResult:
	var result: DataLoadResult = DataLoadResult.new()
	var catalog: ContentCatalog = ContentCatalog.new()

	for entry: Dictionary in ingredients_data["ingredients"]:
		var ingredient: Ingredient = Ingredient.new(entry["id"], entry["name"], entry["unit_cost_kurus"])
		if catalog._ingredients.has(ingredient.id):
			result.errors.append("%s: '%s' id'si birden fazla kez tanımlı" % [INGREDIENTS_DATA, ingredient.id])
		catalog._ingredients[ingredient.id] = ingredient

	for entry: Dictionary in recipes_data["recipes"]:
		var recipe: Recipe = _recipe_from_dict(entry, catalog, result.errors)
		if catalog._recipes.has(recipe.id):
			result.errors.append("%s: '%s' id'si birden fazla kez tanımlı" % [RECIPES_DATA, recipe.id])
		else:
			catalog._recipe_order.append(recipe.id)
		catalog._recipes[recipe.id] = recipe

	for entry: Dictionary in customer_types_data[CUSTOMER_TYPES_DATA]:
		var customer_type: CustomerType = _customer_type_from_dict(entry, catalog, result.errors)
		if catalog._customer_types.has(customer_type.id):
			result.errors.append("%s: '%s' id'si birden fazla kez tanımlı" % [CUSTOMER_TYPES_DATA, customer_type.id])
		else:
			catalog._customer_types[customer_type.id] = customer_type

	if result.is_ok():
		result.data = catalog
	return result


static func _customer_type_from_dict(entry: Dictionary, catalog: ContentCatalog, errors: Array[String]) -> CustomerType:
	var customer_type: CustomerType = CustomerType.new()
	customer_type.id = entry["id"]
	customer_type.display_name = entry["name"]
	customer_type.price_sensitivity_percent = entry["price_sensitivity_percent"]
	customer_type.patience_minutes = entry["patience_minutes"]
	for window_entry: Dictionary in entry["arrival_windows"]:
		var window: ArrivalWindow = ArrivalWindow.new(
			window_entry["start_hour"], window_entry["end_hour"], window_entry["customers_per_hour"]
		)
		if window.end_hour <= window.start_hour:
			errors.append("%s: '%s' geliş aralığında end_hour (%d) start_hour'dan (%d) büyük olmalı" % [
				CUSTOMER_TYPES_DATA, customer_type.id, window.end_hour, window.start_hour
			])
		customer_type.arrival_windows.append(window)
	for preference: Dictionary in entry["preferences"]:
		var recipe_id: String = preference["recipe"]
		if not catalog._recipes.has(recipe_id):
			errors.append("%s: '%s' bilinmeyen tarife başvuruyor: '%s'" % [CUSTOMER_TYPES_DATA, customer_type.id, recipe_id])
		if customer_type.preferences.has(recipe_id):
			errors.append("%s: '%s' tercihlerinde '%s' birden fazla kez geçiyor" % [CUSTOMER_TYPES_DATA, customer_type.id, recipe_id])
		customer_type.preferences[recipe_id] = preference["weight"]
	return customer_type


static func _recipe_from_dict(entry: Dictionary, catalog: ContentCatalog, errors: Array[String]) -> Recipe:
	var recipe: Recipe = Recipe.new()
	recipe.id = entry["id"]
	recipe.display_name = entry["name"]
	recipe.prep_minutes = entry["prep_minutes"]
	recipe.base_price_kurus = entry["base_price_kurus"]
	recipe.unlock_cost_kurus = entry["unlock_cost_kurus"]
	for line: Dictionary in entry["ingredients"]:
		var ingredient_id: String = line["ingredient"]
		if not catalog._ingredients.has(ingredient_id):
			errors.append("%s: '%s' tarifi bilinmeyen malzemeye başvuruyor: '%s'" % [RECIPES_DATA, recipe.id, ingredient_id])
		if recipe.ingredient_amounts.has(ingredient_id):
			errors.append("%s: '%s' tarifinde '%s' birden fazla kez geçiyor" % [RECIPES_DATA, recipe.id, ingredient_id])
		recipe.ingredient_amounts[ingredient_id] = line["amount"]
	return recipe


func ingredient(ingredient_id: String) -> Ingredient:
	return _ingredients.get(ingredient_id)


func recipe(recipe_id: String) -> Recipe:
	return _recipes.get(recipe_id)


func ingredient_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_ingredients.keys())
	return ids


# Veri dosyasındaki sırayla.
func recipe_ids() -> Array[String]:
	return _recipe_order.duplicate()


func customer_type(type_id: String) -> CustomerType:
	return _customer_types.get(type_id)


# Veri dosyasındaki sırayla.
func customer_type_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_customer_types.keys())
	return ids


# Bir porsiyonun malzeme maliyeti (docs/tasarim.md §4.2). Bilinmeyen id için 0.
func recipe_cost_kurus(recipe_id: String) -> int:
	var target: Recipe = recipe(recipe_id)
	if target == null:
		return 0
	var total: int = 0
	for ingredient_id: String in target.ingredient_amounts:
		total += _ingredients[ingredient_id].unit_cost_kurus * target.ingredient_amounts[ingredient_id]
	return total
