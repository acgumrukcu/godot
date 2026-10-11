extends GutTest

const STARTING_BALANCE: int = 10000

var economy: Economy


func before_each() -> void:
	economy = Economy.new(STARTING_BALANCE)


func test_starts_with_given_balance() -> void:
	assert_eq(economy.balance(), STARTING_BALANCE)
	assert_eq(economy.transactions().size(), 0)


func test_negative_starting_balance_is_clamped_to_zero() -> void:
	assert_eq(Economy.new(-500).balance(), 0)


func test_earn_increases_balance_and_records_transaction() -> void:
	assert_true(economy.earn(4500, Economy.Category.SALE, 1, "filtre kahve"))
	assert_eq(economy.balance(), STARTING_BALANCE + 4500)
	var transaction: EconomyTransaction = economy.transactions()[0]
	assert_eq(transaction.amount, 4500)
	assert_eq(transaction.day, 1)
	assert_eq(transaction.category, Economy.Category.SALE)
	assert_eq(transaction.note, "filtre kahve")


func test_spend_decreases_balance_and_records_negative_amount() -> void:
	assert_true(economy.spend(3000, Economy.Category.INGREDIENT_PURCHASE, 1))
	assert_eq(economy.balance(), STARTING_BALANCE - 3000)
	assert_eq(economy.transactions()[0].amount, -3000)


func test_can_spend_exact_balance() -> void:
	assert_true(economy.spend(STARTING_BALANCE, Economy.Category.INGREDIENT_PURCHASE, 1))
	assert_eq(economy.balance(), 0)


func test_overspending_is_rejected_without_change() -> void:
	# İflas yok: bakiye negatife düşmez.
	assert_false(economy.spend(STARTING_BALANCE + 1, Economy.Category.INGREDIENT_PURCHASE, 1))
	assert_eq(economy.balance(), STARTING_BALANCE)
	assert_eq(economy.transactions().size(), 0)


func test_can_afford() -> void:
	assert_true(economy.can_afford(STARTING_BALANCE))
	assert_false(economy.can_afford(STARTING_BALANCE + 1))


func test_zero_or_negative_amounts_are_rejected() -> void:
	assert_false(economy.earn(0, Economy.Category.SALE, 1))
	assert_false(economy.earn(-100, Economy.Category.SALE, 1))
	assert_false(economy.spend(0, Economy.Category.INGREDIENT_PURCHASE, 1))
	assert_false(economy.spend(-100, Economy.Category.INGREDIENT_PURCHASE, 1))
	assert_eq(economy.balance(), STARTING_BALANCE)
	assert_eq(economy.transactions().size(), 0)


func test_category_direction_is_enforced() -> void:
	assert_false(economy.earn(100, Economy.Category.INGREDIENT_PURCHASE, 1), "Gider kategorisiyle gelir eklenemez")
	assert_false(economy.spend(100, Economy.Category.SALE, 1), "Gelir kategorisiyle gider düşülemez")
	assert_eq(economy.balance(), STARTING_BALANCE)


func test_daily_totals() -> void:
	economy.earn(4500, Economy.Category.SALE, 1)
	economy.earn(2500, Economy.Category.SALE, 1)
	economy.spend(3000, Economy.Category.INGREDIENT_PURCHASE, 1)
	economy.earn(1000, Economy.Category.SALE, 2)
	assert_eq(economy.income_for_day(1), 7000)
	assert_eq(economy.expense_for_day(1), 3000)
	assert_eq(economy.net_for_day(1), 4000)
	assert_eq(economy.income_for_day(2), 1000)
	assert_eq(economy.expense_for_day(2), 0)
	assert_eq(economy.net_for_day(3), 0)


func test_transactions_returns_a_copy() -> void:
	economy.earn(100, Economy.Category.SALE, 1)
	economy.transactions().clear()
	assert_eq(economy.transactions().size(), 1)


func test_modifying_returned_transaction_does_not_change_ledger() -> void:
	economy.earn(100, Economy.Category.SALE, 1)
	economy.transactions()[0].amount = 999999
	assert_eq(economy.income_for_day(1), 100)
