class_name CustomerVisit
extends RefCounted

# Bir müşterinin gelişi ve sipariş kararı. Servis (hazırlama, bekleme) ayrı bir adımdır.

enum Decision { ORDERED, TOO_EXPENSIVE, NOTHING_WANTED }

var customer_type_id: String = ""
var day: int = 0
var minute_of_day: int = 0
var decision: Decision = Decision.NOTHING_WANTED
# Seçilen ürün; NOTHING_WANTED ise boş.
var recipe_id: String = ""
# Kararın verildiği menü fiyatı (kuruş); NOTHING_WANTED ise 0.
var price_kurus: int = 0
var patience_minutes: int = 0
