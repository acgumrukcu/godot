class_name EconomyTransaction
extends RefCounted

# Kasa defterindeki tek bir kayıt. amount işaretlidir: gelir pozitif, gider negatif (kuruş).

var day: int = 0
var amount: int = 0
var category: Economy.Category = Economy.Category.SALE
var note: String = ""


func _init(p_day: int, p_amount: int, p_category: Economy.Category, p_note: String) -> void:
	day = p_day
	amount = p_amount
	category = p_category
	note = p_note
