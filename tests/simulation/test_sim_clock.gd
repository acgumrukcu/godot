extends GutTest

const OPEN_HOUR: int = 8
const CLOSE_HOUR: int = 20
const TICKS_PER_DAY: int = (CLOSE_HOUR - OPEN_HOUR) * 60

var clock: SimClock


func before_each() -> void:
	var data: Dictionary = {
		"open_hour": OPEN_HOUR, "close_hour": CLOSE_HOUR,
		"real_ms_per_tick": 1000, "speed_multipliers": [1], "starting_balance_kurus": 0,
	}
	var config: GameConfig = GameConfig.from_dict(data).data
	clock = SimClock.new(config)


func _run_ticks(count: int) -> void:
	for _i: int in range(count):
		clock.tick()


func test_starts_on_day_one_morning_at_open_hour() -> void:
	assert_eq(clock.day, 1)
	assert_eq(clock.phase, SimClock.Phase.MORNING)
	assert_eq(clock.hour(), OPEN_HOUR)
	assert_eq(clock.minute(), 0)
	assert_eq(clock.total_ticks, 0)


func test_ticks_per_day_matches_opening_hours() -> void:
	assert_eq(clock.ticks_per_day(), 720)


func test_time_does_not_pass_in_morning() -> void:
	assert_false(clock.tick())
	assert_eq(clock.minute_of_day, OPEN_HOUR * 60)
	assert_eq(clock.total_ticks, 0)


func test_tick_advances_one_minute_when_open() -> void:
	clock.open_cafe()
	assert_true(clock.tick())
	assert_eq(clock.hour(), OPEN_HOUR)
	assert_eq(clock.minute(), 1)
	assert_eq(clock.total_ticks, 1)


func test_hour_rolls_over() -> void:
	clock.open_cafe()
	_run_ticks(75)
	assert_eq(clock.hour(), 9)
	assert_eq(clock.minute(), 15)


func test_stays_open_until_last_minute() -> void:
	clock.open_cafe()
	_run_ticks(TICKS_PER_DAY - 1)
	assert_eq(clock.phase, SimClock.Phase.OPEN)
	assert_eq(clock.hour(), 19)
	assert_eq(clock.minute(), 59)


func test_closes_at_close_hour() -> void:
	clock.open_cafe()
	_run_ticks(TICKS_PER_DAY)
	assert_eq(clock.phase, SimClock.Phase.EVENING)
	assert_eq(clock.hour(), CLOSE_HOUR)
	assert_eq(clock.minute(), 0)
	assert_eq(clock.total_ticks, TICKS_PER_DAY)


func test_time_does_not_pass_in_evening() -> void:
	clock.open_cafe()
	_run_ticks(TICKS_PER_DAY)
	assert_false(clock.tick())
	assert_eq(clock.total_ticks, TICKS_PER_DAY)


func test_next_day_resets_to_morning() -> void:
	clock.open_cafe()
	_run_ticks(TICKS_PER_DAY)
	assert_true(clock.start_next_day())
	assert_eq(clock.day, 2)
	assert_eq(clock.phase, SimClock.Phase.MORNING)
	assert_eq(clock.hour(), OPEN_HOUR)
	assert_eq(clock.minute(), 0)
	assert_eq(clock.total_ticks, TICKS_PER_DAY, "Toplam tick günler arasında korunur")


func test_invalid_phase_transitions_are_rejected() -> void:
	assert_false(clock.start_next_day(), "Sabahtan doğrudan ertesi güne geçilemez")
	assert_true(clock.open_cafe())
	assert_false(clock.open_cafe(), "Açıkken tekrar açılamaz")
	assert_false(clock.start_next_day(), "Açıkken ertesi güne geçilemez")
	assert_eq(clock.day, 1)


func test_thirty_days_run_exactly() -> void:
	# MVP hedefi 30 gün (docs/kararlar/001-oyun-suresi.md).
	for _day: int in range(30):
		clock.open_cafe()
		_run_ticks(TICKS_PER_DAY)
		clock.start_next_day()
	assert_eq(clock.day, 31)
	assert_eq(clock.total_ticks, 30 * TICKS_PER_DAY)
