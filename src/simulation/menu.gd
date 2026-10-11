class_name Menu
extends RefCounted

# Oyuncunun satışa koyduğu ürünler ve belirlediği fiyatlar (kuruş).
# Satış fiyatını oyuncu belirler (docs/tasarim.md §4.2).

var _prices: Dictionary[String, int] = {}


func set_price(recipe_id: String, price_kurus: int) -> bool:
	if price_kurus < 0:
		return false
	_prices[recipe_id] = price_kurus
	return true


func remove(recipe_id: String) -> void:
	_prices.erase(recipe_id)


func has(recipe_id: String) -> bool:
	return _prices.has(recipe_id)


# Menüde yoksa -1.
func price(recipe_id: String) -> int:
	return _prices.get(recipe_id, -1)


func recipe_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_prices.keys())
	return ids


# Başlangıçta açık tüm tarifleri temel fiyatlarıyla menüye koyar.
static func with_starting_recipes(catalog: ContentCatalog) -> Menu:
	var menu: Menu = Menu.new()
	for recipe_id: String in catalog.recipe_ids():
		var recipe: Recipe = catalog.recipe(recipe_id)
		if recipe.is_unlocked_at_start():
			menu.set_price(recipe_id, recipe.base_price_kurus)
	return menu
