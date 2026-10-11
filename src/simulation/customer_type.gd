class_name CustomerType
extends RefCounted

# data/customer_types.json içindeki bir müşteri tipi (docs/tasarim.md §4.4).

var id: String = ""
var display_name: String = ""
var arrival_windows: Array[ArrivalWindow] = []
# Tarif id → seçim ağırlığı. Sıra veri dosyasındaki gibidir (deterministik seçim için).
var preferences: Dictionary[String, int] = {}
var price_sensitivity_percent: int = 0
var patience_minutes: int = 0


# Verilen saatte saatte kaç müşteri gelir; aralık dışındaysa 0.
func customers_per_hour_at(hour: int) -> int:
	var total: int = 0
	for window: ArrivalWindow in arrival_windows:
		if window.contains_hour(hour):
			total += window.customers_per_hour
	return total
