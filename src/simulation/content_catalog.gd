class_name ContentCatalog
extends RefCounted

# Oyun içeriğinin (malzemeler, tarifler) tipli ve çapraz denetlenmiş hali.
# Şemanın ifade edemediği kurallar burada kontrol edilir: benzersiz id'ler ve
# tariflerin var olan malzemelere başvurması (bkz. docs/kararlar/002-veri-semalari.md).

const INGREDIENTS_DATA: String = "ingredients"
const RECIPES_DATA: String = "recipes"

var _ingredients: Dictionary[String, Ingredient] = {}
var _recipes: Dictionary[String, Recipe] = {}
# Veri dosyasındaki sıra korunur (menüde gösterim için).
var _recipe_order: Array[String] = []


# data/ingredients.json ve data/recipes.json'u yükler. Başarılıysa result.data bir ContentCatalog'tur.
static func load_default() -> DataLoadResult:
	var ingredients_result: DataLoadResult = DataLoader.load_data(INGREDIENTS_DATA)
	if not ingredients_result.is_ok():
		return ingredients_result
	var recipes_result: DataLoadResult = DataLoader.load_data(RECIPES_DATA)
	if not recipes_result.is_ok():
		return recipes_result
	return from_dicts(ingredients_result.data, recipes_result.data)


# Şemadan geçmiş sözlüklerden oluşturur.
static func from_dicts(ingredients_data: Dictionary, recipes_data: Dictionary) -> DataLoadResult:
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

	if result.is_ok():
		result.data = catalog
	return result


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


# Bir porsiyonun malzeme maliyeti (docs/tasarim.md §4.2).
func recipe_cost_kurus(recipe_id: String) -> int:
	var target: Recipe = recipe(recipe_id)
	var total: int = 0
	for ingredient_id: String in target.ingredient_amounts:
		total += _ingredients[ingredient_id].unit_cost_kurus * target.ingredient_amounts[ingredient_id]
	return total
