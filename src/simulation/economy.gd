class_name Economy
extends RefCounted

# Kafenin kasası ve gelir/gider defteri. Para her zaman kuruş cinsinden int'tir.
# "İflas yok" ilkesi (docs/tasarim.md §2): bakiye asla negatife düşmez; karşılanamayan
# harcama reddedilir.

enum Category { SALE, INGREDIENT_PURCHASE }

const INCOME_CATEGORIES: Array[Category] = [Category.SALE]
const EXPENSE_CATEGORIES: Array[Category] = [Category.INGREDIENT_PURCHASE]

var _balance: int = 0
var _transactions: Array[EconomyTransaction] = []


func _init(starting_balance: int) -> void:
	_balance = maxi(starting_balance, 0)


func balance() -> int:
	return _balance


# Gelir ekler. amount pozitif ve kategori bir gelir kategorisi olmalıdır.
func earn(amount: int, category: Category, day: int, note: String = "") -> bool:
	if amount <= 0 or not INCOME_CATEGORIES.has(category):
		return false
	_balance += amount
	_transactions.append(EconomyTransaction.new(day, amount, category, note))
	return true


# Gider düşer. Bakiye yetmiyorsa hiçbir şey değişmez ve false döner.
func spend(amount: int, category: Category, day: int, note: String = "") -> bool:
	if amount <= 0 or not EXPENSE_CATEGORIES.has(category):
		return false
	if not can_afford(amount):
		return false
	_balance -= amount
	_transactions.append(EconomyTransaction.new(day, -amount, category, note))
	return true


func can_afford(amount: int) -> bool:
	return amount <= _balance


# Defterin kopyası; dışarıdan değiştirilemez.
func transactions() -> Array[EconomyTransaction]:
	return _transactions.duplicate()


func income_for_day(day: int) -> int:
	var total: int = 0
	for transaction: EconomyTransaction in _transactions:
		if transaction.day == day and transaction.amount > 0:
			total += transaction.amount
	return total


# Pozitif sayı olarak döner.
func expense_for_day(day: int) -> int:
	var total: int = 0
	for transaction: EconomyTransaction in _transactions:
		if transaction.day == day and transaction.amount < 0:
			total -= transaction.amount
	return total


func net_for_day(day: int) -> int:
	return income_for_day(day) - expense_for_day(day)
