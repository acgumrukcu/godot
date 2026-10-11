class_name CustomerSpawner
extends RefCounted

# Müşteri gelişi ve sipariş kararı (docs/tasarim.md §4.4, §4.2).
# Tüm rastgelelik enjekte edilen tohumlu RNG'den gelir (CLAUDE.md kural 2).
# Olasılıklar float yerine binde (permille) tam sayı ile hesaplanır; böylece sonuçlar
# platformdan bağımsız olarak aynı tohumla birebir tekrarlanır.

const PERMILLE: int = 1000
const PERCENT: int = 100

var _catalog: ContentCatalog
var _rng: RandomNumberGenerator


func _init(catalog: ContentCatalog, rng: RandomNumberGenerator) -> void:
	_catalog = catalog
	_rng = rng


# Saatin şu anki dakikası için gelen müşterileri ve kararlarını döner.
# Saat açık değilse boş döner. Tipler veri dosyasındaki sırayla işlenir.
func tick(clock: SimClock, menu: Menu) -> Array[CustomerVisit]:
	var visits: Array[CustomerVisit] = []
	if clock.phase != SimClock.Phase.OPEN:
		return visits
	for type_id: String in _catalog.customer_type_ids():
		var customer_type: CustomerType = _catalog.customer_type(type_id)
		if _arrives(customer_type.customers_per_hour_at(clock.hour())):
			visits.append(_decide(customer_type, clock, menu))
	return visits


# Saatte n müşteri → her dakika n/60 olasılıkla bir müşteri.
func _arrives(customers_per_hour: int) -> bool:
	if customers_per_hour <= 0:
		return false
	return _rng.randi_range(1, SimClock.MINUTES_PER_HOUR) <= customers_per_hour


func _decide(customer_type: CustomerType, clock: SimClock, menu: Menu) -> CustomerVisit:
	var visit: CustomerVisit = CustomerVisit.new()
	visit.customer_type_id = customer_type.id
	visit.day = clock.day
	visit.minute_of_day = clock.minute_of_day
	visit.patience_minutes = customer_type.patience_minutes

	var recipe_id: String = _pick_recipe(customer_type, menu)
	if recipe_id.is_empty():
		visit.decision = CustomerVisit.Decision.NOTHING_WANTED
		return visit

	visit.recipe_id = recipe_id
	visit.price_kurus = menu.price(recipe_id)
	var base_price: int = _catalog.recipe(recipe_id).base_price_kurus
	var chance: int = purchase_chance_permille(visit.price_kurus, base_price, customer_type.price_sensitivity_percent)
	if _rng.randi_range(1, PERMILLE) <= chance:
		visit.decision = CustomerVisit.Decision.ORDERED
	else:
		visit.decision = CustomerVisit.Decision.TOO_EXPENSIVE
	return visit


# Menüdeki ürünler arasından tercih ağırlığına göre seçer; uygun ürün yoksa "".
func _pick_recipe(customer_type: CustomerType, menu: Menu) -> String:
	var total_weight: int = 0
	for recipe_id: String in customer_type.preferences:
		if menu.has(recipe_id):
			total_weight += customer_type.preferences[recipe_id]
	if total_weight == 0:
		return ""
	var roll: int = _rng.randi_range(1, total_weight)
	for recipe_id: String in customer_type.preferences:
		if not menu.has(recipe_id):
			continue
		roll -= customer_type.preferences[recipe_id]
		if roll <= 0:
			return recipe_id
	return ""


# Fiyat esnekliği: temel fiyat ve altı → kesin alır (1000‰). Temel fiyatın her %1 üstü,
# alma olasılığını sensitivity_percent'in %1'i kadar (binde 10 × hassasiyet/100) düşürür.
static func purchase_chance_permille(price_kurus: int, base_price_kurus: int, sensitivity_percent: int) -> int:
	if price_kurus <= base_price_kurus:
		return PERMILLE
	if base_price_kurus <= 0:
		return 0
	var over_permille: int = (price_kurus - base_price_kurus) * PERMILLE / base_price_kurus
	var drop: int = over_permille * sensitivity_percent / PERCENT
	return clampi(PERMILLE - drop, 0, PERMILLE)
