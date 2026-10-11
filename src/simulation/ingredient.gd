class_name Ingredient
extends RefCounted

# data/ingredients.json içindeki bir malzeme. Bir birim = bir porsiyonluk miktar.

var id: String = ""
var display_name: String = ""
var unit_cost_kurus: int = 0


func _init(p_id: String, p_display_name: String, p_unit_cost_kurus: int) -> void:
	id = p_id
	display_name = p_display_name
	unit_cost_kurus = p_unit_cost_kurus
