extends GutTest

const SEED: int = 42

var catalog: ContentCatalog


func _catalog_with(customer_types: Array) -> ContentCatalog:
	var ingredients: Dictionary = {"ingredients": [{"id": "beans", "name": "Çekirdek", "unit_cost_kurus": 100}]}
	var recipes: Dictionary = {"recipes": [
		{"id": "coffee", "name": "Kahve", "ingredients": [{"ingredient": "beans", "amount": 1}],
			"prep_minutes": 2, "base_price_kurus": 1000, "unlock_cost_kurus": 0},
		{"id": "tea", "name": "Çay", "ingredients": [{"ingredient": "beans", "amount": 1}],
			"prep_minutes": 2, "base_price_kurus": 500, "unlock_cost_kurus": 0},
	]}
	var result: DataLoadResult = ContentCatalog.from_dicts(ingredients, recipes, {"customer_types": customer_types})
	assert_true(result.is_ok(), result.error_text())
	return result.data


func _type_entry(id: String, per_hour: int, sensitivity: int = 100) -> Dictionary:
	return {
		"id": id, "name": id,
		"arrival_windows": [{"start_hour": 8, "end_hour": 20, "customers_per_hour": per_hour}],
		"preferences": [{"recipe": "coffee", "weight": 1}],
		"price_sensitivity_percent": sensitivity, "patience_minutes": 10,
	}


func _open_clock() -> SimClock:
	var config: GameConfig = GameConfig.from_dict({
		"open_hour": 8, "close_hour": 20, "real_ms_per_tick": 1000,
		"speed_multipliers": [1], "starting_balance_kurus": 0,
	}).data
	var clock: SimClock = SimClock.new(config)
	clock.open_cafe()
	return clock


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


# Bir günü oynatıp tüm ziyaretleri döner.
func _run_day(spawner: CustomerSpawner, menu: Menu) -> Array[CustomerVisit]:
	var clock: SimClock = _open_clock()
	var visits: Array[CustomerVisit] = []
	while clock.phase == SimClock.Phase.OPEN:
		visits.append_array(spawner.tick(clock, menu))
		clock.tick()
	return visits


func _visit_signature(visits: Array[CustomerVisit]) -> Array[String]:
	var lines: Array[String] = []
	for visit: CustomerVisit in visits:
		lines.append("%s@%d:%s:%d" % [visit.customer_type_id, visit.minute_of_day, visit.recipe_id, visit.decision])
	return lines


# --- Fiyat esnekliği ---

func test_price_at_or_below_base_always_buys() -> void:
	assert_eq(CustomerSpawner.purchase_chance_permille(1000, 1000, 100), 1000)
	assert_eq(CustomerSpawner.purchase_chance_permille(500, 1000, 300), 1000)


func test_price_ten_percent_over_with_full_sensitivity() -> void:
	assert_eq(CustomerSpawner.purchase_chance_permille(1100, 1000, 100), 900)


func test_sensitivity_scales_the_drop() -> void:
	assert_eq(CustomerSpawner.purchase_chance_permille(1100, 1000, 50), 950)
	assert_eq(CustomerSpawner.purchase_chance_permille(1100, 1000, 200), 800)
	assert_eq(CustomerSpawner.purchase_chance_permille(1100, 1000, 0), 1000)


func test_chance_never_goes_below_zero() -> void:
	assert_eq(CustomerSpawner.purchase_chance_permille(5000, 1000, 100), 0)


func test_free_base_price_with_positive_price_never_buys() -> void:
	assert_eq(CustomerSpawner.purchase_chance_permille(100, 0, 100), 0)
	assert_eq(CustomerSpawner.purchase_chance_permille(0, 0, 100), 1000)


# --- Geliş ---

func test_no_customers_when_closed() -> void:
	catalog = _catalog_with([_type_entry("regular", 60)])
	var spawner: CustomerSpawner = CustomerSpawner.new(catalog, _rng(SEED))
	var config: GameConfig = GameConfig.from_dict({
		"open_hour": 8, "close_hour": 20, "real_ms_per_tick": 1000,
		"speed_multipliers": [1], "starting_balance_kurus": 0,
	}).data
	var morning_clock: SimClock = SimClock.new(config)
	assert_eq(spawner.tick(morning_clock, Menu.with_starting_recipes(catalog)).size(), 0)


func test_sixty_per_hour_arrives_every_minute() -> void:
	catalog = _catalog_with([_type_entry("regular", 60)])
	var spawner: CustomerSpawner = CustomerSpawner.new(catalog, _rng(SEED))
	var visits: Array[CustomerVisit] = _run_day(spawner, Menu.with_starting_recipes(catalog))
	assert_eq(visits.size(), 720)


func test_arrival_rate_is_roughly_per_hour_value() -> void:
	catalog = _catalog_with([_type_entry("regular", 6)])
	var spawner: CustomerSpawner = CustomerSpawner.new(catalog, _rng(SEED))
	var menu: Menu = Menu.with_starting_recipes(catalog)
	var total: int = 0
	var days: int = 20
	for _day: int in range(days):
		total += _run_day(spawner, menu).size()
	# Beklenen: 6/saat × 12 saat = günde 72. Geniş tolerans; amaç oranın doğru ölçekte olması.
	var average: float = float(total) / days
	assert_between(average, 60.0, 84.0)


func test_customers_only_arrive_in_their_window() -> void:
	var entry: Dictionary = _type_entry("morning", 60)
	entry["arrival_windows"] = [{"start_hour": 9, "end_hour": 10, "customers_per_hour": 60}]
	catalog = _catalog_with([entry])
	var spawner: CustomerSpawner = CustomerSpawner.new(catalog, _rng(SEED))
	var visits: Array[CustomerVisit] = _run_day(spawner, Menu.with_starting_recipes(catalog))
	assert_eq(visits.size(), 60)
	for visit: CustomerVisit in visits:
		assert_eq(visit.minute_of_day / 60, 9)


func test_visit_carries_context() -> void:
	catalog = _catalog_with([_type_entry("regular", 60)])
	var spawner: CustomerSpawner = CustomerSpawner.new(catalog, _rng(SEED))
	var clock: SimClock = _open_clock()
	var visit: CustomerVisit = spawner.tick(clock, Menu.with_starting_recipes(catalog))[0]
	assert_eq(visit.customer_type_id, "regular")
	assert_eq(visit.day, 1)
	assert_eq(visit.minute_of_day, 8 * 60)
	assert_eq(visit.recipe_id, "coffee")
	assert_eq(visit.price_kurus, 1000)
	assert_eq(visit.patience_minutes, 10)
	assert_eq(visit.decision, CustomerVisit.Decision.ORDERED)


# --- Sipariş kararı ---

func test_nothing_wanted_when_preferences_not_on_menu() -> void:
	catalog = _catalog_with([_type_entry("regular", 60)])
	var spawner: CustomerSpawner = CustomerSpawner.new(catalog, _rng(SEED))
	var menu: Menu = Menu.with_starting_recipes(catalog)
	menu.remove("coffee")
	var visit: CustomerVisit = spawner.tick(_open_clock(), menu)[0]
	assert_eq(visit.decision, CustomerVisit.Decision.NOTHING_WANTED)
	assert_eq(visit.recipe_id, "")


func test_overpriced_item_is_refused() -> void:
	catalog = _catalog_with([_type_entry("regular", 60)])
	var spawner: CustomerSpawner = CustomerSpawner.new(catalog, _rng(SEED))
	var menu: Menu = Menu.with_starting_recipes(catalog)
	menu.set_price("coffee", 3000)  # %200 pahalı, hassasiyet 100 → olasılık 0
	for visit: CustomerVisit in _run_day(spawner, menu):
		assert_eq(visit.decision, CustomerVisit.Decision.TOO_EXPENSIVE)


func test_higher_price_means_fewer_orders() -> void:
	catalog = _catalog_with([_type_entry("regular", 60)])
	var cheap_menu: Menu = Menu.with_starting_recipes(catalog)
	var pricey_menu: Menu = Menu.with_starting_recipes(catalog)
	pricey_menu.set_price("coffee", 1500)  # %50 pahalı → ‰500
	var cheap_orders: int = _count_orders(_run_day(CustomerSpawner.new(catalog, _rng(SEED)), cheap_menu))
	var pricey_orders: int = _count_orders(_run_day(CustomerSpawner.new(catalog, _rng(SEED)), pricey_menu))
	assert_eq(cheap_orders, 720)
	assert_between(pricey_orders, 300, 420)


func test_preference_weights_shape_choices() -> void:
	var entry: Dictionary = _type_entry("tea_lover", 60)
	entry["preferences"] = [{"recipe": "coffee", "weight": 1}, {"recipe": "tea", "weight": 9}]
	catalog = _catalog_with([entry])
	var visits: Array[CustomerVisit] = _run_day(CustomerSpawner.new(catalog, _rng(SEED)), Menu.with_starting_recipes(catalog))
	var tea_count: int = 0
	for visit: CustomerVisit in visits:
		if visit.recipe_id == "tea":
			tea_count += 1
	# Beklenen %90.
	assert_between(tea_count, 600, 696)


func _count_orders(visits: Array[CustomerVisit]) -> int:
	var count: int = 0
	for visit: CustomerVisit in visits:
		if visit.decision == CustomerVisit.Decision.ORDERED:
			count += 1
	return count


# --- Determinizm (CLAUDE.md kural 2) ---

func test_same_seed_gives_identical_day() -> void:
	catalog = ContentCatalog.load_default().data
	var menu: Menu = Menu.with_starting_recipes(catalog)
	var first: Array[String] = _visit_signature(_run_day(CustomerSpawner.new(catalog, _rng(SEED)), menu))
	var second: Array[String] = _visit_signature(_run_day(CustomerSpawner.new(catalog, _rng(SEED)), menu))
	assert_gt(first.size(), 0)
	assert_eq(first, second)


func test_different_seed_gives_different_day() -> void:
	catalog = ContentCatalog.load_default().data
	var menu: Menu = Menu.with_starting_recipes(catalog)
	var first: Array[String] = _visit_signature(_run_day(CustomerSpawner.new(catalog, _rng(SEED)), menu))
	var second: Array[String] = _visit_signature(_run_day(CustomerSpawner.new(catalog, _rng(SEED + 1)), menu))
	assert_ne(first, second)
