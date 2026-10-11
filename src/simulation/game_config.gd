class_name GameConfig
extends RefCounted

# data/game_config.json içeriğinin tipli hali. Şemanın ifade edemediği
# alanlar arası kurallar burada kontrol edilir (bkz. docs/kararlar/002-veri-semalari.md).

const DATA_NAME: String = "game_config"

var open_hour: int = 0
var close_hour: int = 0
var real_ms_per_tick: int = 0
var speed_multipliers: Array[int] = []


# data/game_config.json'u yükler. Başarılıysa result.data bir GameConfig'tir.
static func load_default() -> DataLoadResult:
	var loaded: DataLoadResult = DataLoader.load_data(DATA_NAME)
	if not loaded.is_ok():
		return loaded
	return from_dict(loaded.data)


# Şemadan geçmiş (int'leri dönüştürülmüş) sözlükten oluşturur.
static func from_dict(data: Dictionary) -> DataLoadResult:
	var result: DataLoadResult = DataLoadResult.new()
	var config: GameConfig = GameConfig.new()
	config.open_hour = data["open_hour"]
	config.close_hour = data["close_hour"]
	config.real_ms_per_tick = data["real_ms_per_tick"]
	config.speed_multipliers.assign(data["speed_multipliers"])

	if config.close_hour <= config.open_hour:
		result.errors.append("%s: close_hour (%d) open_hour'dan (%d) büyük olmalı" % [
			DATA_NAME, config.close_hour, config.open_hour
		])
		return result
	result.data = config
	return result
