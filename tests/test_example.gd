extends GutTest

# Altyapı doğrulaması: GUT headless çalışıyor ve testleri bulabiliyor.


func test_gut_runs() -> void:
	assert_true(true, "GUT çalışıyor")


func test_seeded_rng_is_deterministic() -> void:
	# Simülasyon tohumlu RNG'ye dayanır (CLAUDE.md kural 2); aynı tohum aynı diziyi üretmeli.
	var seed_value: int = 42
	var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
	var rng_b: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_a.seed = seed_value
	rng_b.seed = seed_value
	for i: int in range(10):
		assert_eq(rng_a.randi(), rng_b.randi())
