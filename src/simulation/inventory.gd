class_name Inventory
extends RefCounted

# Malzeme stoku. Miktarlar birim (porsiyon) cinsinden int'tir ve asla negatife düşmez.

var _stock: Dictionary[String, int] = {}


func quantity(ingredient_id: String) -> int:
	return _stock.get(ingredient_id, 0)


# Stokun kopyası.
func stock() -> Dictionary[String, int]:
	return _stock.duplicate()


func add(ingredient_id: String, amount: int) -> bool:
	if amount <= 0:
		return false
	_stock[ingredient_id] = quantity(ingredient_id) + amount
	return true


# Malzemeyi kasadan ödeyerek satın alır. Para yetmezse hiçbir şey değişmez.
func purchase(ingredient: Ingredient, amount: int, economy: Economy, day: int) -> bool:
	if amount <= 0:
		return false
	var cost: int = ingredient.unit_cost_kurus * amount
	if not economy.spend(cost, Economy.Category.INGREDIENT_PURCHASE, day, ingredient.id):
		return false
	return add(ingredient.id, amount)


func can_prepare(recipe: Recipe) -> bool:
	for ingredient_id: String in recipe.ingredient_amounts:
		if quantity(ingredient_id) < recipe.ingredient_amounts[ingredient_id]:
			return false
	return true


# Bir porsiyon için malzemeleri stoktan düşer. Eksik varsa hiçbir şey değişmez.
func prepare(recipe: Recipe) -> bool:
	if not can_prepare(recipe):
		return false
	for ingredient_id: String in recipe.ingredient_amounts:
		_stock[ingredient_id] -= recipe.ingredient_amounts[ingredient_id]
	return true
