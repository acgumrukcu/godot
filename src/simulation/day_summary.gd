class_name DaySummary
extends RefCounted

# Gün sonu raporu (docs/tasarim.md §3 "Akşam: günün özeti").
# Şimdilik kasa ve müşteri kararlarını özetler. Servis sonuçları (satılan / bekleyip
# ayrılan), memnuniyet ve ilişkiler ilgili sistemler eklendikçe buraya eklenecek.
# Metne dökme UI'nın ya da araçların işidir.

var day: int = 0
var income_kurus: int = 0
var expense_kurus: int = 0
var net_kurus: int = 0
# build() çağrıldığı andaki bakiye; gün kapandıktan sonra çağrılmalıdır.
var ending_balance_kurus: int = 0

var customers_arrived: int = 0
var orders_placed: int = 0
var refused_too_expensive: int = 0
var nothing_wanted: int = 0
# Tarif id → verilen sipariş sayısı.
var orders_by_recipe: Dictionary[String, int] = {}
# Müşteri tipi id → gelen müşteri sayısı.
var customers_by_type: Dictionary[String, int] = {}


# visits başka günlere ait ziyaretler de içerebilir; yalnızca `day` gününe ait olanlar sayılır.
static func build(p_day: int, economy: Economy, visits: Array[CustomerVisit]) -> DaySummary:
	var summary: DaySummary = DaySummary.new()
	summary.day = p_day
	summary.income_kurus = economy.income_for_day(p_day)
	summary.expense_kurus = economy.expense_for_day(p_day)
	summary.net_kurus = economy.net_for_day(p_day)
	summary.ending_balance_kurus = economy.balance()

	for visit: CustomerVisit in visits:
		if visit.day != p_day:
			continue
		summary.customers_arrived += 1
		summary.customers_by_type[visit.customer_type_id] = summary.customers_by_type.get(visit.customer_type_id, 0) + 1
		match visit.decision:
			CustomerVisit.Decision.ORDERED:
				summary.orders_placed += 1
				summary.orders_by_recipe[visit.recipe_id] = summary.orders_by_recipe.get(visit.recipe_id, 0) + 1
			CustomerVisit.Decision.TOO_EXPENSIVE:
				summary.refused_too_expensive += 1
			CustomerVisit.Decision.NOTHING_WANTED:
				summary.nothing_wanted += 1
	return summary
