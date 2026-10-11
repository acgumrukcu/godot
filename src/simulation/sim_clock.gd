class_name SimClock
extends RefCounted

# Tick tabanlı oyun saati. 1 tick = 1 oyun dakikası (CLAUDE.md kural 2).
# Günlük döngü (docs/tasarim.md §3): sabah hazırlığı → açık saatler → akşam özeti.
# Zaman yalnızca OPEN evresinde akar; gerçek zamana hiç bağlı değildir.

enum Phase { MORNING, OPEN, EVENING }

const MINUTES_PER_HOUR: int = 60
const FIRST_DAY: int = 1

var day: int = FIRST_DAY
var minute_of_day: int = 0
var phase: Phase = Phase.MORNING
var total_ticks: int = 0

var _open_minute: int = 0
var _close_minute: int = 0


func _init(config: GameConfig) -> void:
	_open_minute = config.open_hour * MINUTES_PER_HOUR
	_close_minute = config.close_hour * MINUTES_PER_HOUR
	minute_of_day = _open_minute


# Sabah hazırlığını bitirip kafeyi açar. Sadece MORNING evresinde geçerlidir.
func open_cafe() -> bool:
	if phase != Phase.MORNING:
		return false
	phase = Phase.OPEN
	return true


# Bir oyun dakikası ilerletir. Kapanış saatine gelince EVENING evresine geçer.
# OPEN dışında hiçbir şey yapmaz ve false döner.
func tick() -> bool:
	if phase != Phase.OPEN:
		return false
	minute_of_day += 1
	total_ticks += 1
	if minute_of_day >= _close_minute:
		phase = Phase.EVENING
	return true


# Akşam özetinden sonra ertesi günün sabahına geçer. Sadece EVENING evresinde geçerlidir.
func start_next_day() -> bool:
	if phase != Phase.EVENING:
		return false
	day += 1
	minute_of_day = _open_minute
	phase = Phase.MORNING
	return true


func hour() -> int:
	return minute_of_day / MINUTES_PER_HOUR


func minute() -> int:
	return minute_of_day % MINUTES_PER_HOUR


func ticks_per_day() -> int:
	return _close_minute - _open_minute
