class_name Recipe
extends RefCounted

# data/recipes.json içindeki bir tarif (docs/tasarim.md §4.3).

var id: String = ""
var display_name: String = ""
# Malzeme id → gereken birim sayısı.
var ingredient_amounts: Dictionary[String, int] = {}
var prep_minutes: int = 0
var base_price_kurus: int = 0
var unlock_cost_kurus: int = 0


func is_unlocked_at_start() -> bool:
	return unlock_cost_kurus == 0
