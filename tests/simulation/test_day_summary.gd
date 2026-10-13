extends GutTest

var economy: Economy


func before_each() -> void:
	economy = Economy.new(10000)


func _visit(day: int, type_id: String, decision: CustomerVisit.Decision, recipe_id: String = "") -> CustomerVisit:
	var visit: CustomerVisit = CustomerVisit.new()
	visit.day = day
	visit.customer_type_id = type_id
	visit.decision = decision
	visit.recipe_id = recipe_id
	return visit


func test_empty_day() -> void:
	var summary: DaySummary = DaySummary.build(1, economy, [] as Array[CustomerVisit])
	assert_eq(summary.day, 1)
	assert_eq(summary.income_kurus, 0)
	assert_eq(summary.expense_kurus, 0)
	assert_eq(summary.net_kurus, 0)
	assert_eq(summary.ending_balance_kurus, 10000)
	assert_eq(summary.customers_arrived, 0)
	assert_eq(summary.orders_by_recipe.size(), 0)


func test_money_totals_come_from_economy_for_that_day_only() -> void:
	economy.spend(3000, Economy.Category.INGREDIENT_PURCHASE, 1)
	economy.earn(4500, Economy.Category.SALE, 1)
	economy.earn(2000, Economy.Category.SALE, 2)
	var summary: DaySummary = DaySummary.build(1, economy, [] as Array[CustomerVisit])
	assert_eq(summary.income_kurus, 4500)
	assert_eq(summary.expense_kurus, 3000)
	assert_eq(summary.net_kurus, 1500)
	assert_eq(summary.ending_balance_kurus, 10000 - 3000 + 4500 + 2000)


func test_customer_decisions_are_counted() -> void:
	var visits: Array[CustomerVisit] = [
		_visit(1, "fisherman", CustomerVisit.Decision.ORDERED, "filter_coffee"),
		_visit(1, "fisherman", CustomerVisit.Decision.ORDERED, "filter_coffee"),
		_visit(1, "student", CustomerVisit.Decision.ORDERED, "cookie"),
		_visit(1, "student", CustomerVisit.Decision.TOO_EXPENSIVE, "cookie"),
		_visit(1, "retiree", CustomerVisit.Decision.NOTHING_WANTED),
	]
	var summary: DaySummary = DaySummary.build(1, economy, visits)
	assert_eq(summary.customers_arrived, 5)
	assert_eq(summary.orders_placed, 3)
	assert_eq(summary.refused_too_expensive, 1)
	assert_eq(summary.nothing_wanted, 1)
	assert_eq(summary.orders_by_recipe, {"filter_coffee": 2, "cookie": 1} as Dictionary[String, int])
	assert_eq(summary.customers_by_type, {"fisherman": 2, "student": 2, "retiree": 1} as Dictionary[String, int])


func test_visits_from_other_days_are_ignored() -> void:
	var visits: Array[CustomerVisit] = [
		_visit(1, "fisherman", CustomerVisit.Decision.ORDERED, "tea"),
		_visit(2, "fisherman", CustomerVisit.Decision.ORDERED, "tea"),
		_visit(2, "fisherman", CustomerVisit.Decision.TOO_EXPENSIVE, "tea"),
	]
	var summary: DaySummary = DaySummary.build(2, economy, visits)
	assert_eq(summary.customers_arrived, 2)
	assert_eq(summary.orders_placed, 1)
	assert_eq(summary.refused_too_expensive, 1)


func test_decision_counts_add_up_to_arrivals() -> void:
	# Gerçek bir gün: spawner çıktısıyla tutarlılık.
	var catalog: ContentCatalog = ContentCatalog.load_default().data
	var config: GameConfig = GameConfig.load_default().data
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var spawner: CustomerSpawner = CustomerSpawner.new(catalog, rng)
	var menu: Menu = Menu.with_starting_recipes(catalog)
	menu.set_price("cookie", 4500)  # bazı reddler olsun
	var clock: SimClock = SimClock.new(config)
	clock.open_cafe()
	var visits: Array[CustomerVisit] = []
	while clock.phase == SimClock.Phase.OPEN:
		visits.append_array(spawner.tick(clock, menu))
		clock.tick()

	var summary: DaySummary = DaySummary.build(1, economy, visits)
	assert_gt(summary.customers_arrived, 0)
	assert_gt(summary.refused_too_expensive, 0, "Senaryo ret içermeli")
	assert_eq(summary.orders_placed +summary.refused_too_expensive + summary.nothing_wanted, summary.customers_arrived)
	var by_type_total: int = 0
	for type_id: String in summary.customers_by_type:
		by_type_total += summary.customers_by_type[type_id]
	assert_eq(by_type_total, summary.customers_arrived)
	var by_recipe_total: int = 0
	for recipe_id: String in summary.orders_by_recipe:
		by_recipe_total += summary.orders_by_recipe[recipe_id]
	assert_eq(by_recipe_total, summary.orders_placed)
